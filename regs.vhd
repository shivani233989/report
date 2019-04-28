library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all; 

entity regs is port (
    clk                : in  std_logic ;
    en                 : in  std_logic ;
    rst                : in  std_logic ;
    id1                : in  std_logic_vector (4 downto 0) ; -- Addresses
    id2                : in  std_logic_vector (4 downto 0) ; -- Addresses
    wr_en1             : in  std_logic ;
    wr_en2             : in  std_logic ;
    din1               : in  std_logic_vector (15 downto 0) ;
    din2               : in  std_logic_vector (15 downto 0) ;
    dout1              : out std_logic_vector (15 downto 0) ;
    dout2              : out std_logic_vector (15 downto 0) 
) ;
end regs ;

architecture rtl of regs is

  type registers_mem is array (31 downto 0) of std_logic_vector (15 downto 0);
  signal registers : registers_mem := (others => (others => '0'));
 
begin
  -- Write Logic
  mem_write : process (clk,rst)
  begin
    registers(conv_integer(0)) <= "0000000000000000";
      if(rst = '1') then
        for i in 0 to 31 loop
		    registers(conv_integer(i)) <= "0000000000000000";
        end loop;		
	  elsif (rising_edge(clk))  then
         if (en = '1') then  
             if (wr_en1 = '1') then
               registers(conv_integer(id1)) <= din1;
             end if;
             if (wr_en2 = '1') then
               registers(conv_integer(id2)) <= din2;
             end if;
         end if;
      end if;
  end process  mem_write ;

  -- Read Logic
  dout1 <= registers(conv_integer(id1)) when (en and not rst) = '1' else (others => '0') ;
  dout2 <= registers(conv_integer(id2)) when (en and not rst) = '1' else (others => '0') ;

end rtl;
