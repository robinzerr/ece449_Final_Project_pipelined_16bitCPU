library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.tb_mem_helpers_pkg.all;

entity tb_FormatBTest3 is
end entity;

architecture sim of tb_FormatBTest3 is
    signal clk       : std_logic := '0';
    signal rst       : std_logic := '1';
    signal boot_mode : std_logic := '1';
    signal in_port   : std_logic_vector(15 downto 0) := (others => '0');
    signal out_port  : std_logic_vector(15 downto 0);

    constant INPUTS : slv16_array_t(0 to 3) := (
        x"FFFE", -- R0 = -2
        x"0003", -- R1 = 3
        x"0001", -- R2 = 1
        x"0005"  -- R3 = 5
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
        rst <= '1';
        wait_n_rising_edges(clk, 2);
        rst <= '0';

        drive_in_sequence_after_pipeline_fill(clk, in_port, INPUTS, 4);

        wait_n_rising_edges(clk, 20);

        -- Expected final architectural state: R6 = -10 = 0xFFF6.
        assert false report "FormatBTest3 stimulus completed. Check R6 = 0xFFF6 in waveforms." severity note;
        wait;
    end process;
end architecture;
