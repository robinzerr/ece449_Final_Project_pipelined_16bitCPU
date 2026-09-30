----------------------------------------------------------------------------------
-- University of Victoria 
-- Engineer: Robin Zerr / Ava Birtwistle
--
-- Create Date: 02/02/2026 04:35:50 PM
-- Design Name:
-- Module Name: Alu -
-- Project Name: 16 Bit CPU
-- Target Devices: Artix-7 xc7a100tcsg324-1 
-- Tool Versions: Vivado 2025-2
-- Description: This file implements the 16-bit arithmetic logic unit used by the
-- CPU execute stage. It performs arithmetic, logical, shift, and test operations
-- and generates the carry, zero, negative, and overflow status flags.
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

entity Alu is
    port(
        shift_amount: in  std_logic_vector(3 downto 0);
        a           : in  std_logic_vector(15 downto 0); -- first operand for ALU operations
        b           : in  std_logic_vector(15 downto 0); -- second operand for ALU operations
        result      : out std_logic_vector(15 downto 0); -- output of the ALU operation
        control_sel : in  std_logic_vector(2 downto 0); -- selects the ALU operation
        Carry       : out std_logic; -- carry flag for addition and subtraction
        Zero        : out std_logic; -- zero flag for result of ALU operation
        Negative    : out std_logic; -- negative flag for result of ALU operation
        Overflow    : out std_logic -- overflow flag for addition and subtraction
    );
end Alu;

architecture behavioural of Alu is
begin

    process(a, b, control_sel)
        variable temp_result  : std_logic_vector(15 downto 0);
        variable temp_signed  : signed(15 downto 0);
        variable mult_result  : signed(31 downto 0);
        variable add_ext      : unsigned(16 downto 0); 
        variable sub_ext      : unsigned(16 downto 0);
    begin
        -- defaults
        temp_result := (others => '0');
        Carry       <= '0';
        Overflow    <= '0';
        Zero        <= '0';
        Negative    <= '0';

        case control_sel is -- determines which operation to perform

            -- NOP
            when "000" =>
                temp_result := (others => '0');
                Carry       <= '0';

            -- R[ra] <- R[rb] + R[rc]
            when "001" =>
                add_ext := ('0' & unsigned(a)) + ('0' & unsigned(b));
                temp_result := std_logic_vector(add_ext(15 downto 0));
                Carry <= add_ext(16);

            -- R[ra] <- R[rb] - R[rc]
            when "010" =>
                sub_ext := ('0' & unsigned(a)) - ('0' & unsigned(b));
                temp_result := std_logic_vector(sub_ext(15 downto 0));
                Carry <= sub_ext(16);

            -- R[ra] <- R[rb] x R[rc]
            when "011" =>
                mult_result := signed(a) * signed(b);
                temp_result := std_logic_vector(mult_result(15 downto 0));
                Carry <= '0';
                if mult_result > to_signed(32767, 32) or mult_result < to_signed(-32768, 32) then --  checks if the result exceeds the range of a 16-bit signed integer
                    Overflow <= '1';
                else
                    Overflow <= '0';
                end if;

    
            -- R[ra] <- R[ra] NAND R[rb]
            when "100" =>
                temp_result := not (a and b);
                Carry <= '0';

            -- shift left A by n = low 4 bits of B
            when "101" =>
                if to_integer(unsigned(shift_amount)) = 0 then
                    temp_result := a;
                else
                    temp_result := std_logic_vector(shift_left(unsigned(a), to_integer(unsigned(shift_amount))));
                end if;
                Carry <= '0';

            -- logical shift right A by n = low 4 bits of B
            when "110" =>
                if to_integer(unsigned(shift_amount)) = 0 then
                    temp_result := a;
                else
                    temp_result := std_logic_vector(shift_right(unsigned(a), to_integer(unsigned(shift_amount))));
                end if;
                Carry <= '0';

            -- 111 = TEST
            -- sets flags from A, result unused
            when "111" =>
                temp_result := (others => '0');
                Carry <= '0';

            when others =>
                temp_result := (others => '0');
                Carry <= '0';

        end case;

        result <= temp_result;

        -- Flags
        if control_sel = "111" then
            -- TEST checks A directly
            if a = x"0000" then
                Zero <= '1';
            else
                Zero <= '0';
            end if;

            if signed(a) < 0 then
                Negative <= '1';
            else
                Negative <= '0';
            end if;
        else
            if temp_result = x"0000" then
                Zero <= '1';
            else
                Zero <= '0';
            end if;

            temp_signed := signed(temp_result);
            if temp_signed < 0 then
                Negative <= '1';
            else
                Negative <= '0';
            end if;
        end if;

    end process;

end behavioural;
