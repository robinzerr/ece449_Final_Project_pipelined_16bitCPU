library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_fetch is
end tb_fetch;

architecture sim of tb_fetch is
    signal clk         : std_logic := '0';
    signal reset       : std_logic := '0';
    signal rom_ena     : std_logic := '1';
    signal mode        : std_logic_vector(1 downto 0) := "00";
    signal in_pc       : std_logic_vector(15 downto 0) := (others => '0');
    signal pc          : std_logic_vector(15 downto 0);
    signal instruction : std_logic_vector(15 downto 0);
begin

    uut : entity work.fetch
        port map(
            clk         => clk,
            reset       => reset,
            rom_ena     => rom_ena,
            mode        => mode,
            in_pc       => in_pc,
            pc          => pc,
            instruction => instruction
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
        reset <= '1';
        wait for 20 ns;

        reset <= '0';
        mode <= "00";  -- increment mode
        rom_ena <= '1';

        wait for 200 ns;

        wait;
    end process;

end sim;
