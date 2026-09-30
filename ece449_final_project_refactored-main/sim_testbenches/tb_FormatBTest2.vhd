library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.tb_mem_helpers_pkg.all;

entity tb_FormatBTest2 is
end entity;

architecture sim of tb_FormatBTest2 is
    signal clk       : std_logic := '0';
    signal rst       : std_logic := '1';
    signal boot_mode : std_logic := '0';
    signal in_port   : std_logic_vector(15 downto 0) := (others => '0');
    signal out_port  : std_logic_vector(15 downto 0);

    constant INPUTS : slv16_array_t(0 to 7) := (
        x"0002", -- R0
        x"0003", -- R1
        x"0001", -- R2
        x"0005", -- R3
        x"0210", -- R4 = 528 decimal
        x"0001", -- R5
        x"0005", -- R6
        x"0000"  -- R7
    );
begin
    uut : entity work.Top_Level_CPU
        port map (
            clk       => clk,
            rst       => rst,
            boot_mode => boot_mode,
            in_port   => in_port,
            out_port  => out_port
        );

    clk <= not clk after 5 ns;

    stim_proc : process
    begin
        -- This program is assembled at 0x0210 and uses BR.SUB / RETURN.
        rst <= '1';
        wait_n_rising_edges(clk, 2);
        rst <= '0';

        drive_in_sequence_after_pipeline_fill(clk, in_port, INPUTS, 4);

        wait_n_rising_edges(clk, 80);

        -- No OUT instruction exists in this test.
        -- Expected final architectural state:
        --   R1 = 158 (0x009E)
        --   R2 = 79  (0x004F)
        --   R6 = 0
        --   R7 = 0x0222 return address
        assert false report "FormatBTest2 stimulus completed. Check branch / return behavior and final registers in waveforms." severity note;
        wait;
    end process;
end architecture;
