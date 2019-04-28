library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;

entity my_alu is
port(clk, clk_en: std_logic;
A, B: in  std_logic_vector(15 downto 0);  -- 2 inputs 16-bit
ALU_sel: in std_logic_vector(3 downto 0);  -- 1 input 4-bit for selecting operation
ALU_out: out std_logic_vector(15 downto 0)); -- 1 output 16-bit 
end my_alu; 

architecture behavioral of my_alu is

begin
process(clk)
begin
 if (rising_edge(clk)) then
    if (clk_en = '1') then
       case (ALU_sel) is
          when "0000" => 
          ALU_out <= std_logic_vector(unsigned(A) + unsigned(B)); -- addition
          when "0001" => 
          ALU_out <= std_logic_vector(unsigned(A) - unsigned(B)); -- subtraction
          when "0010" => 
          ALU_out <= std_logic_vector(unsigned(A) + 1); -- A + 1
          when "0011" => 
          ALU_out <= std_logic_vector(unsigned(A) - 1); -- A - 1
          when "0100" => 
          ALU_out <= std_logic_vector(0 - unsigned(A)); -- 0 - A
          when "0101" => 
          ALU_out <= A(14 downto 0) & '0'; -- shift left logical
          when "0110" => 
          ALU_out <= '0' & A(15 downto 1); -- shift right logical
          when "0111" => 
          ALU_out <= A(15) & A(15 downto 1); -- shift right arithmetic
          when "1000" =>   
          ALU_out <= A AND B; -- logical and
          when "1001" => 
          ALU_out <= A OR B; -- logical or
          when "1010" => 
          ALU_out <= A XOR B; -- logical xor
          when "1011" => if(signed(A) < signed(B)) then   -- A < B (signed)
          ALU_out <= "0000000000000000"; 
          else
          ALU_out <= "0000000000000001";  
          end if;
          when "1100" => if(signed(A) > signed(B)) then   -- A > B (signed)
          ALU_out <= "0000000000000000"; 
          else
          ALU_out <= "0000000000000001";  
          end if;
          when "1101" => if(unsigned(A) = unsigned(B)) then   -- A = B 
          ALU_out <= "0000000000000000"; 
          else
          ALU_out <= "0000000000000001";  
          end if;
          when "1110" => if(unsigned(A) < unsigned(B)) then   -- A < B 
          ALU_out <= "0000000000000000"; 
          else
          ALU_out <= "0000000000000001";  
          end if;
          when "1111" => if(unsigned(A) > unsigned(B)) then   -- A > B 
          ALU_out <= "0000000000000000"; 
          else
          ALU_out <= "0000000000000001";  
          end if; 
          when others => ALU_out <= (others => '0');
        end case;
     end if;
   end if;
end process;
end behavioral;
