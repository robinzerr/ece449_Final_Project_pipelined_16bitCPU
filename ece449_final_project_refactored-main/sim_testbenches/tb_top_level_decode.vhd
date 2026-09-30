library ieee;
use ieee.std_logic_1164.all;

entity tb_top_level_cpu is
end tb_top_level_cpu;

architecture sim of tb_top_level_cpu is
    signal clk       : std_logic := '0';
    signal reset     : std_logic := '0';
    signal boot_mode : std_logic := '0';
    signal in_port   : std_logic_vector(15 downto 0) := (others => '0');
    signal out_port  : std_logic_vector(15 downto 0);
begin

   
    uut : entity work.top_level_cpu
        port map(
            clk       => clk,
            reset     => reset,
            boot_mode => boot_mode,
            in_port   => in_port,
            out_port  => out_port
        );

    clk_process : process
    begin
        while true loop
            clk <= '0';
            wait for 5 ns;
            clk <= '1';
            wait for 5 ns;
        end loop;
    end process;

    stim_proc : process
    begin
        -- execute-mode reset
        boot_mode <= '0';
        reset <= '1';
        wait for 20 ns;

        reset <= '0';
        wait for 200 ns;

        -- load-mode reset
        boot_mode <= '1';
        reset <= '1';
        wait for 20 ns;

        reset <= '0';
        wait for 200 ns;

        wait;
    end process;

end sim;
