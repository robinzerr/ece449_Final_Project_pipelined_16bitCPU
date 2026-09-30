----------------------------------------------------------------------------------
-- University of Victoria 
-- Engineer: Robin Zerr / Ava Birtwistle
--
-- Create Date: 02/02/2026 04:35:50 PM
-- Design Name:
-- Module Name: register_file -
-- Project Name: 16 Bit CPU
-- Target Devices: Artix-7 xc7a100tcsg324-1 
-- Tool Versions: Vivado 2025-2
-- Description: This file implements the 8-register, 16-bit register file used by
-- the CPU. It supports synchronous writes, two combinational read ports, and
-- simple same-cycle forwarding to handle read-after-write behavior.
--
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity register_file is
  Port (
        clk, reset, wr_en: in std_logic;
        w_addr: in std_logic_vector(2 downto 0); -- index for reg to write to
        w_data: in std_logic_vector(15 downto 0); -- data to write
        r_addr0, r_addr1: in std_logic_vector(2 downto 0); -- indices for regs to read from
        r_data0, r_data1: out std_logic_vector(15 downto 0) -- outputs for data read from the register file
  );
end register_file;

architecture rtl of register_file is

type reg_file_type is array (7 downto 0) of std_logic_vector(15 downto 0);

signal array_reg: reg_file_type; -- this signal represents the current state of the register file values, we will update this on the rising edge of the clock with the next state values stored in array_next
signal array_next: reg_file_type; -- we need this signal to hold the next state of the register file values so we can update them all at once on the rising edge of the clock

begin
    process(clk,reset) -- process to update the state of the register file 
    begin
        if(reset = '1') then
            array_reg(0) <= (others => '0');
            array_reg(1) <= (others => '0');
            array_reg(2) <= (others => '0');
            array_reg(3) <= (others => '0');
            array_reg(4) <= (others => '0');
            array_reg(5) <= (others => '0');
            array_reg(6) <= (others => '0');
            array_reg(7) <= (others => '0');
        elsif (rising_edge(clk)) then
            array_reg(0) <= array_next(0);            
            array_reg(1) <= array_next(1);            
            array_reg(2) <= array_next(2);            
            array_reg(3) <= array_next(3);            
            array_reg(4) <= array_next(4);            
            array_reg(5) <= array_next(5);            
            array_reg(6) <= array_next(6);            
            array_reg(7) <= array_next(7);                          
        end if;
     end process;
     
     process(array_reg, wr_en, w_addr, w_data)
     begin
        array_next <= array_reg;
        if wr_en = '1' then
            array_next(to_integer(unsigned(w_addr))) <= w_data;
        end if;
     end process;
     
     -- output the register values corresponding to read address
     -- in case of RAW, the value to be written is forwarded to the output
     r_data0 <= w_data when (wr_en = '1' and w_addr = r_addr0) else array_reg(to_integer(unsigned(r_addr0)));
     r_data1 <= w_data when (wr_en = '1' and w_addr = r_addr1) else array_reg(to_integer(unsigned(r_addr1)));
end rtl;
