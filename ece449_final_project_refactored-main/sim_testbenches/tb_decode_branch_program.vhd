library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.constant_package.all;

entity tb_decode_branch_program is
end tb_decode_branch_program;

architecture sim of tb_decode_branch_program is
    constant CLK_PERIOD : time := 10 ns;

    signal clk           : std_logic := '0';
    signal reset         : std_logic := '0';
    signal instruction   : std_logic_vector(15 downto 0) := (others => '0');
    signal pc_plus2_in   : std_logic_vector(15 downto 0) := (others => '0');

    signal wb_wr_en      : std_logic := '0';
    signal wb_dest       : std_logic_vector(2 downto 0) := (others => '0');
    signal wb_data       : std_logic_vector(15 downto 0) := (others => '0');

    signal flag_zero     : std_logic := '0';
    signal flag_neg      : std_logic := '0';
    signal boot_mode     : std_logic := '0';

    signal rd_data1      : std_logic_vector(15 downto 0);
    signal rd_data2      : std_logic_vector(15 downto 0);
    signal imm           : std_logic_vector(15 downto 0);
    signal dest_reg      : std_logic_vector(2 downto 0);
    signal pc_plus2_out  : std_logic_vector(15 downto 0);
    signal alu_mode      : std_logic_vector(2 downto 0);
    signal alu_src       : std_logic;
    signal wr_en_MEM     : std_logic;
    signal wr_en_REG     : std_logic;
    signal sel_WB        : std_logic_vector(1 downto 0);
    signal in_p_EN       : std_logic;
    signal out_p_EN      : std_logic;
    signal pc_mode       : std_logic_vector(1 downto 0);
    signal pc_reset      : std_logic_vector(15 downto 0);
    signal branch_target : std_logic_vector(15 downto 0);
    signal branch_taken  : std_logic;

    function slv6(value : integer) return std_logic_vector is
    begin
        return std_logic_vector(to_signed(value, 6));
    end function;

    function slv9(value : integer) return std_logic_vector is
    begin
        return std_logic_vector(to_signed(value, 9));
    end function;

    constant INSTR_IN_R0       : std_logic_vector(15 downto 0) := OP_IN & "000" & "000000";
    constant INSTR_IN_R4       : std_logic_vector(15 downto 0) := OP_IN & "100" & "000000";
    constant INSTR_BR_SUB_R4_10: std_logic_vector(15 downto 0) := OP_BR_SUB & "100" & slv6(10);
    constant INSTR_BRR_0       : std_logic_vector(15 downto 0) := OP_BRR & slv9(0);
    constant INSTR_BRR_Z_2     : std_logic_vector(15 downto 0) := OP_BRR_Z & slv9(2);
    constant INSTR_BRR_NEG5    : std_logic_vector(15 downto 0) := OP_BRR & slv9(-5);
    constant INSTR_RETURN      : std_logic_vector(15 downto 0) := OP_RETURN & "000000000";
begin

    uut : entity work.decode
        port map(
            clk           => clk,
            reset         => reset,
            instruction   => instruction,
            pc_plus2_in   => pc_plus2_in,
            wb_wr_en      => wb_wr_en,
            wb_dest       => wb_dest,
            wb_data       => wb_data,
            flag_zero     => flag_zero,
            flag_neg      => flag_neg,
            boot_mode     => boot_mode,
            rd_data1      => rd_data1,
            rd_data2      => rd_data2,
            imm           => imm,
            dest_reg      => dest_reg,
            pc_plus2_out  => pc_plus2_out,
            alu_mode      => alu_mode,
            alu_src       => alu_src,
            wr_en_MEM     => wr_en_MEM,
            wr_en_REG     => wr_en_REG,
            sel_WB        => sel_WB,
            in_p_EN       => in_p_EN,
            out_p_EN      => out_p_EN,
            pc_mode       => pc_mode,
            pc_reset      => pc_reset,
            branch_target => branch_target,
            branch_taken  => branch_taken
        );

    clk_process : process
    begin
        while true loop
            clk <= '0';
            wait for CLK_PERIOD / 2;
            clk <= '1';
            wait for CLK_PERIOD / 2;
        end loop;
    end process;

    stim_proc : process
        procedure write_reg(
            constant addr : std_logic_vector(2 downto 0);
            constant data : std_logic_vector(15 downto 0)
        ) is
        begin
            wb_dest  <= addr;
            wb_data  <= data;
            wb_wr_en <= '1';
            wait until rising_edge(clk);
            wait for 1 ns;
            wb_wr_en <= '0';
            wait for 1 ns;
        end procedure;
    begin
        reset <= '1';
        wait for 2 * CLK_PERIOD;
        reset <= '0';

        -- Move the controller FSM from RESET_STATE into DECODE_STATE.
        wait until rising_edge(clk);
        wait for 1 ns;

        -- Preload register values used by the example branch program.
        write_reg("100", x"0210"); -- R4 = absolute subroutine address
        write_reg("101", x"0001"); -- R5 = constant 1
        write_reg("110", x"0005"); -- R6 = loop counter
        write_reg("111", x"0210"); -- R7 = sample return address

        -- IN R0
        instruction <= INSTR_IN_R0;
        pc_plus2_in <= x"0202";
        flag_zero   <= '0';
        flag_neg    <= '0';
        wait for 1 ns;

        assert dest_reg = "000"
            report "IN R0 should target R0"
            severity error;
        assert in_p_EN = '1'
            report "IN should enable input-port writeback"
            severity error;
        assert wr_en_REG = '1'
            report "IN should write the register file"
            severity error;

        -- IN R4
        instruction <= INSTR_IN_R4;
        wait for 1 ns;

        assert dest_reg = "100"
            report "IN R4 should target R4"
            severity error;

        -- BR.SUB R4,10
        instruction <= INSTR_BR_SUB_R4_10;
        pc_plus2_in <= x"0212";
        wait for 1 ns;

        assert rd_data1 = x"0210"
            report "BR.SUB should read the absolute target from R4"
            severity error;
        assert imm = x"000A"
            report "BR.SUB immediate should sign-extend 10"
            severity error;
        assert dest_reg = LINK_REGISTER
            report "BR.SUB should redirect writeback to the link register"
            severity error;
        assert branch_target = x"0210"
            report "BR.SUB should branch to the address stored in R4"
            severity error;
        assert branch_taken = '1'
            report "BR.SUB should always take the branch"
            severity error;
        assert pc_mode = PC_IM_VALUE
            report "BR.SUB should drive fetch into immediate-PC mode"
            severity error;
        assert sel_WB = WB_PC2
            report "BR.SUB should write PC+2 back to the link register"
            severity error;

        -- BRR 0
        instruction <= INSTR_BRR_0;
        pc_plus2_in <= x"0214";
        wait for 1 ns;

        assert imm = x"0000"
            report "BRR 0 should produce a zero displacement"
            severity error;
        assert branch_target = x"0214"
            report "BRR 0 should branch back to PC+2"
            severity error;
        assert branch_taken = '1'
            report "BRR should always take the branch"
            severity error;

        -- BRR.z 2 with zero flag asserted
        instruction <= INSTR_BRR_Z_2;
        pc_plus2_in <= x"021C";
        flag_zero   <= '1';
        wait for 1 ns;

        assert imm = x"0002"
            report "BRR.z 2 should sign-extend the positive displacement"
            severity error;
        assert branch_target = x"021E"
            report "BRR.z 2 should jump ahead by one instruction"
            severity error;
        assert branch_taken = '1'
            report "BRR.z should branch when zero flag is set"
            severity error;

        -- BRR -5
        instruction <= INSTR_BRR_NEG5;
        pc_plus2_in <= x"0220";
        flag_zero   <= '0';
        wait for 1 ns;

        assert imm = x"FFFB"
            report "BRR -5 should sign-extend the negative displacement"
            severity error;
        assert branch_target = x"021B"
            report "BRR -5 should compute the backward branch target"
            severity error;
        assert branch_taken = '1'
            report "BRR -5 should always take the branch"
            severity error;

        -- RETURN uses the link register.
        instruction <= INSTR_RETURN;
        wait for 1 ns;

        assert rd_data1 = x"0210"
            report "RETURN should read the link register"
            severity error;
        assert branch_target = x"0210"
            report "RETURN should branch to the link-register address"
            severity error;
        assert branch_taken = '1'
            report "RETURN should always take the branch"
            severity error;

        assert false
            report "tb_decode_branch_program completed successfully"
            severity note;
        wait;
    end process;

end sim;
