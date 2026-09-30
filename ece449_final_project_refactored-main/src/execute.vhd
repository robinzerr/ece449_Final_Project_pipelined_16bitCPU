----------------------------------------------------------------------------------
-- University of Victoria 
-- Engineer: Ava Birtwistle / Robin Zerr
-- 
-- Create Date: 03/28/2026 11:49:37 AM
-- Design Name: 
-- Module Name: execute - Behavioral
-- Project Name: 16 Bit CPU
-- Target Devices: Artix-7 xc7a100tcsg324-1 
-- Tool Versions: Vivado 2025-2
-- Description: This file implements the execute stage of the 16-bit CPU. It
-- selects ALU operands from the ID/EX pipeline register, performs the requested
-- operation, updates status flags, and forwards results to the EX/MEM stage.
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

use work.constants_package.all;
use work.pipeline_registers.all;  

entity execute is
 port(

       -- from WB stage -- ride alongs?  we should have this in the top level
    --   wb_wr_en      : in  std_logic;
   --    wb_dest       : in  std_logic_vector(2 downto 0);
   --    wb_data       : in  std_logic_vector(15 downto 0);

         -- from ID/EX pipeline register
        rd_data1     : in std_logic_vector(15 downto 0);
        rd_data2     : in std_logic_vector(15 downto 0);
        imm          : in std_logic_vector(15 downto 0);
        ex_mem_value : in std_logic_vector(15 downto 0);
        mem_wb_value : in std_logic_vector(15 downto 0);
        fwd_a_sel    : in std_logic_vector(1 downto 0);
        fwd_b_sel    : in std_logic_vector(1 downto 0);
        dest_reg     : in std_logic_vector(2 downto 0);
        pc_plus2     : in std_logic_vector(15 downto 0);
        
        alu_mode   : in std_logic_vector(2 downto 0);
        alu_src    : in std_logic;
        wr_en_MEM  : in std_logic;
        reg_write  : in std_logic;
        wb_src     : in std_logic_vector(1 downto 0);
        out_p_EN   : in std_logic; -- ride along to memory for OUT
        shift_amount: in  std_logic_vector(3 downto 0) ;     
        -- outputs to EX/MEM pipeline register
        alu_result : out std_logic_vector(15 downto 0);
        rd_data2_out : out std_logic_vector(15 downto 0);
        dest_reg_out : out std_logic_vector(2 downto 0);
        pc_plus2_out : out std_logic_vector(15 downto 0);
        
        wr_en_MEM_out : out std_logic;
        reg_write_out : out std_logic;
        wb_src_out    : out std_logic_vector(1 downto 0);
        out_p_EN_out  : out std_logic; -- ride along to memory
        flag_zero_out     : out std_logic; 
        flag_negative_out : out std_logic; 
        flag_carry_out    : out std_logic;
        flag_overflow_out : out std_logic 
    );                                  
end execute;

architecture Behavioral of execute is
    -- Internal input signals to the ALU 
    signal source_1_data_internal : std_logic_vector(15 downto 0); 
    signal source_2_reg_internal  : std_logic_vector(15 downto 0);
    signal source_2_data_internal : std_logic_vector(15 downto 0);

    -- internal output signals from the ALU
    signal result_internal        : std_logic_vector(15 downto 0);
    signal flag_zero_internal     : std_logic;
    signal flag_negative_internal : std_logic;
    signal flag_carry_internal    : std_logic;
    signal flag_overflow_internal : std_logic;

begin
        process(rd_data1, ex_mem_value, mem_wb_value, fwd_a_sel)
    begin
        case fwd_a_sel is
            when "01" =>
                source_1_data_internal <= ex_mem_value;
            when "10" =>
                source_1_data_internal <= mem_wb_value;
            when others =>
                source_1_data_internal <= rd_data1;
        end case;
    end process;

    process(rd_data2, ex_mem_value, mem_wb_value, fwd_b_sel)
    begin
        case fwd_b_sel is
            when "01" =>
                source_2_reg_internal <= ex_mem_value;
            when "10" =>
                source_2_reg_internal <= mem_wb_value;
            when others =>
                source_2_reg_internal <= rd_data2;
        end case;
    end process;

    source_2_data_internal <= source_2_reg_internal when alu_src = '0' else imm;


    -- instantiate the ALU
    u_alu : entity work.Alu
        port map(
            shift_amount => shift_amount,
            a           => source_1_data_internal,
            b           => source_2_data_internal,
            result      => result_internal,
            control_sel => alu_mode, -- direct connection
            Carry       => flag_carry_internal,
            Zero        => flag_zero_internal,
            Negative    => flag_negative_internal,
            Overflow    => flag_overflow_internal
        );
    -- output to the EX/MEM pipeline register
    rd_data2_out  <= source_2_reg_internal; -- forwarded store data must reach memory
    dest_reg_out  <= dest_reg; 
    pc_plus2_out  <= pc_plus2;
    wr_en_MEM_out <= wr_en_MEM;
    reg_write_out <= reg_write;
    wb_src_out    <= wb_src;
    out_p_EN_out  <= out_p_EN;

    -- map the internal signals set by the ALU to the outputs accessible in top level
    flag_zero_out     <= flag_zero_internal;
    flag_negative_out <= flag_negative_internal;
    flag_carry_out    <= flag_carry_internal;
    flag_overflow_out <= flag_overflow_internal;
    alu_result    <= result_internal;
end Behavioral;
