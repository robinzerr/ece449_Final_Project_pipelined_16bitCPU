----------------------------------------------------------------------------------
-- University of Victoria 
-- Engineer: Ava Birtwistle / Robin Zerr
--
-- Create Date: 02/02/2026 04:35:50 PM
-- Design Name:
-- Module Name: rom -
-- Project Name: 16 Bit CPU
-- Target Devices: Artix-7 xc7a100tcsg324-1 
-- Tool Versions: Vivado 2025-2
-- Description: This file implements the instruction memory for the 16-bit CPU
-- using a Xilinx single-port ROM primitive. It stores the program image and
-- provides synchronous instruction fetches based on the program counter address.
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
use IEEE.NUMERIC_STD.ALL;

library xpm;
use xpm.vcomponents.all;

entity rom is
    port
    (
        clk   : in  std_logic;
        rst   : in  std_logic;
        ena   : in  std_logic;
        addra : in  std_logic_vector(8 downto 0); -- 9-bit address input to access 512 words (16 bits each)
        douta : out std_logic_vector(15 downto 0) -- 16-bit data output from ROM
    );
end rom;

architecture Behavioral of rom is
begin

    xpm_memory_sprom_inst : xpm_memory_sprom
    generic map (
        ADDR_WIDTH_A         => 9, -- address width (number of bits used to address memory depth)
        AUTO_SLEEP_TIME      => 0,
        ECC_MODE             => "no_ecc",
        MEMORY_INIT_FILE     => "FormatBTest1.mem", -- update this field with the mem files used for simulation
        MEMORY_INIT_PARAM    => "0",
        MEMORY_OPTIMIZATION  => "true",
        MEMORY_PRIMITIVE     => "distributed",
        MEMORY_SIZE          => 8192, -- size in bits
        MESSAGE_CONTROL      => 0,
        READ_DATA_WIDTH_A    => 16,
        READ_LATENCY_A       => 0,
        READ_RESET_VALUE_A   => "0",
        SIM_ASSERT_CHK       => 0,
        USE_MEM_INIT         => 1,
        WAKEUP_TIME          => "disable_sleep"
    )
    port map (
        addra          => addra,
        clka           => clk,
        ena            => ena,
        injectdbiterra => '0',
        injectsbiterra => '0',
        regcea         => '0',
        rsta           => rst,
        sleep          => '0',
        douta          => douta,
        dbiterra       => open,
        sbiterra       => open
    );

end Behavioral;
