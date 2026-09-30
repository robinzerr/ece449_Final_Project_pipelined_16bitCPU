----------------------------------------------------------------------------------
-- University of Victoria
-- Engineer: Robin Zerr / Ava Birtwistle
--
-- Create Date: 02/02/2026 04:35:50 PM
-- Design Name: constants_package
-- Module Name: constants_package
-- Project Name: 16 Bit CPU
-- Target Devices: Artix-7 xc7a100tcsg324-1
-- Tool Versions: Vivado 2025.2
-- Description: This package defines shared constants used throughout the 16-bit
-- CPU design. It includes ALU modes, writeback selection signals, program counter
-- control modes, opcodes, and memory-mapped I/O addresses.
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package constants_package is 

    -- ALU operation modes
    constant ALU_NOP  : std_logic_vector(2 downto 0) := "000";
    constant ALU_ADD  : std_logic_vector(2 downto 0) := "001";
    constant ALU_SUB  : std_logic_vector(2 downto 0) := "010";
    constant ALU_MUL  : std_logic_vector(2 downto 0) := "011";
    constant ALU_NAND : std_logic_vector(2 downto 0) := "100";
    constant ALU_SHL  : std_logic_vector(2 downto 0) := "101";
    constant ALU_SHR  : std_logic_vector(2 downto 0) := "110";
    constant ALU_TEST : std_logic_vector(2 downto 0) := "111";

    --  modes for selecting the value to write back to the register file in the WB stage
    constant WB_ALU : std_logic_vector(1 downto 0) := "00";
    constant WB_MEM : std_logic_vector(1 downto 0) := "01";
    constant WB_PC2 : std_logic_vector(1 downto 0) := "10";
    constant WB_AUX : std_logic_vector(1 downto 0) := "11";

    -- program counter modes
    constant PC_INCREMENT : std_logic_vector(1 downto 0) := "00"; -- increment the PC by 2 to point to the next instruction
    constant PC_LOAD_NEW_VAL      : std_logic_vector(1 downto 0) := "01"; -- update the PC with an immediate value (for jumps and branches)
    constant PC_STALL           : std_logic_vector(1 downto 0) := "10"; -- hold the current value of the PC (no update)
    constant PC_BOOT_MODE         : std_logic_vector(1 downto 0) := "11"; -- when asserted with reset, then load mode reset vector is loaded
    constant PC_RESET_AND_EXECUTE_VAL        : std_logic_vector(15 downto 0) := x"0000"; -- value loaded on program start, when reset is '1' and mode is not PC_BOOT_MODE
    constant PC_RESET_AND_LOAD_VAL        : std_logic_vector(15 downto 0) := x"0002"; -- load mode reset vector


    -- The opcode values for the instruction types
    constant OP_NOP      : std_logic_vector(6 downto 0) := "0000000"; -- 0, NOP
    constant OP_ADD      : std_logic_vector(6 downto 0) := "0000001"; -- 1, ADD
    constant OP_SUB      : std_logic_vector(6 downto 0) := "0000010"; -- 2, SUB
    constant OP_MUL      : std_logic_vector(6 downto 0) := "0000011"; -- 3, MUL
    constant OP_NAND     : std_logic_vector(6 downto 0) := "0000100"; -- 4, NAND
    constant OP_SHL      : std_logic_vector(6 downto 0) := "0000101"; -- 5, SHL
    constant OP_SHR      : std_logic_vector(6 downto 0) := "0000110"; -- 6, SHR
    constant OP_TEST     : std_logic_vector(6 downto 0) := "0000111"; -- 7, Test

    constant OP_LOAD     : std_logic_vector(6 downto 0) := "0010000"; -- 16, LOAD
    constant OP_STORE    : std_logic_vector(6 downto 0) := "0010001"; -- 17, Store
    constant OP_LOADIMM  : std_logic_vector(6 downto 0) := "0010010"; -- 18, Load immediate
    constant OP_MOV      : std_logic_vector(6 downto 0) := "0010011"; -- 19, move

    constant OP_OUT      : std_logic_vector(6 downto 0) := "0100000"; -- 32, out
    constant OP_IN       : std_logic_vector(6 downto 0) := "0100001"; -- 33, in

    -- branch instruction
    constant OP_BRR      : std_logic_vector(6 downto 0) := "1000000"; -- 64, branch
    constant OP_BRR_N    : std_logic_vector(6 downto 0) := "1000001"; -- 65, branch if not zero
    constant OP_BRR_Z    : std_logic_vector(6 downto 0) := "1000010"; -- 66, branch if zero
    constant OP_BR       : std_logic_vector(6 downto 0) := "1000011"; -- 67, branch if negative
    constant OP_BR_N     : std_logic_vector(6 downto 0) := "1000100"; -- 68, branch if not negative
    constant OP_BR_Z     : std_logic_vector(6 downto 0) := "1000101"; -- 69, branch if not zero and not negative
    constant OP_BR_SUB   : std_logic_vector(6 downto 0) := "1000110"; -- 70, branch to subroutine (jump and link, save return address in r7)
    constant OP_RETURN   : std_logic_vector(6 downto 0) := "1000111"; -- 71, return from subroutine (jump to address in r7)
    constant OP_BRR_V    : std_logic_vector(6 downto 0) := "1001000"; -- 72, branch relative if overflow

    -- stack operations
    constant OP_PUSH     : std_logic_vector(6 downto 0) := "1100000"; -- 96, push the value in the specified register onto the stack (decrement stack pointer and store value at new top of stack)
    constant OP_POP      : std_logic_vector(6 downto 0) := "1100001"; -- 97, pop the value from the top of the stack into the specified register (load value from top of stack and increment stack pointer)
    constant OP_LOAD_SP  : std_logic_vector(6 downto 0) := "1100010"; -- 98, load the stack pointer with an immediate value (used for stack initialization, SP starts at top of memory and grows downwards so we can load it with the max memory address)
    constant OP_RTI      : std_logic_vector(6 downto 0) := "1100011"; -- 99, return from interrupt (jump to address in r7 and restore r7 with value at top of stack, increment stack pointer)

    -- Link/return register
    constant LINK_REGISTER      : std_logic_vector(2 downto 0) := "111"; -- 7, return from interrupt (jump to address in r7 and restore r7 with value at top of stack, increment stack pointer)

end package constants_package;
