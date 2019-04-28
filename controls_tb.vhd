library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;

entity controls_tb is
end controls_tb;

architecture test of controls_tb is

   component controls
   port (
   -- Timing Signals
   clk       : in  std_logic ;
   en        : in  std_logic ;
   rst       : in  std_logic ;
   -- Register File IO
     -- Address
   rID1      : out std_logic_vector (4 downto 0) ;
   rID2      : out std_logic_vector (4 downto 0) ;
     -- Write enable
   wr_enR1   : out std_logic ;
   wr_enR2   : out std_logic ;
     -- Read Data 
   regrD1    : in  std_logic_vector (15 downto 0) ;
   regrD2    : in  std_logic_vector (15 downto 0) ;
     -- Write Data
   regwD1    : out std_logic_vector (15 downto 0) ;
   regwD2    : out std_logic_vector (15 downto 0) ;
   -- Framebuffer IO
   fbRST     : out std_logic ;
   fbLd      : out std_logic ;
   fbAddr1   : out std_logic_vector (11 downto 0) ;
   fbDin1    : in  std_logic_vector (15 downto 0) ;
   fbDout1   : out std_logic_vector (15 downto 0) ;
   -- Instruction Memory IO
   irAddr    : out std_logic_vector (13 downto 0) ;
   irWord    : in  std_logic_vector (31 downto 0) ;
   -- Data Memory IO
   dAddr     : out std_logic_vector (14 downto 0) ;
   d_wr_en   : out std_logic ;
   dOut      : out std_logic_vector (15 downto 0) ;
   dIn       : in  std_logic_vector (15 downto 0) ;
   -- ALU IO
   aluA      : out std_logic_vector (15 downto 0) ;
   aluB      : out std_logic_vector (15 downto 0) ;
   aluOp     : out std_logic_vector (3 downto 0) ;
   aluResult : in  std_logic_vector (15 downto 0) ;
   -- UART IO
   ready     : in  std_logic ;
   newChar   : in  std_logic ;
   send      : out std_logic ;
   charRec   : in  std_logic_vector (7 downto 0) ;
   charSend  : out std_logic_vector (7 downto 0)
   ) ;
   end component ;

   component regs 
   port (
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
   end component;

   component framebuffer 
   port (
    clk      : in std_logic ;                               -- Input clock
    rst      : in std_logic ;                               -- Input clock
    en1      : in std_logic ;                               -- Enable for port 1
    en2      : in std_logic ;                               -- Enable for port 2
    ld       : in std_logic ;                               -- load the reset value
    addr1    : in std_logic_vector (11 downto 0) ;          -- Address for port 1
    addr2    : in std_logic_vector (11 downto 0) ;          -- Address for port 2
    wr_en1   : in std_logic ;                               -- Write enable port 1 
    din1     : in std_logic_vector (15 downto 0) ;          -- Write data port 1
    dout1    : out std_logic_vector (15 downto 0) ;         -- Read data port 1
    dout2    : out std_logic_vector (15 downto 0)           -- Read data port 2
   ) ;
   end component;

   component uart
   port (
       clk, en, send, rx, rst      : in std_logic;
       charSend                    : in std_logic_vector (7 downto 0);
       ready, tx, newChar          : out std_logic;
       charRec                     : out std_logic_vector (7 downto 0)
   );
   end component;

   component my_alu
   port(
        clk, clk_en: in std_logic;
        A, B: in  std_logic_vector(15 downto 0);  -- 2 inputs 16-bit
        ALU_sel: in std_logic_vector(3 downto 0);  -- 1 input 4-bit for selecting operation
        ALU_out: out std_logic_vector(15 downto 0) -- 1 output 16-bit 
    );
   end component; 

   component data_ram 
   port (
    clk       : in  std_logic ;
    rst       : in  std_logic ;
    d_wr_en   : in  std_ulogic                     ;
    dAddr     : in  std_logic_vector(14 downto 0)  ;
    dOut      : out std_logic_vector(15 downto 0)  ;
    dIn       : in  std_logic_vector(15 downto 0)  
   );
   end component;
   
 signal   tx_out    : std_ulogic                     := '0'; 
 signal   rx_in     : std_ulogic                     := '0'; 
 signal   clk       : std_ulogic                     := '0'; 
 signal   en        : std_ulogic                     := '0'; 
 signal   finished  : std_ulogic                     := '0'; 
 signal   rst       : std_ulogic                     := '0'; 
 signal   wr_enR1   : std_ulogic                     := '0'; 
 signal   wr_enR2   : std_ulogic                     := '0'; 
 signal   fbRST     : std_ulogic                     := '0';
 signal   fbLd      : std_ulogic                     := '0';
 signal   d_wr_en   : std_ulogic                     := '0';
 signal   ready     : std_ulogic                     := '0'; 
 signal   newChar   : std_ulogic                     := '0'; 
 signal   send      : std_ulogic                     := '0'; 
 signal   rID1      : std_logic_vector (4  downto 0) := (others => '0') ;
 signal   rID2      : std_logic_vector (4  downto 0) := (others => '0') ;
 signal   regrD1    : std_logic_vector(15 downto 0)  := (others => '0') ;
 signal   regrD2    : std_logic_vector(15 downto 0)  := (others => '0') ;
 signal   regwD1    : std_logic_vector(15 downto 0)  := (others => '0') ;
 signal   regwD2    : std_logic_vector(15 downto 0)  := (others => '0') ;
 signal   fbAddr1   : std_logic_vector(11 downto 0)  := (others => '0') ;
 signal   fbDin1    : std_logic_vector(15 downto 0)  := (others => '0') ;
 signal   fbDout1   : std_logic_vector(15 downto 0)  := (others => '0') ;
 signal   irAddr    : std_logic_vector(13 downto 0)  := (others => '0') ;
 signal   irWord    : std_logic_vector(31 downto 0)  := (others => '0') ;
 signal   dAddr     : std_logic_vector(14 downto 0)  := (others => '0') ;
 signal   dOut      : std_logic_vector(15 downto 0)  := (others => '0') ;
 signal   dIn       : std_logic_vector(15 downto 0)  := (others => '0') ;
 signal   aluA      : std_logic_vector(15 downto 0)  := (others => '0') ;
 signal   aluB      : std_logic_vector(15 downto 0)  := (others => '0') ;
 signal   aluOp     : std_logic_vector(3  downto 0)  := (others => '0') ;
 signal   aluResult : std_logic_vector(15 downto 0)  := (others => '0') ;
 signal   charRec   : std_logic_vector(7  downto 0)  := (others => '0') ;
 signal   charSend  : std_logic_vector(7  downto 0)  := (others => '0') ;

 -- Instruction memory
 type inst_memory is array (16383 downto 0) of std_logic_vector (31 downto 0) ;
 signal inst_mem : inst_memory := (others => (others => '0')) ;

 -- Frame buffer instance
 signal   ld        : std_ulogic := '0'; 
 signal   addr2     : std_logic_vector(11  downto 0) := (others => '0') ; 
 signal   en2       : std_ulogic := '0'; 

 -- [15:0] aluResult_org ;
 signal   aluResult_org : std_logic_vector(15 downto 0) := (others => '0') ;

 -- Data memory
 type data_memory is array (32767 downto 0) of std_logic_vector (15 downto 0) ;
 signal data_mem : data_memory := (others => (others => '0')) ;

 signal shift_bit : bit := '1';

 signal data                : std_logic_vector (15 downto 0) := (others => '0');

begin

--control fsm    
control_inst : controls port map (
   clk       => clk      , 
   en        => en       , 
   rst       => rst      , 
   rID1      => rID1     , 
   rID2      => rID2     , 
   wr_enR1   => wr_enR1  , 
   wr_enR2   => wr_enR2  , 
   regrD1    => regrD1   , 
   regrD2    => regrD2   , 
   regwD1    => regwD1   , 
   regwD2    => regwD2   , 
   fbRST     => fbRST    , 
   fbLd      => fbLd     , 
   fbAddr1   => fbAddr1  , 
   fbDin1    => fbDin1   , 
   fbDout1   => fbDout1  , 
   irAddr    => irAddr   , 
   irWord    => irWord   , 
   dAddr     => dAddr    , 
   d_wr_en   => d_wr_en  , 
   dOut      => dOut     , 
   dIn       => dIn      , 
   aluA      => aluA     , 
   aluB      => aluB     , 
   aluOp     => aluOp    , 
   aluResult => aluResult, 
   ready     => ready    , 
   newChar   => newChar  , 
   send      => send     , 
   charRec   => charRec  , 
   charSend  => charSend 
) ;

-- Regsiter file
reg_file : regs port map (
   clk    => clk    , 
   en     => en     , 
   rst    => rst    , 
   id1    => rID1   , 
   id2    => rID2   , 
   wr_en1 => wr_enR1,
   wr_en2 => wr_enR2,
   din1   => regwD1 , 
   din2   => regwD2 , 
   dout1  => regrD1 , 
   dout2  => regrD2 
 );


-- framebuffer
framebuffer_inst : framebuffer port map (
    clk      => clk     ,  
    rst      => fbRST   ,  
    en1      => en      ,
    en2      => en2     ,
    ld       => fbLd    ,
    addr1    => fbAddr1 ,
    addr2    => addr2   ,
    wr_en1   => wr_enR1 ,  
    din1     => fbDout1 ,
    dout1    => fbDin1  ,
    dout2    => open     
) ;

--uart
uart_inst : uart port map (
    clk      => clk,
    rst      => rst,
    en       => en,
    send     => send,
    rx       => rx_in,
    charSend => charSend,
    ready    => ready,
    tx       => tx_out,
    newChar  => newChar,
    charRec  => charRec
);

--alu
alu_inst : my_alu port map (
    clk      => clk,      
    clk_en   => en,      
    A        => aluA,      
    B        => aluB,      
    ALU_sel  => aluOp,      
    ALU_out  => aluResult
);

   stim : process
   begin
     en        <= '0';
     rst       <= '1';
     wait for 10 ns; 
     rst       <= '0';
     wait for 10 ns; 
     en        <= '1';
     wait for 1000 ns; 
     en        <= '0';
     wait for 10 ns; 
     finished  <= '1';
     wait; 
     --assert false report "end of simulation" severity failure;
   end process;

  clk <= not clk after 2 ns when finished /= '1' else '0';

  -- Initialization Memory - Instruction
  inst_mem_init : process
  begin

      -- add $r3 $r4 $r5 - 0x00C85000
      inst_mem(0) <= "00000000110010000101000000000000";  --32'h00C85000

      -- seq $r3, $r6, $r30
      --inst_mem(1) <= "01010" & "00011" & "00110" & "11110" & "000000000000"; 

      -- ori $r3, $r5, 4
     -- inst_mem(2) <= "10010" & "00011" & "00101" & "0000000000000100" & "0"; 

      for i in 3 to 16383 loop
        inst_mem(conv_integer(i)) <= "00000000000000000000000000000000"; 
      end loop;  -- ii
      wait; 
      

  end process;

  -- Instruction Memory
  instmem : process(clk)
  begin
      if (rising_edge(clk)) then
          irWord <= inst_mem(conv_integer(irAddr));
      end if;
  end process;
  
   data_ram_inst :  data_ram port map (
    clk      => clk, 
    rst      => rst, 
    d_wr_en  => d_wr_en, 
    dAddr    => dAddr, 
    dOut     => dIn, 
    dIn      => dOut 
   );
   
  addr2 <= (others => '0');
  en2   <= '0';

end test;
