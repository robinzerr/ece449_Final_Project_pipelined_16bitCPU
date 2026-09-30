----------------------------------------------------------------------------------
-- University of Victoria 
-- Engineer: Ava Birtwistle / Robin Zerr
--
-- Create Date: 02/02/2026 04:35:50 PM
-- Design Name:
-- Module Name: decoder -
-- Project Name: 16 Bit CPU
-- Target Devices: Artix-7 xc7a100tcsg324-1 
-- Tool Versions: Vivado 2025-2
-- Description: This file implements the instruction field decoder for the 16-bit
-- CPU. It extracts opcode, register indices, shift amounts, and displacement
-- values from the raw instruction word for use in the decode stage.
--
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

library work;
use work.constants_package.all;

entity decoder is
    port(
        instruction    : in  std_logic_vector(15 downto 0); -- unprocessed instruction from the IF/ID pipeline register

        opcode      : out std_logic_vector(6 downto 0); -- the opcode of the instruction, used by controller to 
        destination_reg : out std_logic_vector(2 downto 0); -- the index of the register to write for R-type instructions
        source_1 : out std_logic_vector(2 downto 0); -- the index of the register to read for operand 1 
        source_2 : out std_logic_vector(2 downto 0); -- the index of the register to read for operand 2 
        shift_amt : out std_logic_vector(3 downto 0); -- the amount to shift for shift instructions
        disp: out signed(15 downto 0)
        );
end decoder;

architecture Behavioral of decoder is
begin
    process(instruction) -- only needs to run when the INSTUCTION changes, but it doesn't matter if it runs more often than that
        begin
            -- default values
            destination_reg <= (others => '0');
            source_1        <= (others => '0'); -- the first data source to read
            source_2        <= (others => '0'); -- the second data source to read
            shift_amt       <= (others => '0');
            disp            <= (others => '0'); -- this is used to calculate the branch target
            
            case instruction(15 downto 9) is 
                when OP_NOP => -- format A0
                    NULL;

                -- Format A
                when OP_ADD | OP_SUB | OP_MUL | OP_NAND => -- A1 Format
                    destination_reg <= instruction(8 downto 6); -- index for ra
                    source_1        <= instruction(5 downto 3); -- index for rb
                    source_2        <= instruction(2 downto 0); -- index for rc

                when OP_SHL | OP_SHR => -- A2 Format
                    source_1        <= instruction(8 downto 6); -- index for ra
                    destination_reg <= instruction(8 downto 6);
                    shift_amt       <= instruction(3 downto 0);

                when OP_TEST => -- A3 Format
                    source_1 <= instruction(8 downto 6); -- index for register we are testing

                when OP_OUT => -- A3 Format
                    source_1 <= instruction(8 downto 6); 
                    source_2 <= instruction(8 downto 6); 

                when OP_IN => -- A3 Format
                    destination_reg <= instruction(8 downto 6);
                
                when OP_BRR | OP_BRR_N | OP_BRR_Z | OP_BRR_V => -- B1 format
                   disp <= shift_left(resize(signed(instruction(8 downto 0)), 16), 1); -- the displcement amount to add, sign-extended and multiply by 2 since displacement is in terms of instructions and instructions are 2 bytes long
                
                when OP_BR | OP_BR_N | OP_BR_Z | OP_BR_SUB => -- format b2
                    source_1 <= instruction(8 downto 6); -- index for the register we will add the displacement to
                    disp <= shift_left(resize(signed(instruction(5 downto 0)), 16), 1); -- the displcement amount to add, sign-extended and multiply by 2 since displacement is in terms of instructions and instructions are 2 bytes long
                
                    if instruction(15 downto 9) = OP_BR_SUB then
                        destination_reg <= LINK_REGISTER; -- write the return address to the link register
                    end if;
                
                when OP_RETURN => -- format b3
                    source_1 <= LINK_REGISTER; -- we want to read from the link register index
                when OP_LOAD => -- Format L
                    destination_reg <= instruction(8 downto 6);
                    source_1        <= instruction(5 downto 3);

                when OP_STORE => -- Format L
                    source_1 <= instruction(8 downto 6);
                    source_2 <= instruction(5 downto 3);

                when OP_LOADIMM => -- Format L
                    destination_reg <= LINK_REGISTER;
                    source_1        <= LINK_REGISTER;

                when OP_MOV => -- Format L
                    destination_reg <= instruction(8 downto 6);
                    source_1        <= instruction(5 downto 3);
              
                when others=>
                    null;
            end case;
    end process;

    opcode <= instruction(15 downto 9); -- output the opcode for controller and decode
end Behavioral;
