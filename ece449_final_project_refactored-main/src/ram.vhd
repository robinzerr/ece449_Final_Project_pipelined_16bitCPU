----------------------------------------------------------------------------------
-- University of Victoria 
-- Engineer: Robin Zerr / Ava Birtwistle
--
-- Create Date: 02/02/2026 04:35:50 PM
-- Design Name:
-- Module Name: ram -
-- Project Name: 16 Bit CPU
-- Target Devices: Artix-7 xc7a100tcsg324-1 
-- Tool Versions: Vivado 2025-2
-- Description: This file implements the CPU data memory using a Xilinx dual-port
-- distributed RAM primitive. It provides a read/write port for processor memory
-- access and a secondary read port for additional observation or future expansion.
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

-- xpm_memory_dpdistram: Dual Port Distributed RAM
-- Xilinx Parameterized Macro, version 2023.2
-- generic map fills in the template (components) parameters and the port map actually connects the signals

entity ram is
    port
    (
        clk      : in  std_logic;
        rst      : in  std_logic;

        -- Port A : CPU read/write port
        ena      : in  std_logic;
        wea      : in  std_logic_vector(0 downto 0);
        addra    : in  std_logic_vector(8 downto 0);
        dina     : in  std_logic_vector(15 downto 0);
        douta    : out std_logic_vector(15 downto 0);

        -- Port B : second port (read-only here, available if needed later)
        enb      : in  std_logic;
        addrb    : in  std_logic_vector(8 downto 0);
        doutb    : out std_logic_vector(15 downto 0)
    );
end ram;

architecture Behavioral of ram is
begin
    xpm_memory_dpdistram_inst : xpm_memory_dpdistram
    generic map (
       ADDR_WIDTH_A => 9,               -- needed to address 512 words
       ADDR_WIDTH_B => 9,               -- needed to address 512 words
       BYTE_WRITE_WIDTH_A => 16,        -- the size of chunks that you can write to memory at a time
       CLOCKING_MODE => "common_clock", -- String
       IGNORE_INIT_SYNTH => 0,          -- DECIMAL
       MEMORY_INIT_FILE => "none",      -- String
       MEMORY_INIT_PARAM => "0",        -- String
       MEMORY_OPTIMIZATION => "true",   -- String
       MEMORY_SIZE => 8192,             -- 1024 byte block corresponds to 8192 bits
       MESSAGE_CONTROL => 0,            --  enables the dynamic message reporting such as collision warnings when 1
       READ_DATA_WIDTH_A => 16,         -- the size of chunks that you can read from memory at a time (port B)
       READ_DATA_WIDTH_B => 16,         -- the size of chunks that you can read from memory at a time (port A)
       READ_LATENCY_A => 0,             -- number of pipeline registers between the memory and port
       READ_LATENCY_B => 0,             -- number of pipeline regiwsters betweent the memory and port
       READ_RESET_VALUE_A => "0",       -- resets the port A to all 0
       READ_RESET_VALUE_B => "0",       -- resets the port b to all 0
       RST_MODE_A => "SYNC",            -- synchronous reset
       RST_MODE_B => "SYNC",            -- synchronous reset
       SIM_ASSERT_CHK => 0,             -- DECIMAL; 0=disable simulation messages, 1=enable simulation messages
       USE_EMBEDDED_CONSTRAINT => 0,    -- DECIMAL
       USE_MEM_INIT => 1,               -- DECIMAL
       USE_MEM_INIT_MMI => 0,           -- DECIMAL
       WRITE_DATA_WIDTH_A => 16         -- the size of chunks that you can write to memory at a time (port A)
    )
    port map (
       douta => douta,   -- READ_DATA_WIDTH_A-bit output: Data output for port A read operations.
       doutb => doutb,   -- READ_DATA_WIDTH_B-bit output: Data output for port B read operations.
       addra => addra,   -- ADDR_WIDTH_A-bit input: Address for port A write and read operations.
       addrb => addrb,   -- ADDR_WIDTH_B-bit input: Address for port B write and read operations.
       clka => clk,     -- 1-bit input: Clock signal for port A. Also clocks port B when parameter
                         -- CLOCKING_MODE is "common_clock".
    
       clkb => clk,     -- 1-bit input: Clock signal for port B when parameter CLOCKING_MODE is
                         -- "independent_clock". Unused when parameter CLOCKING_MODE is "common_clock".
    
       dina => dina,     -- WRITE_DATA_WIDTH_A-bit input: Data input for port A write operations.
       ena => ena,       -- 1-bit input: Memory enable signal for port A. Must be high on clock cycles when read
                         -- or write operations are initiated. Pipelined internally.
    
       enb => enb,       -- 1-bit input: Memory enable signal for port B. Must be high on clock cycles when read
                         -- or write operations are initiated. Pipelined internally.
    
       regcea => '0', -- 1-bit input: Clock Enable for the last register stage on the output data path.
       regceb => '0', -- 1-bit input: Do not change from the provided value.
       rsta => rst,     -- 1-bit input: Reset signal for the final port A output register stage. Synchronously
                         -- resets output port douta to the value specified by parameter READ_RESET_VALUE_A.
    
       rstb => rst,     -- 1-bit input: Reset signal for the final port B output register stage. Synchronously
                         -- resets output port doutb to the value specified by parameter READ_RESET_VALUE_B.
    
       wea => wea        -- WRITE_DATA_WIDTH_A/BYTE_WRITE_WIDTH_A-bit input: Write enable vector for port A
                         -- input data port dina. 1 bit wide when word-wide writes are used. In byte-wide write
                         -- configurations, each bit controls the writing one byte of dina to address addra. For
                         -- example, to synchronously write only bits [15-8] of dina when WRITE_DATA_WIDTH_A is
                         -- 32, wea would be 4'b0010.
    
    );
end Behavioral;
-- End of xpm_memory_dpdistram_inst instantiation
