----------------------------------------------------------------------------------
-- University of Victoria 
-- Engineer: Robin Zerr / Ava Birtwistle
--
-- Create Date: 02/02/2026 04:35:50 PM
-- Design Name:
-- Module Name: controller -
-- Project Name: 16 Bit CPU
-- Target Devices: Artix-7 xc7a100tcsg324-1 
-- Tool Versions: Vivado 2025-2
-- Description: This file implements the control unit for the 16-bit CPU. It
-- decodes the instruction opcode along with processor flags and boot mode to
-- generate datapath, memory, writeback, and program counter control signals.
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
library work;
use work.constants_package.all; 

entity controller is
    port(
        reset       : in  std_logic;

        -- Input from IF/ID pipeline register (Instruction bits 15 downto 9)
        opcode      : in  std_logic_vector(6 downto 0);

        -- Status flags from ALU
        flag_zero   : in  std_logic;
        flag_neg    : in  std_logic;
        flag_overflow : in std_logic;

        -- Boot mode, used for controlling program counter
        boot_mode   : in  std_logic;

        -- ALU Control Signals
        mode_ALU    : out std_logic_vector(2 downto 0);
        src_ALU     : out std_logic; -- selects source for second operand for ALU

        -- Write/ Memory control signals
        wr_en_REG   : out std_logic;
        sel_WB      : out std_logic_vector(1 downto 0); 
        wr_en_MEM   : out std_logic;
        
        -- I/O Port Control Signals
        in_p_EN     : out std_logic;
        out_p_EN    : out std_logic;

        -- Branch / PC Control
        pc_mode       : out std_logic_vector(1 downto 0); -- controls what happens to program counter in fetch
        pc_reset       : out std_logic -- signal to reset the program counter in fetch
    );
end controller;


architecture Behavioral of controller is
     
begin
    fsm_seq : process(opcode, reset, flag_zero, flag_neg, flag_overflow, boot_mode)
    begin
        mode_ALU  <= ALU_NOP;
        src_ALU   <= '0';
        wr_en_MEM <= '0';
        wr_en_REG <= '0';
        sel_WB    <= WB_ALU;
        in_p_EN   <= '0';
        out_p_EN  <= '0';
        pc_mode <= PC_INCREMENT; -- the signal for selecting the program counter mode in the fetch module
        pc_reset <= '0'; -- for reseting the program counter in the fetch module

        if reset = '1' then
            pc_reset <= '1';
            if boot_mode = '1' then -- reset into load mode
                pc_mode <= PC_BOOT_MODE;
            else                    -- reset into execute mode
                pc_mode <= PC_INCREMENT;
            end if;

        else -- no reset then check opcode to determine control signals for the instruction
            case opcode is
                when OP_NOP =>
                    mode_ALU  <= ALU_NOP;
                    src_ALU   <= '0';
                    wr_en_MEM <= '0';
                    wr_en_REG <= '0';
                    sel_WB    <= WB_ALU;
                    in_p_EN   <= '0';
                    out_p_EN  <= '0';
                    pc_mode <= PC_INCREMENT;

                when OP_ADD =>
                    mode_ALU  <= ALU_ADD;
                    src_ALU   <= '0';
                    wr_en_MEM <= '0';
                    wr_en_REG <= '1';
                    sel_WB    <= WB_ALU;
                    in_p_EN   <= '0';
                    out_p_EN  <= '0';
                    pc_mode <= PC_INCREMENT;
                    
                when OP_SUB =>
                    mode_ALU  <= ALU_SUB;
                    src_ALU   <= '0';
                    wr_en_MEM <= '0';
                    wr_en_REG <= '1';
                    sel_WB    <= WB_ALU;
                    in_p_EN   <= '0';
                    out_p_EN  <= '0';
                    pc_mode <= PC_INCREMENT;
                    
                when OP_MUL =>
                    mode_ALU  <= ALU_MUL;
                    src_ALU   <= '0';
                    wr_en_MEM <= '0';
                    wr_en_REG <= '1';
                    sel_WB    <= WB_ALU;
                    in_p_EN   <= '0';
                    out_p_EN  <= '0';
                    pc_mode <= PC_INCREMENT;
                    
                when OP_NAND =>
                    mode_ALU  <= ALU_NAND;
                    src_ALU   <= '0';
                    wr_en_MEM <= '0';
                    wr_en_REG <= '1';
                    sel_WB    <= WB_ALU;
                    in_p_EN   <= '0';
                    out_p_EN  <= '0';
                    pc_mode <= PC_INCREMENT;
                    
                when OP_SHL =>
                    mode_ALU  <= ALU_SHL;
                    src_ALU   <= '1'; -- 1 because the operand for the shift amount comes from the immediate field path
                    wr_en_MEM <= '0';
                    wr_en_REG <= '1';
                    sel_WB    <= WB_ALU;
                    in_p_EN   <= '0';
                    out_p_EN  <= '0';
                    pc_mode <= PC_INCREMENT;
                    
                when OP_SHR =>
                    mode_ALU  <= ALU_SHR;
                    src_ALU   <= '1'; -- 1 because the operand for shift amount comes from immediate field path
                    wr_en_MEM <= '0';
                    wr_en_REG <= '1';
                    sel_WB    <= WB_ALU;
                    in_p_EN   <= '0';
                    out_p_EN  <= '0';
                    pc_mode <= PC_INCREMENT;
                    
                when OP_TEST =>
                    mode_ALU  <= ALU_TEST;
                    src_ALU   <= '0';
                    wr_en_MEM <= '0';
                    wr_en_REG <= '0';  -- TEST sets flags only
                    sel_WB    <= WB_ALU;
                    in_p_EN   <= '0';
                    out_p_EN  <= '0';
                    pc_mode <= PC_INCREMENT;
                    
                when OP_OUT =>
                    mode_ALU  <= ALU_NOP;
                    src_ALU   <= '0';
                    wr_en_MEM <= '0';
                    wr_en_REG <= '0';
                    sel_WB    <= WB_ALU;
                    in_p_EN   <= '0';
                    out_p_EN  <= '1';
                    pc_mode <= PC_INCREMENT;
                    
                when OP_IN =>
                    mode_ALU  <= ALU_NOP;
                    src_ALU   <= '0';
                    wr_en_MEM <= '0';
                    wr_en_REG <= '1';
                    sel_WB    <= WB_AUX;
                    in_p_EN   <= '1';
                    out_p_EN  <= '0';
                    pc_mode <= PC_INCREMENT;

                -- branch relative
                when OP_BRR =>                        -- Branch relative, unconditional: PC = PC + imm
                    mode_ALU  <= ALU_NOP;             -- target computed in decode (pc_plus2 + imm), ALU not needed
                    src_ALU   <= '0';
                    wr_en_MEM <= '0';
                    wr_en_REG <= '0';
                    sel_WB    <= WB_ALU;
                    in_p_EN   <= '0';
                    out_p_EN  <= '0';
                    pc_mode <= PC_LOAD_NEW_VAL;
                    
                when OP_BRR_N =>                      -- Branch relative if negative: PC = PC + imm if flag_neg
                    mode_ALU  <= ALU_NOP;             -- target computed in decode (pc_plus2 + imm), ALU not needed
                    src_ALU   <= '0';
                    wr_en_MEM <= '0';
                    wr_en_REG <= '0';
                    sel_WB    <= WB_ALU;
                    in_p_EN   <= '0';
                    out_p_EN  <= '0';
                    if flag_neg = '1' then 
                        pc_mode <= PC_LOAD_NEW_VAL;
                    else
                        pc_mode <= PC_INCREMENT;
                    end if;
                    
                when OP_BRR_Z =>                      -- Branch relative if zero: PC = PC + imm if flag_zero
                    mode_ALU  <= ALU_NOP;             -- target computed in decode (pc_plus2 + imm), ALU not needed
                    src_ALU   <= '0';
                    wr_en_MEM <= '0';
                    wr_en_REG <= '0';
                    sel_WB    <= WB_ALU;
                    in_p_EN   <= '0';
                    out_p_EN  <= '0';
                    if flag_zero = '1' then 
                        pc_mode <= PC_LOAD_NEW_VAL;
                    else
                        pc_mode <= PC_INCREMENT;
                    end if;

                
                when OP_BRR_V =>                      -- Branch relative if signed multiply overflow
                    mode_ALU  <= ALU_NOP;
                    src_ALU   <= '0';
                    wr_en_MEM <= '0';
                    wr_en_REG <= '0';
                    sel_WB    <= WB_ALU;
                    in_p_EN   <= '0';
                    out_p_EN  <= '0';
                    if flag_overflow = '1' then
                        pc_mode <= PC_LOAD_NEW_VAL;
                    else
                        pc_mode <= PC_INCREMENT;
                    end if;

                -- branch register
                when OP_BR =>                         -- Branch to register, unconditional: PC = Ra
                    mode_ALU  <= ALU_NOP;             -- no ALU computation; target is register value
                    src_ALU   <= '0';
                    wr_en_MEM <= '0';
                    wr_en_REG <= '0';
                    sel_WB    <= WB_ALU;
                    in_p_EN   <= '0';
                    out_p_EN  <= '0';
                    pc_mode <= PC_LOAD_NEW_VAL; 

                when OP_BR_N =>                       -- Branch to register if negative: PC = Ra if flag_neg
                    mode_ALU  <= ALU_NOP;
                    src_ALU   <= '0';
                    wr_en_MEM <= '0';
                    wr_en_REG <= '0';
                    sel_WB    <= WB_ALU;
                    in_p_EN   <= '0';
                    out_p_EN  <= '0';
                    if flag_neg = '1' then  -- branch only when negative flag set
                        pc_mode <= PC_LOAD_NEW_VAL;
                    else
                        pc_mode <= PC_INCREMENT;
                    end if;
                    
                when OP_BR_Z =>                       -- Branch to register if zero: PC = Ra if flag_zero
                    mode_ALU  <= ALU_NOP;
                    src_ALU   <= '0';
                    wr_en_MEM <= '0';
                    wr_en_REG <= '0';
                    sel_WB    <= WB_ALU;
                    in_p_EN   <= '0';
                    out_p_EN  <= '0';
                    if flag_zero = '1' then  -- branch only when zero flag set
                        pc_mode <= PC_LOAD_NEW_VAL;
                    else
                        pc_mode <= PC_INCREMENT;
                    end if;
                    
                when OP_BR_SUB =>                     -- Branch to subroutine: PC = Ra, save PC+2 to link reg
                    mode_ALU  <= ALU_NOP;
                    src_ALU   <= '0';
                    wr_en_MEM <= '0';
                    wr_en_REG <= '1';                 -- write return address (PC+2) to link register
                    sel_WB    <= WB_PC2;              -- select PC+2 as write-back value
                    in_p_EN   <= '0';
                    out_p_EN  <= '0';
                    pc_mode <= PC_LOAD_NEW_VAL;

                when OP_RETURN =>                     -- Return from subroutine: PC = Ra (we need r7?) (link register) 
                    mode_ALU  <= ALU_NOP;
                    src_ALU   <= '0';
                    wr_en_MEM <= '0';
                    wr_en_REG <= '0';
                    sel_WB    <= WB_ALU;
                    in_p_EN   <= '0';
                    out_p_EN  <= '0';
                    pc_mode <= PC_LOAD_NEW_VAL;

                when OP_LOAD =>
                    mode_ALU  <= ALU_ADD;
                    src_ALU   <= '1';
                    wr_en_MEM <= '0';
                    wr_en_REG <= '1';
                    sel_WB    <= WB_MEM;
                    in_p_EN   <= '0';
                    out_p_EN  <= '0';          
                    pc_mode   <= PC_INCREMENT;

                when OP_STORE =>
                    mode_ALU  <= ALU_ADD;
                    src_ALU   <= '1';
                    wr_en_MEM <= '1';
                    wr_en_REG <= '0';
                    sel_WB    <= WB_ALU;
                    in_p_EN   <= '0';
                    out_p_EN  <= '0';
                    pc_mode   <= PC_INCREMENT;

                when OP_LOADIMM =>
                        mode_ALU  <= ALU_NOP;
                        src_ALU   <= '0';
                        wr_en_MEM <= '0';
                        wr_en_REG <= '1';
                        sel_WB    <= WB_AUX;
                        in_p_EN   <= '0';
                        out_p_EN  <= '0';
                        pc_mode   <= PC_INCREMENT;

                when OP_MOV =>
                    mode_ALU  <= ALU_ADD;
                    src_ALU   <= '1';
                    wr_en_MEM <= '0';
                    wr_en_REG <= '1';
                    sel_WB    <= WB_ALU;
                    in_p_EN   <= '0';
                    out_p_EN  <= '0';
                    pc_mode   <= PC_INCREMENT;

                when others =>
                    mode_ALU  <= ALU_NOP;
                    src_ALU   <= '0';
                    wr_en_MEM <= '0';
                    wr_en_REG <= '0';
                    sel_WB    <= WB_ALU;
                    in_p_EN   <= '0';
                    out_p_EN  <= '0';
                    pc_mode <= PC_INCREMENT;
            end case;
        end if;      
    end process;
end behavioral;
