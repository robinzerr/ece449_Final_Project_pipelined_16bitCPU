#!/usr/bin/env python

################################################################################
# assembly.py
#
# assembler for ECE 449 lab project CPUs
#
# Version 1.12 beta 2
#
# Written by : Caedmon Somers
# Created    : January 2002
# Modified   : April 3, 2002
#
# Modified and extended to two pass by Nikitas Dimopoulos April 3, 2018
#
# Modified  Fixed issue with NOP instructions being inserted in listing output
#           if origin of program is not 0 by Brent Sirna : January 23, 2019
#
# Modified by Brent Sirna  : February 15, 2019
#
# Added EQU directive
# Fixed END directive bypassing second pass of the assembler
# Added .LO and .HI directive
# Added ability to reference symbols in instructions or directives
# Removed segment directives (.code and .data )
#
# Modified by Brent Sirna : February 27, 2019
#
# Added Second output stream for a ascii hex file format (.hex)
# Fixed bug with branch and shift instructions incorrectly doing a symbol
#	table access in pass 2
#
# Modified by Brent Sirna : December 18, 2023
#
# Updated code to work with Python 3
# removed code related to segments
# Added support for byte and word addresses based code ( Default is byte mode )
#
# Modified by Brent Sirna : December 20, 2023
#
# Fixed issue with BadSymbol exception handler
#
##
################################################################################


################################################################################
# imports

# python library modules
import string, sys, time, math, operator, re


################################################################################
# exceptions

class RegisterStringError(Exception): pass
class ParameterCountError(Exception): pass
class AddressOutOfRangeError(Exception): pass
class ByteOutOfRangeError(Exception): pass
class BadAddressError(Exception): pass
class BadImmediateError(Exception): pass
class BadSymbol(Exception): pass
class MissingParameterForEquate(Exception): pass
class SymbolAlreadyDefined(Exception): pass
class MissingParameterForOrg(Exception): pass

Version = "1.12 beta 1"



################################################################################
# helper functions

# 3 operand instructions
def ConstructOpcode(opc, ra = None, rb = None, rc = None, brx = None):
	# construct a 16 bit opcode from constituents
	opcode = opc
	if ra:
		opcode = opcode | (ra << 6)
	if rb:
		opcode = opcode | (rb <<3)
	if rc:
		opcode = opcode | rc

	if brx:
		opcode = opcode | (brx << 2)
	return opcode

# branch instructions
def ConstructOpcodeBranch(opc, ra = None, offset = None):
	# construct a 16 bit opcode from constituents
	# Branch relative dedicates the 9 LSB for the displacement
	opcode = opc
	if ra:
		opcode = opcode | (ra << 6)
	if offset:
		opcode = opcode | (offset & 0x003f)

	return opcode

# branch relative instructions
def ConstructOpcodeBranchR(opc, offset = None):
	# construct a 16 bit opcode from constituents
	# Branch relative dedicates the 9 LSB for the displacement
	opcode = opc
	if offset:
		opcode = opcode | (offset & 0x01ff)

	return opcode

# LOAD Immediate instructions
def ConstructOpcodeLDIMM(opc, imm = None):
	# construct a 16 bit opcode from constituents
	# Branch relative dedicates the 9 LSB for the displacement
	opcode = opc
	if imm:
		opcode = opcode | (imm & 0x00ff)

	return opcode

# Shift instructions
def ConstructOpcodeSHIFT(opc, ra = None, cl = None):
	# construct a 16 bit opcode from constituents
	# Branch relative dedicates the 9 LSB for the displacement
	opcode = opc
	if ra:
		opcode = opcode | (ra << 6)
	if cl:
		opcode = opcode | (cl & 0x000f)

	return opcode

################################################################################
# classes

class Assembler:
	def __init__(self, memory_depth):
		# memory depth for mem file
		self.memory_depth = memory_depth

		# symbol table
		self.symbol_table = {}

		# list of instruction words
		self.machine_code = [0] * self.memory_depth

		# List of assembly lines
		self.refined_code_line = [''] * self.memory_depth

		# for ram map
		self.org = 0
		self.highest_org = 0

		# for error messages
		self.line_num = 0

		# to handle END directives
		self.end = 0

		# Shows if we are parsing the data section
		self.Data_Parsing = False

		# Shows if we are parsing the code section
		self.Code_Parsing = False

		# Variables to hold the start of the data and code segments
		self.Loc = 0

		#
		# Maximum number of characters in all the symbols
		#
		self.MaxSymbolLength = 0

	def MachineCode2String(self):
		# construct string of hex numbers for machine code text file

		s = """
;
; Created on %s with ECE 449 assembler v%s (16 bit).
;
;Header Section
RADIX 10
DEPTH %d
WIDTH 16
DEFAULT 0
;
; Data Section
; Specifies data to be stored in different addresses
; e.g., DATA 0:A, 1:0
;
RADIX 16
DATA """ % (time.ctime(time.time()), Version, self.memory_depth)

		self.Address = 0

		if ( byte_addressable == True ):
			self.Increment = 2
		else:
			self.Increment = 1

		s = s + '\n'
		for i in range(0,self.highest_org + 1, self.Increment ):

			if 0 != len(  self.refined_code_line[i] ):
				s = s + '%04d => "%s", -- %04X - %04X %-25s\n' % ( self.Address, format(self.machine_code[i],'016b'), self.Address, self.machine_code[i], self.refined_code_line[i])

			self.Address = self.Address + self.Increment


		# Print symbol table
		s = s + '\n\n-------------------------------------------------------\n'
		s = s + 'Symbol Table:\n'
		self.symbol_table = sorted(self.symbol_table.items(), key=operator.itemgetter(0))
		for SymbolName,SymbolValue in self.symbol_table:
			s = s + '%s %6d (%04X)\n' % (SymbolName+(' '*((self.MaxSymbolLength+1)-len(SymbolName))),SymbolValue, SymbolValue )

		return s

	def MachineCode2HexString(self):
		# construct string of hex numbers for machine code text file

		s = ""
		for i in range(0,self.highest_org + 1,2):
			s = s + '%04X\n' % ( self.machine_code[i])

		return s

	def MachineCode2CoeString(self):
		# construct string of hex numbers for machine code text file

		s = "memory_initialization_radix=16;\nmemory_initialization_vector=\n"

		for i in range(0,self.highest_org + 1,2):
			if ( i != 0 ):
				s = s + ',\n'

			s = s + '%04X' % ( self.machine_code[i])

		s = s + ';\n'


		return s

	def StoreByte(self, b , r_line ):
		if self.org >= self.memory_depth:
			raise ByteOutOfRangeError( self.org )
		self.machine_code[self.org] = b
#		r_line = re.sub( '\s+', '\t', r_line ).strip()
		self.refined_code_line[self.org] = r_line
		self.highest_org = max(self.highest_org, self.org)

		if ( byte_addressable == True ):
			self.org = self.org + 2
		else:
			self.org = self.org + 1


# This function is to be used for the first pass. It does not store the machine code
# It simply increments the address. The machine code will be stored by the StoreByte
# during the second pass
	def UpdateAddress(self):
		if self.org >= self.memory_depth:
			raise ByteOutOfRangeError( self.org )
		self.highest_org = max(self.highest_org, self.org)

		if ( byte_addressable == True ):
			self.org = self.org + 2
		else:
			self.org = self.org + 1


	def DecodeRegisterString(self, s):
		# can add more stringent parameter checks here

		if ( s.upper() in ['R0', 'R1', 'R2', 'R3', 'R4', 'R5', 'R6', 'R7'] ):
			return ['R0', 'R1', 'R2', 'R3', 'R4', 'R5', 'R6', 'R7'].index(s.upper())
		else:
			raise RegisterStringError( s )


	def String2Address(self, s):
		# addresses can be of the form '10' '0x10' or 'symbol'
		try:
			# hex and decimal reps
			address = eval(s)
		except NameError:
				# may be numeric or may be string
				address = s

		if type(address) not in [type(0), type('string')]:
			raise BadAddressError( s )

		if type(address) == type(0) and address >= self.memory_depth:
			raise AddressOutOfRangeError( address, self.memory_depth )

		return address




	def String2Immediate(self, s):
		# immediate values can be of the form '10' '0x10' or 'symbol'

		HighByte = False
		LowByte = False

		if ( s[-3:].upper() == ".HI" ) :
			HighByte = True
			s = s[:s.find('.')]

		if ( s[-3:].upper() == ".LO" ) :
			LowByte = True
			s = s[:s.find('.')]

		if s in self.symbol_table:
			imm = self.symbol_table[s] & 0xFFFF;
		else:
			try:
				# hex and decimal reps
				imm = eval(s)

			except NameError:
				self.QuitWithError( 'Missing or illegal parameter', "symbol was "+s )

		if ( HighByte ) :
			return ( imm & 0xFFFF ) >> 8

		if ( LowByte ) :
			return ( imm & 0x00FF )


		if type(imm) not in [type(0), type('string')]:
			raise BadImmediateError( s )

##		if type(imm) == type(0) and (imm > MAX_INT or imm < -MAX_INT/2):
##			raise AddressOutOfRangeError( imm )

		return imm


	def TranslateSymbols(self):
		for i in range(len(self.machine_code)):
			byte = self.machine_code[i]
			if type(byte) is type('string'):
				try:
					self.machine_code[i] = self.symbol_table[byte]
				except KeyError:
					sys.stderr.write('undefined symbol: %s\n' % byte)
					sys.exit(-1)


	def AssembleString(self, s):
		# First Pass, assemble symbol table
		for line in s.split( '\n' ):
			self.FirstPassLine(line)

		# Second Pass, assemble code.
		# If there is an ORG directive, it will set the origin correctly

		self.org = 0				# Reset the default origin
		self.end = 0				# Reset the end of file instruction
		self.line_num = 0			# Reset the line count
		for line in s.split( '\n' ):
			#print line
			self.AssembleLine(line)
		self.TranslateSymbols()


	def QuitWithError(self, error_string, line):
		sys.stderr.write(error_string + '\n')
		sys.stderr.write('line %d: %s\n' % (self.line_num, line))
		sys.exit(-1)

	def AddSymbol(self, Symbol, Value ):
		self.symbol_table[Symbol] = Value
		if ( len( Symbol )  > self.MaxSymbolLength ):
			self.MaxSymbolLength = len( Symbol )

	def BuildOutput( self, SymbolName, Opcode, tokens ):

		OutputString = SymbolName + (' '*((self.MaxSymbolLength +2 ) - len( SymbolName )))
		OutputString = OutputString + Opcode+(' '*(14-len( Opcode )))
		loop = 0
		while ( loop < len( tokens )):
			OutputString = OutputString + tokens[loop] + ','
			loop = loop + 1

		return OutputString[:-1]

# #########
# First Pass identify labels and assemble the symbol table
# First Pass code identical to second Pass except that it does not do any
# opcode processing except to determine whether the lines have valid opcodes.
# It only focuses on labels and stores them together wit their resolved addresses
# to the symbol table to be used during the second pass below
# ########

	def FirstPassLine(self, line):
		# ignore all lines after END directive
		if self.end:
			return

		# keep track of line number
		self.line_num = self.line_num + 1

		# remove comment text after first semicolon
		refined_line = line.split( ';' )[0]

		# remove leading and trailing whitespace
		refined_line = refined_line.strip()

		# ignore lines with no opcodes
		if not refined_line:
			return

		# convert commas to spaces
		refined_line = ' '.join( refined_line.split( ',' ))

		# break line into words
		tokens = refined_line.split()

		# skip effectively blank lines
		if not tokens:
			return

		# tokens[0] - symbol
		# tokens[1] - opcode
		# tokens[2...] - opcode specific data

		#
		# See if we have a symbol at the beginning of the line. if not the insert a blank token for the symbol to keep the tokens aligned
		#

		try:
			if tokens[0][-1] == ':':
				if tokens[0].find( ':' ) + 1 == len( tokens[0] ):


					if tokens[0][:-1] in self.symbol_table:
						raise SymbolAlreadyDefined
		#
		# Check for an EQU instruction. If so then process it
		#
					if (( len( tokens ) >= 2 ) and ( tokens[1].upper() == 'EQU' )):
						try:
							self.AddSymbol( tokens[0][:-1], self.String2Immediate(tokens[2]) )
							return
						except IndexError:
							raise MissingParameterForEquate
					else:
						self.AddSymbol( tokens[0][:-1], self.org )

				else:
					raise BadSymbol

			else:
				tokens = [''] + tokens

		except BadSymbol:
			self.QuitWithError( 'Bad symbol in line', line )

		except MissingParameterForEquate:
			self.QuitWithError( 'Missing or illegal parameter for equ directive', line )

		except SymbolAlreadyDefined:
			self.QuitWithError( 'Symbol already defined', line )


		#
		# Check for line with only a symbol on it
		#

		num_tokens = len(tokens)
		if ( num_tokens == 1 ):
			return

		opcode_str = tokens[1].upper()


		try:
			if ( opcode_str == 'ORG' ):
				if ( num_tokens == 3 ):

					self.org = 	self.String2Address(tokens[2])
					if (( self.org & 0x0001 ) == 0x0001 ):
						self.QuitWithError( 'Origin must be an even address', line )

#
# If symbol attached to org directive then assign the new address to the symbol
#
					if ( len( tokens[0]) != 0 ):
						self.AddSymbol( tokens[0][:-1], self.org )
#						self.symbol_table[tokens[0][:-1]] = self.org

					return
				else:
					raise MissingParameterForOrg

		except MissingParameterForOrg:
			self.QuitWithError( 'Missing or illegal parameter for org directive', line )

		except AddressOutOfRangeError as ExError:
			self.QuitWithError('Address %s out of range ( range is 0 to %s )' % ( str( ExError.args[0] ), str( ExError.args[1] -1 )), line)

		except BadAddressError as ExError:
			self.QuitWithError('Bad address %s' % ( str( ExError.args[0] )), line)

		except BadImmediateError as ExError:
			self.QuitWithError('Bad immediate type %s' % type( ExError.args[0] ), line)



		'''
		# Parsing the data segment of the code
		#   and creating the data table:
		#
		#	----------------------------------------------------|
		#	| variable1  |  add  | value1  | Value2  | Value3   |
		#	|---------------------------------------------------|
		#	| variable2  |  add  | value1  | Value2  | Value3   |
		#	|---------------------------------------------------|
		#	|.........											|
		#	|---------------------------------------------------|
		'''


		if opcode_str == 'EQU' :
			self.QuitWithError('Expected symbol with EQU directive', line)



		if opcode_str == 'DB' or opcode_str == 'DW':
			for var in range(2, len(tokens)):		# store the values associated to the variable, next to its address	as a list
				self.UpdateAddress()

			return



##		# detect mem directives
##		if num_tokens > 1 and tokens[1] == 'mem':
##			if num_tokens != 3:
##				self.QuitWithError('mem directive synax should be "<label> mem <value>"', line)
##			self.symbol_table[tokens[0]] = self.org
##			self.UpdateAddress()
##			return

			# line must contain an opcode


			# org directives
		if opcode_str == 'ORG':
			if num_tokens != 3:
				self.QuitWithError('Expected 1 parameter for org directive', line)

			return

		if opcode_str == 'END':
			self.end = 1
			return

			# find opcode
		try:
			opcode = string2opcode[opcode_str]
		except KeyError:
				# bad opcode
			self.QuitWithError('Unrecognized opcode %s' % opcode_str, line)
				# encode opcode and parameters
		try:

				# 0 parameter opcodes
			if opcode in [NOP, HALT, RETURN]:
					#    NOP
					# ex NOP
					# etc
				if num_tokens != 2:
					raise ParameterCountError( 1 )
				self.UpdateAddress()

				# 1 parameter ra opcodes
			elif opcode in [IN, OUT, TEST, PUSH, POP , LOAD_SP]:
					#    SHL R[ra]
					# ex SHL R1
					# etc

				if num_tokens != 3:
					raise ParameterCountError( 2 )
				self.UpdateAddress()

				# 2 parameter ra and disp.s opcodes
			elif opcode in [BR, BR_Z, BR_N, BR_SUB]:
					#    BRR_* displacement
					# ex BRR_* label
					# etc
				if num_tokens != 4:
					raise ParameterCountError( 3 )
				self.UpdateAddress()

				# 1 parameter rb opcodes
			elif opcode in [BRR, BRR_Z, BRR_N, BRR_V]:
					#    BRR_* displacement
					# ex BRR_* label
					# etc
				if num_tokens != 3:
					raise ParameterCountError( 2 )
				self.UpdateAddress()


			elif opcode in [LOAD, STORE, MOV]:
				if num_tokens != 4:
					raise ParameterCountError( 3 )
				self.UpdateAddress()

			elif opcode in [SHL, SHR]:
				if num_tokens != 4:
					raise ParameterCountError( 3 )
				self.UpdateAddress()

				# imm op codes
			elif opcode in [LOADIMM_UPPER, LOADIMM_LOWER]:
				if num_tokens != 3:
					raise ParameterCountError( 2 )
						#    LOADIMM_U  imm
						# ex LOADIMM_L  0xf0
				self.UpdateAddress()

	# Deal with 3 argument instructions i.e. ADD, SUB, MUL, logical etc.

			elif opcode in [ ADD, SUB, NAND, MUL]:
				if num_tokens != 5:
					raise ParameterCountError( 4 )
				self.UpdateAddress()

	# errors and their notifications
	# borrowed from second pass
		except RegisterStringError as ExError:  # ( register_string ):
			self.QuitWithError('Invalid register specification %s (Use R0, etc)' % ExError.args[0], line ) # register_string, line)

		except ParameterCountError as ExError:
			self.QuitWithError('Opcode requires %d parameter(s)' % ( ExError.args[0] -1 ) , line)

		except AddressOutOfRangeError as ExError:
			self.QuitWithError('Address %s out of range ( range is %s )' % ( str( ExError.args[0] ), str( ExError.args[1] )), line)

		except BadAddressError as ExError:
			self.QuitWithError('Bad address %s' % ( str( ExError.args[0] )), line)

		except BadImmediateError as ExError:
			self.QuitWithError('Bad immediate type %s' % type( ExError.args[0] ), line)

		except ByteOutOfRangeError as ExError:
			self.QuitWithError('Program became larger than RAM at byte %s' % str( ExError.args[0] ), line)

		#self.Data_Parsing = False
		#self.Code_Parsing = False

# ###########
# Second Pass Assemble the machine code
# The symbol part is disabled as the symbol table is assembled during the first part.
# However, the lexical analysis identifies labels and treats them properly
# ###########
	def AssembleLine(self, line):
		# ignore all lines after END directive
		if self.end:
			return

		# keep track of line number
		self.line_num = self.line_num + 1

		# remove comment text after first semicolon
		refined_line = line.split( ';')[0]

		# remove leading and trailing whitespace
		refined_line = refined_line.strip()

		# ignore lines with no opcodes
		if not refined_line:
			return

		output_tokens = refined_line.split()
		if ( len( output_tokens ) < 3 ):
			output_tokens = ['', output_tokens]

		# convert commas to spaces
		refined_line = ' '.join( refined_line.split( ',' ))
		# break line into words
		tokens = refined_line.split()


		# skip effectively blank lines
		if not tokens:
			return

			# detect labels:
		if not ( tokens[0][-1] == ':'):
			tokens = [''] + tokens

#
# Check for blank line or line with only a symbol
#
		num_tokens = len(tokens)
		if ( num_tokens == 1 ):
			return

		LineToPrint = self.BuildOutput( tokens[0], tokens[1], tokens[2:] )

		opcode_str = tokens[1].upper()

		# detect directives

		''' Parsing the data segment of the file 		'''

		if opcode_str == 'DB' or opcode_str == 'DW':
			FirstLine = True
			for var in range(2, len(tokens)):		# store the values associated to the variable, next to its address	as a list
				self.Value = int(self.String2Immediate(tokens[var]))

				self.Value = self.Value & 0xFFFF
				if opcode_str == 'DB':
					self.Value = self.Value & 0xFF

				if ( FirstLine ):
					self.StoreByte( self.Value, LineToPrint )
					FirstLine = False
				else:
					self.StoreByte( self.Value, ' ' )

			return
		''' -------------------------------------
			Parsing the code segment of the file
		-----------------------------------------'''




			# detect mem directives
##		if num_tokens > 1 and tokens[1] == 'mem':
##			if num_tokens != 3:
##				self.QuitWithError('mem directive syntax should be "<label> mem <value>"', line)
##				# Labels have been dealt in first pass. Do not update symbol table.
##				# self.symbol_table[tokens[0]] = self.org
##			self.StoreByte(self.String2Immediate(tokens[2]), LineToPrint)
##			return

			# org directives
		if opcode_str == 'ORG':
			if num_tokens != 3:
				self.QuitWithError('Expected 1 parameter for org directive', line)
			self.org = 	self.String2Address(tokens[2])
			return

		if opcode_str == 'END':
			self.end = 1
			return

		if opcode_str == 'EQU':
			return

			# find opcode
		try:
			opcode = string2opcode[opcode_str]
		except KeyError:
				# bad opcode
			self.QuitWithError('Unrecognized opcode %s' % opcode_str, line)

			# encode opcode and parameters
		try:

				# 0 parameter opcodes
			if opcode in [NOP, HALT, RETURN]:
					#    NOP
					# ex NOP
					# etc
				if num_tokens != 2:
					raise ParameterCountError( 1 )

				self.StoreByte(opcode, LineToPrint)

				# 1 parameter ra opcodes
			elif opcode in [IN, OUT, TEST, PUSH, POP, LOAD_SP ]:
					# ex IN R[ra]
					# ex OUT R1
					# etc

				if num_tokens != 3:
					raise ParameterCountError( 2 )
					# register
				ra = self.DecodeRegisterString(tokens[2])
					# store opcode
				self.StoreByte(ConstructOpcode(opcode, ra = ra), LineToPrint)


				# 2 parameter ra and cl opcodes
			elif opcode in [SHL, SHR]:
					# ex	SHR R[ra], 0x03
					# ex	SHL R[ra], 0x01
					# etc

				if num_tokens != 4:
					raise ParameterCountError( 3 )
					# register
				ra = self.DecodeRegisterString(tokens[2])
					#
				shiftbits=self.String2Address(tokens[3])

				if type(shiftbits) == type('string'):
					shiftbits = self.String2Immediate( shiftbits )

					# store opcode
				self.StoreByte(ConstructOpcodeSHIFT(opcode, ra = ra, cl = shiftbits), LineToPrint)


				# 1 parameter rb opcodes
			elif opcode in [BRR, BRR_Z, BRR_N, BRR_V]:
					#    BRR_* displacement
					# ex BRR_* label
					# etc
				if num_tokens != 3:
					raise ParameterCountError( 2 )
					# cl opcode
				offset=self.String2Address(tokens[2])

				if type(offset) == type('string'):
					offset = self.String2Immediate( offset )
#
# use symbol table to get the address of the label
# and find the displacement relative to the current address
#
					offset=offset - self.org
#
# Shift right by one since the ISA requires that displacement
# is multiplied by 2
#
					if ( byte_addressable == True ):
						offset = (offset >> 1)

				self.StoreByte(ConstructOpcodeBranchR(opcode, offset = offset), LineToPrint)

			elif opcode in [BR, BR_Z, BR_N, BR_SUB]:
					#    BR_* ra, displacement
					# ex BR_* r3, 0x02
					# etc
				if num_tokens != 4:
					raise ParameterCountError( 2 )
					# register
				ra = self.DecodeRegisterString(tokens[2])
					# cl opcode
				offset=self.String2Address(tokens[3])

				if type(offset) == type('string'):

					offset = self.String2Immediate( offset )
#
# use symbol table to get the address of the label
# and find the displacement relative to the current address
#
					offset=offset - self.org
#
# Shift right by one since the ISA requires that displacement
# is multiplied by 2
#
					if ( byte_addressable == True ):
						offset = (offset >> 1)

				self.StoreByte(ConstructOpcodeBranch(opcode, ra= ra, offset = offset), LineToPrint)

			elif opcode in [LOAD, STORE, MOV]:
				if num_tokens != 4:
					raise ParameterCountError( 3 )

					# ra, rb op codes
					# ra and rb fields are presently separated by a comma or a space
					# eventually an @ notation needs to be added to indicate source address
				if opcode in [LOAD, STORE, MOV]:
						#    LOAD ra, rb
						#    LOAD rdst, rsrc
						#    STORE rdst, rsrc
						#    MOV   rdest, rsrc

						# registers
						# ra holds destination info
					ra = self.DecodeRegisterString(tokens[2])
						#rb holds source info
					rb = self.DecodeRegisterString(tokens[3])
				self.StoreByte(ConstructOpcode(opcode, ra = ra, rb = rb), LineToPrint)


					# imm op codes
			elif opcode in [LOADIMM_UPPER, LOADIMM_LOWER]:
				if num_tokens != 3:
					raise ParameterCountError( 2 )
						#    LOADIMM_U  imm
						# ex LOADIMM_L  0xf0


						# immediate value

				imm = int( self.String2Immediate(tokens[2]))

				self.StoreByte(ConstructOpcodeLDIMM(opcode, imm = imm), LineToPrint)



	# Deal with 3 argument instructions i.e. ADD, SUB, MUL, logical etc.

			elif opcode in [ ADD, SUB, NAND, MUL]:
				if num_tokens != 5:
					raise ParameterCountError( 4 )

					# ra, rb, rc opcodes
				elif opcode in [ADD, SUB, NAND, MUL]:
						#    ADD R[ra], R[rb], R[rc]
						# ex ADD R1, R2, R3
						# etc

						# registers
					ra = self.DecodeRegisterString(tokens[2])
					rb = self.DecodeRegisterString(tokens[3])
					rc = self.DecodeRegisterString(tokens[4])
						# store opcode
				self.StoreByte(ConstructOpcode(opcode, ra = ra, rb = rb, rc = rc), LineToPrint)





	# errors and their notifications
		except RegisterStringError as ExError:
			self.QuitWithError('Invalid register specification %s (Use R0, etc)' % ExError.args[0], line)

		except ParameterCountError as ExError:
			self.QuitWithError('Opcode requires %d parameter(s)' % (ExError.args[0] -1), line)

		except AddressOutOfRangeError as ExError:
			self.QuitWithError('Address %s out of range ( range is %s )' % ( str( ExError.args[0] ), str( ExError.args[1] )), line)

		except BadAddressError as ExError:
			self.QuitWithError('Bad address %s' % ( str( ExError.args[0] )), line)

		except BadImmediateError as ExError:
			self.QuitWithError('Bad immediate type %s' % type( ExError.args[0] ), line)

		except ByteOutOfRangeError as ExError:
			self.QuitWithError('Program became larger than RAM at byte %s' % str( ExError.args[0] ), line)


################################################################################
# when run as a program

if __name__ == '__main__':
	import fileinput, getopt

	# command line argument specification
	try:
		opts, args = getopt.getopt(sys.argv[1:], 'y:d:wbho:')
	except getopt.error( error_string ):
		sys.stderr.write('ERROR: ' + error_string + '\n')
		sys.exit(-1)

	# default options
	opt_hash = {}
	byte_addressable = True

	# read options from command line
	for opt_pair in opts:
		opt_hash[opt_pair[0]] = opt_pair[1]

	# display help
	if len(args) != 1 or ( "-h" in opt_hash ):
		sys.stderr.write("""
usage: assembler.py [option] ... file | -

Assembles the file (or standard input stream) in ECE 449 assembly language
and produces a Xilinx MEM file with the corresponding memory image.

options:
  -h                 This help.

  -o <file>          Directs output to the given file instead of the standard
                     output stream.

  -y 2001 | 2002 | 2018    Sets the instruction set architecture (ISA) to 2001
                     (project requirements prior to 2002), 2002
                     (requirements as of 2002) or to 2018 (requirements as of 2018 and later.
		     Default is 2018.The ISA architecture is defined in the accompanied
		     isa20xx.py file that must be present within the same directory as the assembler.

  -d <depth>	Sets the memory depth to <depth>.  This value is used
		during assembly to trap programs larger than the specified
		size, and is used as the MEMORY_DEPTH parameter in the
		generated Xilinx MEM file.  Default is 128 for 2002 ISA,
		256 for 2001 ISA, 512 for the 2018 ISA and 2048 for 2024 ISA. Please ensure that this limit
		is congruent with your design. The default value is defined in the isa20xx.py file.

  -b   Byte addressable cpu code

  -w   Word addressable cpu code


features:
- .Data and .Code directives
- Variable declarations:
	* DB - One-byte and string,
	* DW - two-byte,
	* EQU - constant
	** Example:
		.DATA
		VB1			DB		0x55
		VB2			DB		0x12, 51, 0x07, 0x41
		VW1			DW		0x56
		STR1		DB		"Hello!"
		CV1			EQU		0xAA

- Syntax checking.
- Label substitution.
- Labelled data declarations.
- Branch instruction expansion (using R2).
- Output in Xilinx MEM file format.
- Variable memory depth.
- Comments.
- Associated simulator (unsupported).
- Associated disassembler (unsupported).
""")
		sys.exit(-1)

	# determine the instruction set to use
	instruction_set_version = opt_hash.get('-y', '2024')

	if instruction_set_version == '2001':
		from isa2001 import *
	elif instruction_set_version == '2002':
		from isa2002 import *
	elif instruction_set_version == '2018':
		from isa2018 import *
	elif instruction_set_version == '2024':
		from isa2024 import *
	else:
		sys.stderr.write('ERROR: Unsupported instruction set architecture given (%s)\n' % instruction_set_version)
		sys.exit(-1)

	# determine the memory depth
	try:
		memory_depth = int(opt_hash.get('-d', str(DEFAULT_MEMORY_DEPTH)))
	except ValueError:
		sys.stderr.write('Expected integer memory depth specification, got %s' % opt_hash['-d'])
		sys.exit(-1)

	# determine the output file
	if "-o" in opt_hash:
		ListingStream = open(opt_hash['-o']+".lst", 'w')
		HexStream = open(opt_hash['-o']+".hex", 'w')
		CoeStream = open(opt_hash['-o']+".coe", 'w')
	else:
		HexStream = None
		CoeStream = None
		ListingStream = sys.stdout

	if "-b" in opt_hash:
		byte_addressable = True

	if "-w" in opt_hash:
		byte_addressable = False


	# read in the source file
	input_file_name = args[0]
	if input_file_name == '-':
		input_stream = sys.stdin
	else:
		try:
			input_stream = open(input_file_name)
		except IOError:
			sys.stderr.write('Could not open input file "%s".  Be sure the input file is given after all options.\n' % input_file_name)
			sys.exit(-1)

	assembly_code_string = ''
	for line in input_stream.readlines():
		assembly_code_string = assembly_code_string + line

	# instantiate an assembler object
	a = Assembler(memory_depth)

	# assemble the string
	a.AssembleString(assembly_code_string)

	# write the mem file to the output stream
	ListingStream.write(a.MachineCode2String() + '\n')

	if ( CoeStream != None ):
		CoeStream.write(a.MachineCode2CoeString() + '\n')

	if ( HexStream != None ):
		HexStream.write(a.MachineCode2HexString() + '\n')

