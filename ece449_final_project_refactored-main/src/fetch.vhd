----------------------------------------------------------------------------------
-- University of Victoria
-- Engineer: Ava Birtwistle / Robin Zerr
--
-- Create Date: 02/02/2026 04:35:50 PM
-- Design Name:
-- Module Name: fetch -
-- Project Name: 16 Bit CPU
-- Target Devices: Artix-7 xc7a100tcsg324-1 
-- Tool Versions: Vivado 2025-2
-- Description: This file implements the fetch stage of the 16-bit CPU. It
-- coordinates the program counter and instruction ROM to fetch the next
-- instruction and forward the current PC value and instruction to the IF/ID stage.
--
-- Dependencies: program_counter.vhd, rom.vhd, constant_package.vhd
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- wired to the IF/ID pipeline register in the top level file
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.constants_package.all; 

entity fetch is
    port(
        clk     : in  std_logic; -- clock is used by the register file
        reset   : in  std_logic; -- reset is used by the register file
        pc_reset    : in  std_logic;
        rom_ena  : in  std_logic; -- enable signal for the ROM (can be used to stall the fetch stage when needed)
        mode   : in  std_logic_vector(1 downto 0); -- selects the mode for the program counter (increment, loading immediate value, etc.)
        in_pc   : in  std_logic_vector(15 downto 0); -- the immediate value to load into the program counter when mode is PC_IM_VALUE
        -- output signals that flow into the IF/ID pipeline register
        pc      : out  std_logic_vector(15 downto 0); -- the current value of the program counter that will be used to fetch the instruction from ROM
        instruction : out std_logic_vector(15 downto 0)-- the instruction fetched from ROM that will be passed to the IF/ID pipeline register

    );
end fetch;

architecture Behavioral of fetch is 
    signal pc_sig_internal : std_logic_vector(15 downto 0); -- internal signal to connect the program counter to the rom
    signal rom_instruction_sig_internal : std_logic_vector(15 downto 0);
begin

    -- instantiate the program counter and connect the ports appropriately
    program_counter: entity work.program_counter
        port map ( 
            clk      => clk,
            reset    => reset,
            pc_reset => pc_reset,
            mode     => mode,
            out_pc   => pc_sig_internal, -- out_pc is the current value of the program counter that will be used to fetch the instruction from ROM
            in_pc    => in_pc -- in_pc is the immediate value to load into the program counter when mode is PC_IM_VALUE
        );

-- Instantiate the ROM here and connect the ports appropriately
    rom: entity work.rom
     port map(
        clk => clk,
        rst => reset,
        ena   => rom_ena,
        addra => pc_sig_internal(9 downto 1), -- 9-bit address input to access 512 words (16 bits each) but we need pc=0b0001 to map to 0b0000 in rom and pc=0b00010 to map to 0b0001 in rom (drop lsb)
        douta => rom_instruction_sig_internal -- 16-bit data output from ROM
    );

    pc <= pc_sig_internal; -- connect the internal signal to the output port to pass the current value of the program counter to the IF/ID pipeline register
    instruction <= rom_instruction_sig_internal; 
end Behavioral;
