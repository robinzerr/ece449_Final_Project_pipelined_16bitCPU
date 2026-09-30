----------------------------------------------------------------------------------
-- University of Victoria
-- Engineer: Robin Zerr / Ava Birtwistle
-- 
-- Create Date: 03/28/2026 04:26:59 PM
-- Design Name: top_level_cpu
-- Module Name: top_level_cpu - Behavioral
-- Project Name: 16 Bit CPU
-- Target Devices: Artix-7 xc7a100tcsg324-1 
-- Tool Versions: Vivado 2025-2
-- Description: This file defines the top-level wiring for the complete 16-bit CPU.
-- It integrates the major datapath and control components required to support
-- Format A, Format B, and Format L instruction types within a Harvard architecture.
-- The design also includes hazard handling for signed overflow conditions.
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity top_level_cpu is
    port(
        clk: in std_logic;
        reset: in std_logic;
        boot_mode: in std_logic;
        in_port: in std_logic_vector(15 downto 0);
        out_port: out std_logic_vector(15 downto 0);
        debug_console : in STD_LOGIC;
        board_clock: in std_logic;

        vga_red : out std_logic_vector( 3 downto 0 );
        vga_green : out std_logic_vector( 3 downto 0 );
        vga_blue : out std_logic_vector( 3 downto 0 );
        h_sync_signal : out std_logic;
        v_sync_signal : out std_logic;
        led_segments : out STD_LOGIC_VECTOR( 6 downto 0 );
        led_digits : out STD_LOGIC_VECTOR( 3 downto 0 )  
        );
end top_level_cpu;
    
architecture Behavioral of top_level_cpu is
    -- pipeline register internal signals
    signal IF_ID_reg: IF_ID;
    signal ID_EX_reg: ID_EX;
    signal EX_MEM_reg : EX_MEM;
    signal MEM_WB_reg : MEM_WB; 
    
    -- fetch stage outputs
    signal fetch_instruction: std_logic_vector(15 downto 0);
    signal fetch_pc: std_logic_vector(15 downto 0);

    -- decode stage outputs
    signal decode_rd_data1  : std_logic_vector(15 downto 0);
    signal decode_rd_data2  : std_logic_vector(15 downto 0);
    signal decode_imm       : std_logic_vector(15 downto 0);
    signal decode_dest_reg  : std_logic_vector(2 downto 0);
    signal decode_pc_plus2  : std_logic_vector(15 downto 0);
    signal decode_alu_mode  : std_logic_vector(2 downto 0);
    signal decode_alu_src   : std_logic;
    signal decode_shift_amt : std_logic_vector(3 downto 0);
    signal decode_wr_en_MEM : std_logic;
    signal decode_wr_en_REG : std_logic;
    signal decode_sel_WB    : std_logic_vector(1 downto 0);
    signal decode_in_p_EN   : std_logic;
    signal decode_out_p_EN  : std_logic;
    signal decode_pc_mode   : std_logic_vector(1 downto 0);
    signal decode_pc_reset  : std_logic;
    signal decode_branch_target: std_logic_vector(15 downto 0); -- calculated in decode stage and used as input for the program counter
    signal decode_src1_reg  : std_logic_vector(2 downto 0); -- store what register was used as src1 data
    signal decode_src2_reg  : std_logic_vector(2 downto 0); -- store what register index was used as the src 2 data
    signal decode_src1_used : std_logic; -- denotes if we wrote src1 (RAW prevention)
    signal decode_src2_used : std_logic; -- denotes if we wrote src2 (RAW prevention)
    signal decode_src1_needed_in_decode : std_logic; -- denotes if src1 reg is needed in the decode stage (for hazard detection)
    -- exec signals
    signal exec_rd_data2   : std_logic_vector(15 downto 0);
    signal exec_dest_reg   : std_logic_vector(2 downto 0);
    signal exec_pc_plus2   : std_logic_vector(15 downto 0);
    signal exec_wr_en_MEM  : std_logic;
    signal exec_reg_write  : std_logic;
    signal exec_wb_src     : std_logic_vector(1 downto 0);
    signal exec_out_p_EN   : std_logic;
    signal exec_alu_result : std_logic_vector(15 downto 0);
    signal exec_flag_zero: std_logic;
    signal exec_flag_neg : std_logic;
    signal exec_flag_carry : std_logic;
    signal exec_flag_overflow : std_logic;
    
    -- mem signals 
    signal mem_alu_result : std_logic_vector(15 downto 0);
    signal mem_data       : std_logic_vector(15 downto 0);
    signal mem_dest_reg   : std_logic_vector(2 downto 0);
    signal mem_pc_plus2   : std_logic_vector(15 downto 0);
    signal mem_reg_write  : std_logic;
    signal mem_wb_src     : std_logic_vector(1 downto 0);
    
    -- later-stage inputs back into decode
    signal write_back_addr_rf  : std_logic_vector(2 downto 0);
    signal write_back_en_rf   : std_logic;
    signal write_back_data_rf  : std_logic_vector(15 downto 0);
    signal pc_mode_effective : std_logic_vector(1 downto 0);
    -- signals for hazards pc_mode stall is when stall needed
    signal stall_pipe       : std_logic; -- asserted when RAW detected
    signal if_id_en         : std_logic; -- when asserted freezes the IF/ID register
    signal id_ex_flush      : std_logic; -- inserts a bubble into ID/EX while older instructions drain
    signal fwd_a_sel        : std_logic_vector(1 downto 0); -- 00=id/ex, 01=ex/mem, 10=mem/wb
    signal fwd_b_sel        : std_logic_vector(1 downto 0); -- 00=id/ex, 01=ex/mem, 10=mem/wb
    signal ex_mem_forward_data : std_logic_vector(15 downto 0);

    -- signals for the instruction fetching logic
    signal use_ram_fetch : std_logic; -- denotes to use the instruction fetched from ram when asserted
    signal selected_instruction : std_logic_vector(15 downto 0); -- the instruction that is selected to be passed to the IF/ID pipeline register (from either rom or ram)
    signal ram_instruction: std_logic_vector(15 downto 0); -- instruction fetched from RAM, set by memory unit


-- debug signals
    signal reg0_dbg_internal: std_logic_vector(15 downto 0);
    signal reg1_dbg_internal: std_logic_vector(15 downto 0);
    signal reg2_dbg_internal: std_logic_vector(15 downto 0);
    signal reg3_dbg_internal: std_logic_vector(15 downto 0);
    signal reg4_dbg_internal: std_logic_vector(15 downto 0);
    signal reg5_dbg_internal: std_logic_vector(15 downto 0);
    signal reg6_dbg_internal: std_logic_vector(15 downto 0);     
    signal reg7_dbg_internal: std_logic_vector(15 downto 0);   
   
begin
    led_display_memory: entity work.led
        port map(
            addr_write => s2_memory_write_address,
            clk => clk,
            data_in => s2_memory_write_data,
            en_write => s2_memory_write_enable,
            
            board_clock => board_clock,
            led_segments => led_segments,
            led_digits => led_digits
        );


    u_console: entity work.console
    port map(
        ----
---- Stage 1 Fetch
----
  s1_pc => IF_ID_reg.pc_plus2,
   s1_inst => IF_ID_reg.instruction,

----
---- Stage 2 Decode
----

   s2_pc => decode_pc_plus2,
   s2_inst => x"0000",

  s2_reg_a => ID_EX_reg.dest_reg,
   s2_reg_b => ID_EX_reg.src1_reg,
   s2_reg_c => ID_EX_reg.src2_reg,

    s2_reg_a_data => x"0000",
   s2_reg_b_data => ID_EX_reg.rd_data1,
   s2_reg_c_data => ID_EX_reg.rd_data2,
  s2_immediate => ID_EX_reg.imm,

----
---- Stage 3 Execute
----

   s3_pc => EX_MEM_reg.pc_plus2,
   s3_inst => x"0000",

    s3_reg_a => EX_MEM_reg.dest_reg,
    s3_reg_b => "000",
    s3_reg_c => "000",

    s3_reg_a_data => x"0000",
   s3_reg_b_data => x"0000",
   s3_reg_c_data => x"0000",
    s3_immediate => x"0000",

    s3_r_wb => EX_MEM_reg.reg_write,
   s3_r_wb_data => EX_MEM_reg.alu_result,

   s3_br_wb => '0',
s3_br_wb_address => x"0000",

    s3_mr_wr => EX_MEM_reg.wr_en_MEM,
    s3_mr_wr_address => EX_MEM_reg.alu_result,
    s3_mr_wr_data => EX_MEM_reg.rd_data2,

   s3_mr_rd => '0',
    s3_mr_rd_address => x"0000",

----
---- Stage 4 Memory
----

   s4_pc => MEM_WB_reg.pc_plus2,
    s4_inst => x"0000",
    s4_reg_a => MEM_WB_reg.dest_reg,
    s4_r_wb => MEM_WB_reg.reg_write,
   s4_r_wb_data => write_back_data_rf,

----
---- CPU registers
----

   register_0 => reg0_dbg_internal,
    register_1 => reg1_dbg_internal,
   register_2 => reg2_dbg_internal,
    register_3 => reg3_dbg_internal,
    register_4 => reg4_dbg_internal,
   register_5 => reg5_dbg_internal,
   register_6 => reg6_dbg_internal,
    register_7 => reg7_dbg_internal,

    register_0_of => '0',
   register_1_of => '0',
    register_2_of => '0',
   register_3_of => '0',
   register_4_of => '0',
    register_5_of => '0',
    register_6_of => '0',
   register_7_of => '0',

----
---- CPU Flags
----
   zero_flag => '0',
   negative_flag => '0',
    overflow_flag => '0',

----
---- Debug screen enable
----
    debug => debug_console,

----
---- Text console display memory access signals ( clk is the processor clock )
----

  clk => '0',
  addr_write => x"0000",
   data_in => x"0000",
   en_write => '0',

----
---- Video related signals
----

   board_clock => board_clock,
   h_sync_signal => h_sync_signal,
   v_sync_signal => v_sync_signal,
   vga_red => vga_red,
    vga_green => vga_green,
   vga_blue => vga_blue
    );
        

    pc_mode_effective <= PC_STALL when stall_pipe = '1' else decode_pc_mode;
    use_ram_fetch <= '1' when fetch_pc(15 downto 10) = "000001" else '0';
    selected_instruction <= ram_instruction when use_ram_fetch = '1' else fetch_instruction;

    -- Stall only when decode needs a value before forwarding can supply it.
    process(ID_EX_reg, EX_MEM_reg, decode_src1_reg, decode_src2_reg, decode_src1_used,
            decode_src2_used, decode_src1_needed_in_decode)
        variable load_use_hazard : std_logic;
        variable decode_now_hazard : std_logic;
    begin
        load_use_hazard := '0';
        decode_now_hazard := '0';

        if ID_EX_reg.reg_write = '1' and ID_EX_reg.wb_src = WB_MEM then
            if (decode_src1_used = '1' and decode_src1_reg = ID_EX_reg.dest_reg) or
               (decode_src2_used = '1' and decode_src2_reg = ID_EX_reg.dest_reg) then
                load_use_hazard := '1';
            end if;
        end if;

        if decode_src1_needed_in_decode = '1' then
            if (ID_EX_reg.reg_write = '1' and decode_src1_reg = ID_EX_reg.dest_reg) or
               (EX_MEM_reg.reg_write = '1' and decode_src1_reg = EX_MEM_reg.dest_reg) then
                decode_now_hazard := '1';
            end if;
        end if;

        stall_pipe <= load_use_hazard or decode_now_hazard;
    end process;

    if_id_en    <= not stall_pipe;
    id_ex_flush <= stall_pipe;

    -- Execute-stage RAWs are resolved with forwarding instead of stalls.
    process(ID_EX_reg, EX_MEM_reg, MEM_WB_reg)
    begin
        fwd_a_sel <= "00";
        fwd_b_sel <= "00";

        if ID_EX_reg.src1_used = '1' and EX_MEM_reg.reg_write = '1' and
           EX_MEM_reg.wb_src /= WB_MEM and ID_EX_reg.src1_reg = EX_MEM_reg.dest_reg then
            fwd_a_sel <= "01";
        elsif ID_EX_reg.src1_used = '1' and MEM_WB_reg.reg_write = '1' and
              ID_EX_reg.src1_reg = MEM_WB_reg.dest_reg then
            fwd_a_sel <= "10";
        end if;

        if ID_EX_reg.src2_used = '1' and EX_MEM_reg.reg_write = '1' and
           EX_MEM_reg.wb_src /= WB_MEM and ID_EX_reg.src2_reg = EX_MEM_reg.dest_reg then
            fwd_b_sel <= "01";
        elsif ID_EX_reg.src2_used = '1' and MEM_WB_reg.reg_write = '1' and
              ID_EX_reg.src2_reg = MEM_WB_reg.dest_reg then
            fwd_b_sel <= "10";
        end if;
    end process;

    process(EX_MEM_reg)
    begin
        case EX_MEM_reg.wb_src is
            when WB_ALU =>
                ex_mem_forward_data <= EX_MEM_reg.alu_result;
            when WB_PC2 =>
                ex_mem_forward_data <= EX_MEM_reg.pc_plus2;
            when WB_AUX =>
                ex_mem_forward_data <= EX_MEM_reg.in_data;
            when others =>
                ex_mem_forward_data <= (others => '0');
        end case;
    end process;

    u_fetch: entity work.fetch
        port map(
            clk         => clk,
            reset       => reset,
            pc_reset    => decode_pc_reset,
            rom_ena     => if_id_en,
            mode        => pc_mode_effective,
            in_pc       => decode_branch_target,
            instruction => fetch_instruction,
            pc => fetch_pc
            );
        
    -- process for the IF_ID register
    IF_ID_proc: process(clk, reset)
    begin
        if rising_edge(clk) then -- if we need to reset or we have loaded a new value in the program counter
            if reset = '1' or pc_mode_effective = PC_LOAD_NEW_VAL then -- flush out the pipeline register
                IF_ID_reg.instruction <= (others => '0');
                IF_ID_reg.pc_plus2    <= (others => '0');
            elsif if_id_en = '1' then -- operate as normal
                IF_ID_reg.instruction <= selected_instruction; -- load the instruction from either the rom or the ram
                IF_ID_reg.pc_plus2    <= std_logic_vector(unsigned(fetch_pc)+2);            
            else -- hold the value in our register, this means there is a stall
                IF_ID_reg.instruction <= IF_ID_reg.instruction;
                IF_ID_reg.pc_plus2    <= IF_ID_reg.pc_plus2;
             end if;         
        end if;
    end process;

    
        -- component instantiation
    u_decode: entity work.decode
        port map(
            clk => clk,
            reset => reset,
            instruction  => IF_ID_reg.instruction,
            pc_plus2_in  => IF_ID_reg.pc_plus2,
            wb_wr_en  => write_back_en_rf,
            wb_dest   => write_back_addr_rf,
            wb_data   => write_back_data_rf,
            flag_zero   => exec_flag_zero, -- wired to exec flag output
            flag_neg    => exec_flag_neg,  -- wired to exec flag output
            flag_carry  => exec_flag_carry, -- wired to exec flag output
            flag_overflow => exec_flag_overflow, -- wired to exec flag output
            boot_mode   => boot_mode,   -- input from top level
            rd_data1   => decode_rd_data1, 
            rd_data2    => decode_rd_data2,
            imm         => decode_imm,
            dest_reg     => decode_dest_reg,
            pc_plus2_out => decode_pc_plus2,
            shift_amt  => decode_shift_amt,
            alu_mode     => decode_alu_mode,
            alu_src       => decode_alu_src,
            wr_en_MEM      => decode_wr_en_MEM,
            wr_en_REG      => decode_wr_en_REG,
            sel_WB         => decode_sel_WB,
            in_p_EN         => decode_in_p_EN,
            out_p_EN        => decode_out_p_EN, -- carried forward to memory for OUT / mapped output writes
            pc_mode         => decode_pc_mode,
            branch_target   => decode_branch_target,
            pc_reset        => decode_pc_reset,
            src1_reg        => decode_src1_reg,
            src2_reg        => decode_src2_reg,
            src1_used       => decode_src1_used,
            src2_used       => decode_src2_used,
            src1_needed_in_decode => decode_src1_needed_in_decode,
            --debug signals
            reg0_dbg => reg0_dbg_internal,
            reg1_dbg => reg1_dbg_internal,
            reg2_dbg => reg2_dbg_internal,
            reg3_dbg => reg3_dbg_internal,
            reg4_dbg => reg4_dbg_internal,
            reg5_dbg => reg5_dbg_internal,
            reg6_dbg => reg6_dbg_internal,
            reg7_dbg => reg7_dbg_internal
        );


    -- pipeline refister for the 
    -- ID/EX Register: latches decode/controller output into execute stage
    ID_EX_proc : process(clk, reset)
        begin
            if rising_edge(clk) then
                if (reset = '1') or (id_ex_flush = '1') then  
                    ID_EX_reg.rd_data1  <= (others => '0');
                    ID_EX_reg.rd_data2  <= (others => '0');
                    ID_EX_reg.imm       <= (others => '0');
                    ID_EX_reg.dest_reg  <= (others => '0');
                    ID_EX_reg.src1_reg  <= (others => '0');
                    ID_EX_reg.src2_reg  <= (others => '0');
                    ID_EX_reg.src1_used <= '0';
                    ID_EX_reg.src2_used <= '0';
                    ID_EX_reg.pc_plus2  <= (others => '0');
                    ID_EX_reg.alu_mode  <= ALU_NOP;
                    ID_EX_reg.alu_src   <= '0';
                    ID_EX_reg.wr_en_MEM <= '0';
                    ID_EX_reg.reg_write <= '0';
                    ID_EX_reg.wb_src    <= WB_ALU;
                    ID_EX_reg.out_p_EN <= '0';
                    ID_EX_reg.shift_amt <= (others => '0');  
                    ID_EX_reg.in_data  <= (others => '0');          
                else
                    ID_EX_reg.rd_data1  <= decode_rd_data1;
                    ID_EX_reg.rd_data2  <= decode_rd_data2;
                    ID_EX_reg.imm       <= decode_imm;
                    ID_EX_reg.dest_reg  <= decode_dest_reg;
                    ID_EX_reg.src1_reg  <= decode_src1_reg;
                    ID_EX_reg.src2_reg  <= decode_src2_reg;
                    ID_EX_reg.src1_used <= decode_src1_used;
                    ID_EX_reg.src2_used <= decode_src2_used;
                    ID_EX_reg.pc_plus2  <= decode_pc_plus2;
                    ID_EX_reg.alu_mode  <= decode_alu_mode;
                    ID_EX_reg.alu_src   <= decode_alu_src;
                    ID_EX_reg.wr_en_MEM <= decode_wr_en_MEM;
                    ID_EX_reg.reg_write <= decode_wr_en_REG;
                    ID_EX_reg.wb_src    <= decode_sel_WB;
                    ID_EX_reg.out_p_EN <= decode_out_p_EN;
                    ID_EX_reg.shift_amt <= decode_shift_amt;  
                    if decode_in_p_EN = '1' then -- if decode indicates we want to use data on input port
                        ID_EX_reg.in_data <= (15 downto 1 => '0') & in_port(14 downto 0); -- then the input data should be the source
                    elsif decode_sel_WB = WB_AUX then  -- otherwise it is immediate value
                        ID_EX_reg.in_data <= decode_imm; -- load immediate value produced in decode
                    else
                        ID_EX_reg.in_data <= (others => '0'); -- if we arent using either, set to 0
                    end if;                    
                end if;
            end if;
    end process;
    
    u_execute : entity work.execute
    port map(
        rd_data1      => ID_EX_reg.rd_data1,
        rd_data2      => ID_EX_reg.rd_data2,
        imm           => ID_EX_reg.imm,
        ex_mem_value  => ex_mem_forward_data,
        mem_wb_value  => write_back_data_rf,
        fwd_a_sel     => fwd_a_sel,
        fwd_b_sel     => fwd_b_sel,        
        dest_reg      => ID_EX_reg.dest_reg,
        pc_plus2      => ID_EX_reg.pc_plus2,

        alu_mode      => ID_EX_reg.alu_mode,
        alu_src       => ID_EX_reg.alu_src,
        wr_en_MEM     => ID_EX_reg.wr_en_MEM,
        reg_write     => ID_EX_reg.reg_write,
        wb_src        => ID_EX_reg.wb_src,
        out_p_EN      => ID_EX_reg.out_p_EN,
        shift_amount      => ID_EX_reg.shift_amt,
        alu_result        => exec_alu_result,
        rd_data2_out      => exec_rd_data2,
        dest_reg_out      => exec_dest_reg,
        pc_plus2_out      => exec_pc_plus2,
        wr_en_MEM_out     => exec_wr_en_MEM,
        reg_write_out     => exec_reg_write,
        wb_src_out        => exec_wb_src,
        out_p_EN_out      => exec_out_p_EN,
        flag_zero_out     => exec_flag_zero,
        flag_negative_out => exec_flag_neg,
        flag_carry_out    => exec_flag_carry,
        flag_overflow_out => exec_flag_overflow    
    );
    
    
   -- EX/MEM Register: latches execute output into memory stage
    EX_MEM_proc : process(clk, reset)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                EX_MEM_reg.alu_result <= (others => '0');
                EX_MEM_reg.rd_data2   <= (others => '0');
                EX_MEM_reg.dest_reg   <= (others => '0');
                EX_MEM_reg.pc_plus2   <= (others => '0');
                EX_MEM_reg.wr_en_MEM  <= '0';
                EX_MEM_reg.reg_write  <= '0';
                EX_MEM_reg.wb_src     <= WB_ALU;
                EX_MEM_reg.out_p_EN   <= '0';
                EX_MEM_reg.in_data    <= (others => '0');
            else
                EX_MEM_reg.alu_result <= exec_alu_result;
                EX_MEM_reg.rd_data2   <= exec_rd_data2;
                EX_MEM_reg.dest_reg   <= exec_dest_reg;
                EX_MEM_reg.pc_plus2   <= exec_pc_plus2;
                EX_MEM_reg.wr_en_MEM  <= exec_wr_en_MEM;
                EX_MEM_reg.reg_write  <= exec_reg_write;
                EX_MEM_reg.wb_src     <= exec_wb_src;
                EX_MEM_reg.out_p_EN   <= exec_out_p_EN;
                EX_MEM_reg.in_data    <= ID_EX_reg.in_data;
            end if;
         end if;
    end process;
    
    -- MEMORY COMPONENT INSTANTIATION
    u_memory : entity work.memory
        port map(
        clk         => clk,
        rst         => reset,
        alu_result  => EX_MEM_reg.alu_result,
        rd_data2    => EX_MEM_reg.rd_data2,
        dest_reg    => EX_MEM_reg.dest_reg,
        pc_plus2    => EX_MEM_reg.pc_plus2,
        wr_en_MEM   => EX_MEM_reg.wr_en_MEM,
        reg_write   => EX_MEM_reg.reg_write,
        wb_src      => EX_MEM_reg.wb_src,
        out_p_EN    => EX_MEM_reg.out_p_EN,
        alu_result_out  => mem_alu_result,
        mem_data_out    => mem_data,
        dest_reg_out    => mem_dest_reg,
        pc_plus2_out    => mem_pc_plus2,
        reg_write_out   => mem_reg_write,
        wb_src_out      => mem_wb_src,
        out_port        => out_port, -- this is the part when we output to the ports
        instr_fetch_en   => use_ram_fetch,
        instr_fetch_addr => fetch_pc,
        instr_fetch_data => ram_instruction
        );
    
    -- MEM/WB pipeline register
    MEM_WB_proc : process(clk, reset)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                MEM_WB_reg.alu_result <= (others => '0');
                MEM_WB_reg.mem_data   <= (others => '0');
                MEM_WB_reg.dest_reg   <= (others => '0');
                MEM_WB_reg.pc_plus2   <= (others => '0');
                MEM_WB_reg.reg_write  <= '0';
                MEM_WB_reg.wb_src     <= WB_ALU;
                MEM_WB_reg.in_data    <= (others => '0');
            else
                MEM_WB_reg.alu_result <= mem_alu_result;
                MEM_WB_reg.mem_data   <= mem_data;
                MEM_WB_reg.dest_reg   <= mem_dest_reg;
                MEM_WB_reg.pc_plus2   <= mem_pc_plus2;
                MEM_WB_reg.reg_write  <= mem_reg_write;
                MEM_WB_reg.wb_src     <= mem_wb_src;
                MEM_WB_reg.in_data    <= EX_MEM_reg.in_data;
            end if;
        end if;
    end process;
    
    -- WRITEBACK COMPONENT INSTANTIATION
    u_writeback : entity work.writeback
        port map (
            alu_result   => MEM_WB_reg.alu_result,
            mem_data     => MEM_WB_reg.mem_data,
            dest_reg     => MEM_WB_reg.dest_reg,
            pc_plus2     => MEM_WB_reg.pc_plus2,
            reg_write    => MEM_WB_reg.reg_write,
            wb_src       => MEM_WB_reg.wb_src,
            in_data      => MEM_WB_reg.in_data,
            wb_data      => write_back_data_rf,
            wb_dest_reg  => write_back_addr_rf,
            wb_reg_write => write_back_en_rf
        );
end Behavioral;
