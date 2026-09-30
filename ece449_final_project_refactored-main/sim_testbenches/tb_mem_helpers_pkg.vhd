library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package tb_mem_helpers_pkg is
    type slv16_array_t is array (natural range <>) of std_logic_vector(15 downto 0);

    procedure wait_n_rising_edges(
        signal clk : in std_logic;
        constant n : in natural
    );

    procedure drive_in_sequence_after_pipeline_fill(
        signal clk     : in std_logic;
        signal in_port : out std_logic_vector(15 downto 0);
        constant vals  : in slv16_array_t;
        constant fill_cycles : in natural := 4
    );
end package;

package body tb_mem_helpers_pkg is
    procedure wait_n_rising_edges(
        signal clk : in std_logic;
        constant n : in natural
    ) is
    begin
        for i in 1 to n loop
            wait until rising_edge(clk);
        end loop;
    end procedure;

    procedure drive_in_sequence_after_pipeline_fill(
        signal clk     : in std_logic;
        signal in_port : out std_logic_vector(15 downto 0);
        constant vals  : in slv16_array_t;
        constant fill_cycles : in natural := 4
    ) is
    begin
        if vals'length = 0 then
            return;
        end if;

        -- Hold the first input value long enough for the first IN instruction
        -- to reach write-back in the current 4-stage pipeline.
        in_port <= vals(vals'low);
        wait_n_rising_edges(clk, fill_cycles);

        -- Each subsequent IN instruction is expected to retire one clock apart.
        for i in vals'low + 1 to vals'high loop
            in_port <= vals(i);
            wait until rising_edge(clk);
        end loop;

        -- Keep the final value stable afterwards.
        in_port <= vals(vals'high);
    end procedure;
end package body;
