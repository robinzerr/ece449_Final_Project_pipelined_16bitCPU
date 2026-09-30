----------------------------------------------------------------------------------
-- University of Victoria 
-- Engineer: Robin Zerr / Ava Birtwistle
-- 
-- Create Date: 04/04/2026 11:06:18 AM
-- Design Name: 
-- Module Name: MUX - Behavioral
-- Project Name: 16 Bit CPU
-- Target Devices: Artix-7 xc7a100tcsg324-1 
-- Tool Versions: Vivado 2025-2
-- Description: This file implements a 3-input, 16-bit multiplexer. It selects
-- one of three input values based on the control signal and drives zero on the
-- output for unused selector combinations.
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity MUX is
  Port (
        a : in std_logic_vector(15 downto 0);
        b : in std_logic_vector(15 downto 0); 
        c : in std_logic_vector(15 downto 0); 
        control_sel : in std_logic_vector(1 downto 0);
        
        d_out : out std_logic_vector(15 downto 0)
   );
end MUX;

architecture Behavioral of MUX is -- selects a b or c input data to output at d_out depending on control bits. default is d = 0x0000;
signal d : std_logic_vector(15 downto 0) := (others => '0');
begin
    d_out <= a when (control_sel = "00") else 
             b when (control_sel = "01") else
             c when (control_sel = "10") else
             d;
end Behavioral;
