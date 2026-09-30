library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_decode is
end tb_decode;

architecture sim of tb_decode is
        signal clk           : std_logic;
        signal reset         : std_logic;

        -- from IF/ID
        signal instruction   : std_logic_vector(15 downto 0);
        signal pc_plus2_in   : std_logic_vector(15 downto 0);

        -- from WB stage
        signal wb_wr_en      : std_logic;
        signal wb_dest       : std_logic_vector(2 downto 0);
        signal wb_data       : std_logic_vector(15 downto 0);

        -- flags / mode into controller
        signal flag_zero     : std_logic;
        signal flag_neg      : std_logic;
        signal boot_mode     : std_logic;

        -- outputs to ID/EX
        signal rd_data1      : std_logic_vector(15 downto 0);
        signal rd_data2      : std_logic_vector(15 downto 0);
        signal imm           : std_logic_vector(15 downto 0);
        signal dest_reg      : std_logic_vector(2 downto 0);
        signal pc_plus2_out  :  std_logic_vector(15 downto 0);
        signal shift_amt :  std_logic_vector(3 downto 0); 

        -- control outputs toward ID/EX
        signal alu_mode      :  std_logic_vector(2 downto 0);
        signal alu_src       :  std_logic;
        signal wr_en_MEM     :  std_logic;
        signal wr_en_REG     :  std_logic;
        signal sel_WB        :  std_logic_vector(1 downto 0);
        signal in_p_EN       :  std_logic;
        signal out_p_EN      :  std_logic;

        -- controls toward fetch
        signal pc_mode       :  std_logic_vector(1 downto 0);
        signal branch_target :  std_logic_vector(15 downto 0);
        signal pc_reset:  std_logic;

begin

    uut : entity work.decode
        port map(
            clk          => clk,
            reset        => reset,
            instruction     => instruction,
            pc_plus2_in  => pc_plus2_in,
            wb_wr_en     => wb_wr_en,
            wb_dest      => wb_dest,
            wb_data      => wb_data,
            flag_zero => flag_zero,
            flag_neg => flag_neg,
            boot_mode      => boot_mode,
            rd_data1 => rd_data1,
            rd_data2 => rd_data2,
            imm => imm,
            dest_reg=>dest_reg,
            pc_plus2_out=>pc_plus2_out,
            shift_amt => shift_amt,
            alu_mode => alu_mode,
            alu_src => alu_src,
            wr_en_MEM => wr_en_MEM,
            wr_en_REG => wr_en_REG,
            sel_WB => sel_WB,
            in_p_EN => in_p_EN,
            out_p_EN => out_p_EN,
            pc_mode => pc_mode,
            branch_target => branch_target,
            pc_reset => pc_reset
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
        wait for 5 ns;
        pc_plus2_in <= x"0002";
        flag_neg <= '0';
        flag_zero <= '0';
        boot_mode <= '0';
        wb_wr_en <= '1';
        wb_dest <= "000";
        wb_data <= x"0001";
        reset <= '1';
        wait for 10 ns;
        reset <= '0';
        wait for 10 ns;
        
        wb_wr_en <= '1';
        wb_dest <= "001";
        wb_data <= x"0002";
        wait for 10 ns;
        
        wb_wr_en <= '1';
        wb_dest <= "010";
        wb_data <= x"0004";
        wait for 10 ns;
        
        wb_wr_en <= '1';
        wb_dest <= "100";
        wb_data <= x"8004";
        
        wait for 10 ns;
        -- add 0000001 000 010 001
        instruction <= "0000001000010001";
        wait for 10 ns;
        
        -- add plus reset and load 
        instruction <= "0000001000010010";
        reset <= '1';
        boot_mode <= '0';
        wait for 10 ns;
        reset <= '0';
        -- subtract
        instruction <= "0000010000110011";
        wait for 10 ns;
        
        -- MUL
        instruction <= "0000011000100001";
        wait for 10 ns;
        
        -- NAND
        instruction <= "0000100000110101";
        wait for 10 ns;
        
        -- shift left
        instruction <= "0000101000000001";
         wait for 10 ns;
        
        -- shift right
        instruction <= "0000101010000001";
        wait for 10 ns;
        
        -- TEST negative
        instruction <= "0000111100000000";
        wait for 10 ns;
        
        -- TEST 0
        instruction <= "0000111111000000";
        wait for 10 ns;
                
        -- in 
        instruction <= "0100001011000000";
        wait for 10 ns;
        
        -- out
        instruction <= "0100000001000000";
        wait for 10 ns;
        
        -- Branch Negative
        -- when flag negative is asserted
        instruction <= "1000001001001000";
        flag_neg <= '1';
        wait for 10 ns;
        
        -- when flag negative is not asserted
        instruction <= "1000001000011000";
        flag_neg <= '0';
        wait for 5 ns;
        
        
            -- Branch zero
        -- when flag zero is asserted
        instruction <= "1000010000000010";
        flag_zero <= '1';
        wait for 5 ns;
        
        -- when flag zero is not asserted
        instruction <= "1000010000000110";
        flag_zero <= '0';
        wait for 5 ns;

        wait;
    end process;

end sim;
