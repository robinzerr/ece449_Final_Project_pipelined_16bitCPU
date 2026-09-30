----------------------------------------------------------------------------------
-- University of Victoria
-- Engineer: Robin Zerr / Ava Birtwistle
--
-- Create Date: 03/28/2026 04:26:59 PM
-- Design Name: pipeline_registers
-- Module Name: pipeline_registers
-- Project Name: 16 Bit CPU
-- Target Devices: Artix-7 xc7a100tcsg324-1
-- Tool Versions: Vivado 2025.2
-- Description: This package defines the record types used for the CPU pipeline
-- registers. It groups the data and control signals passed between the IF/ID,
-- ID/EX, EX/MEM, and MEM/WB stages.
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package pipeline_registers is

    type IF_ID is record
        instruction : std_logic_vector(15 downto 0); -- the binary code instrcution which was fetched from instruction memory
        pc_plus2       : std_logic_vector(15 downto 0);
    end record;


    type ID_EX is record
        rd_data1  : std_logic_vector(15 downto 0); -- obtained from rd_index1
        rd_data2  : std_logic_vector(15 downto 0); -- obtained from rd_index2
        imm       : std_logic_vector(15 downto 0); -- immediate value
        dest_reg  : std_logic_vector(2 downto 0); --destination register index
        src1_reg  : std_logic_vector(2 downto 0); -- source register index for forwarding/hazard handling
        src2_reg  : std_logic_vector(2 downto 0); -- source register index for forwarding/hazard handling
        src1_used : std_logic; -- tracks whether source 1 is consumed in execute
        src2_used : std_logic; -- tracks whether source 2 is consumed in execute
        pc_plus2  : std_logic_vector(15 downto 0);

        alu_mode  : std_logic_vector(2 downto 0); -- selects mode of ALU
        alu_src   : std_logic; -- select whether its IMM or Rd_data2
        shift_amt : std_logic_vector(3 downto 0); -- the amount the data is shifted
        
        -- Memory control signals (riding along to MEM)
        wr_en_MEM : std_logic;

        -- Write-back control signals (riding along to WB)
        reg_write : std_logic;
        wb_src    : std_logic_vector(1 downto 0);
        out_p_EN  : std_logic;
        in_data   : std_logic_vector(15 downto 0);

    end record;

    type EX_MEM is record
        alu_result : std_logic_vector(15 downto 0); -- ALU computed result
        rd_data2   : std_logic_vector(15 downto 0); -- store data (STORE @addr, rd_data2)
        dest_reg   : std_logic_vector(2  downto 0); -- destination register index (rd)
        pc_plus2   : std_logic_vector(15 downto 0); -- PC+2 (for BRL return address)

        --  Memory control signals (consumed in MEM) 
        wr_en_MEM  : std_logic;

        -- Write-back control signals (riding along to WB)
        reg_write  : std_logic;                     -- '1' = write to reg file
        wb_src     : std_logic_vector(1 downto 0); -- select write-back source
        out_p_EN   : std_logic;
        in_data    : std_logic_vector(15 downto 0);
    end record;

    type MEM_WB is record
        alu_result : std_logic_vector(15 downto 0); -- ALU computed result from EX/MEM
        mem_data   : std_logic_vector(15 downto 0); -- data returned from RAM
        dest_reg   : std_logic_vector(2 downto 0);  -- destination register index
        pc_plus2   : std_logic_vector(15 downto 0); -- PC+2 (for BRL return address)

        -- Write-back control signals (consumed in WB) 
        reg_write  : std_logic;                     -- '1' = write to reg file
        wb_src     : std_logic_vector(1 downto 0); -- select write-back source
        in_data    : std_logic_vector(15 downto 0);
    end record;

end package pipeline_registers;
