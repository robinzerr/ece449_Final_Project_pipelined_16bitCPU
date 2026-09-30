----------------------------------------------------------------------------------
-- University of Victoria 
-- Engineer: Ava Birtwistle / Robin Zerr
-- 
-- Create Date: 02/09/2026 04:54:41 PM
-- Design Name: 
-- Module Name: ProgramCounter - Behavioral
-- Project Name: 16 Bit CPU
-- Target Devices: Artix-7 xc7a100tcsg324-1 
-- Tool Versions: Vivado 2025-2
-- Description: This file implements the program counter used by the fetch stage
-- of the 16-bit CPU. It supports reset, sequential incrementing, and loading a
-- new address for branch, jump, or immediate program counter updates.
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- For the case switch in the process, we need to increment the current value of the program counter by 2
-- the current value of the program counter is access externally on the out_pc port. Since this is an output port
-- we cannot read from it directly, increment it by 2 and then output this new value as we would essentially be using the 
-- output port as an input which is not allowed. To get around this, we can use an internal signal (pc_curr) to grab the current value 
-- so we can increment it 

----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
library work;
use work.constants_package.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity program_counter is
Port ( 
    clk: in std_logic;
    reset: in std_logic;
    pc_reset: in std_logic; -- signal to reset the program counter in fetch
    mode: in std_logic_vector(1 downto 0);
    in_pc: in std_logic_vector(15 downto 0); -- in_pc is the immediate value to load into the program counter when mode is PC_IM_VALUE

    out_pc: out std_logic_vector(15 downto 0) -- out_pc is the current value of the program counter that will be used to fetch the instruction from ROM
);
end program_counter;

architecture Behavioral of program_counter is
    signal pc_curr: std_logic_vector(15 downto 0) := (others => '0'); -- using others 0 is better than "0000000000000000" because it is more concise and less error-prone
begin
    -- Process to update the program counter on the rising edge of the clock
    process(clk)
    begin 
        if rising_edge(clk) then
            if reset = '1' or pc_reset = '1' then
                if mode = PC_BOOT_MODE then
                    pc_curr <= PC_RESET_AND_LOAD_VAL;
                else
                    pc_curr <= PC_RESET_AND_EXECUTE_VAL; -- reset the program counter to 0
            end if;
            else
                case mode is
                    when PC_INCREMENT =>
                        pc_curr <= std_logic_vector(unsigned(pc_curr) + 2); -- increment by 2 to get the next instruction address
                    when PC_LOAD_NEW_VAL =>
                        pc_curr <= in_pc; -- load the immediate value into the program counter
                    when PC_STALL => -- can be removed (here for readability)
                        pc_curr <= pc_curr; -- hold the current value of the program counter
                    when others => -- do nothing
                end case;
            end if;
        end if;
    end process;
    out_pc <= pc_curr; -- update the output port with the current value of the program counter
end Behavioral;
