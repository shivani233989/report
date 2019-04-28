library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity framebuffer is
port (
    clk      : in std_logic ;                               -- Clock
    rst      : in std_logic ;                               -- Reset
    en1      : in std_logic ;                               -- Enable for port 1
    en2      : in std_logic ;                               -- Enable for port 2
    ld       : in std_logic ;                               -- Load 
    addr1    : in std_logic_vector (11 downto 0) ;          -- Address for port 1
    addr2    : in std_logic_vector (11 downto 0) ;          -- Address for port 2
    wr_en1   : in std_logic ;                               -- Write enable port 1 
    din1     : in std_logic_vector (15 downto 0) ;          -- Write data port 1
    dout1    : out std_logic_vector (15 downto 0) ;         -- Read data port 1
    dout2    : out std_logic_vector (15 downto 0)           -- Read data port 2
) ;
end framebuffer ;

architecture rtl of framebuffer is

  type frmbfr_mem is array (4095 downto 0) of std_logic_vector (15 downto 0) ;
  signal frmbfr         : frmbfr_mem := (others => (others => '0')) ;

  signal d_s         : std_ulogic ;
  signal q_s         : std_ulogic := '0' ;
  signal count          : std_logic_vector (11 downto 0) := (others => '0') ;
  signal count_s        : std_logic_vector (11 downto 0) ;

  signal wr_en1_s       : std_ulogic ; 
  signal en1_s          : std_ulogic ; 
  signal addr1_s        : std_logic_vector (11 downto 0) ;
  signal din1_s         : std_logic_vector (15 downto 0) ; 

  signal cntr_ovrflw_s  : std_ulogic ; 

begin
    
  -- Write Logic
  mem_write : process (clk)
  begin
      if (rising_edge(clk))  then
          if (en1_s = '1') then  
              if (wr_en1_s = '1') then
                frmbfr(conv_integer(addr1_s)) <= din1_s;
              end if;
          end if;
      end if;
  end process  mem_write ;

  -- Read Logic
  dout1 <= frmbfr(conv_integer(addr1)) when (ld and en1 and not rst) = '1' else (others => '0') ;
  dout2 <= frmbfr(conv_integer(addr2)) when (ld and en2 and not rst) = '1' else (others => '0') ;
  
  --Reset Logic
  cntr_ovrflw_s <= '1' when unsigned(count) = 4095 else '0';
  d_s  <= (rst or q_s) and not cntr_ovrflw_s ; 
  count_s <= count + '1' when q_s = '1' else (others => '0') ;

  reset : process (clk)
  begin
      if (clk = '1' and clk'event)  then
          q_s <= d_s  ;
          count  <= count_s ;
      end if;
  end process reset;

  -- Write Enable Address and Data for reset 
  wr_en1_s <= q_s or wr_en1; 
  en1_s    <= q_s or en1; 
  addr1_s  <= count when q_s = '1' else addr1;
  din1_s   <= (others => '0') when q_s = '1' else din1;

end rtl;
