library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity controls is
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
end controls ;

architecture rtl of controls is


    type state is (idle, fetch, decode, decode_lat, rops, iops, jops, calc, store, jr, recv, rpix, wpix, send_st, equals, nequals, ori, lw, sw, jmp, jal, clrscr, finish);
    signal curr : state := idle;
    signal curr_d1 : state := idle;
    
    signal pc_signal       : std_logic_vector (13 downto 0) := (others => '0');
    signal instruction     : std_logic_vector (31 downto 0) := (others => '0');
    signal opcode_2bits    : std_logic_vector (1  downto 0) := (others => '0');
    signal opcode          : std_logic_vector (4  downto 0) := (others => '0');
    signal op_addr_r1      : std_logic_vector (4  downto 0) := (others => '0'); 
    signal op_addr_r2      : std_logic_vector (4  downto 0) := (others => '0');
    signal op_addr_r3      : std_logic_vector (4  downto 0) := (others => '0');
    signal opcode_btm3bits : std_logic_vector (2  downto 0) := (others => '0');
    signal store_aluResult : std_logic_vector (15 downto 0) := (others => '0');
    signal imm             : std_logic_vector (15 downto 0) := (others => '0');
    signal imm_pc          : std_logic_vector (13 downto 0) := (others => '0');
    signal alu_out         : std_logic_vector (15 downto 0) := (others => '0');


begin

    instruction     <= irWord;
    opcode_2bits    <= instruction(31 downto 30); -- Opcode (4 downto 3)
    opcode_btm3bits <= opcode(2 downto 0);
    opcode          <= instruction(31 downto 27); -- Opcode - 5 bits
    imm             <= instruction(16 downto 1);
    imm_pc          <= instruction(26 downto 13);
    alu_out         <= aluResult;

    control_fsm : process (clk, rst)
    begin
        if (rst = '1') then
            curr            <= idle;
            curr_d1         <= idle;
            wr_enR1         <= '0'; 
            wr_enR2         <= '0'; 
            fbRST           <= '0'; 
            fbLd            <= '0'; 
            d_wr_en         <= '0'; 
            send            <= '0'; 
            charSend        <= (others => '0'); 
            rID1            <= (others => '0'); 
            rID2            <= (others => '0'); 
            regwD1          <= (others => '0'); 
            regwD2          <= (others => '0'); 
            fbAddr1         <= (others => '0'); 
            fbDout1         <= (others => '0'); 
            irAddr          <= (others => '0'); 
            dAddr           <= (others => '0'); 
            dOut            <= (others => '0'); 
            aluA            <= (others => '0'); 
            aluB            <= (others => '0'); 
            aluOp           <= (others => '0'); 
            pc_signal       <= (others => '0'); 
            op_addr_r1      <= (others => '0');
            op_addr_r2      <= (others => '0');
            op_addr_r3      <= (others => '0');
            store_aluResult <= (others => '0');
        elsif (rising_edge(clk))  then
            curr_d1         <= curr           ;
            if (en = '1') then  

                case curr is
                    when idle   => 
                        curr <= fetch;
                     
                    when fetch  =>
                        -- ToDo :
                        -- Get PC from reg into signal pc_signal
                        pc_signal    <= regrD1(13 downto 0);
                        irAddr       <= regrD1(13 downto 0);
                        -- NextState : 
                        -- decode    
                        curr <= decode;
                        
                    when decode =>
                        -- ToDo :
                        -- Get instructon = irMem[pc_signal]
                        -- Increment pc_signal + 1 and store it in reg 1
                        --irAddr       <= pc_signal;
                        regwD1       <= ("00" & pc_signal) + 1;
                        rID1         <= "00001"; -- PC @ Address 1
                        wr_enR1      <= '1';
                        -- NextState : 
                        -- decode_lat
                        -- Since irMem is having 1 cycle latency 1 new state is added (decode_lat)
                        curr         <= decode_lat;

                    when decode_lat =>    
                        -- Flush previous asserted outputs
                        wr_enR1      <= '0';
                        -- NextState : 
                        -- Rops if opcode top bits are 00 or 01 else Iops if 10 else Jops
                        if (opcode_2bits = "00" or opcode_2bits = "01") then
                            curr     <= rops;
                        elsif (opcode_2bits = "10") then
                            curr     <= iops;
                        else
                            curr     <= jops;
                        end if;

                    when rops   =>
                        -- ToDo :
                        -- Break up instruction into arguments. Use arguments to fetch register contents for reg2 and reg3 into signals
                        -- [op][reg1][reg2][reg3]
                        -- Note : Opcode in Instruction is of 5 bits where MSBs bits are used to identify the type of instruction where lower 4 bits (3 LSB + 1 MSB) 
                        --        is used to give ALU Opcode
                        -- Instruction              31	30	29	28	27
                        --    Type of Instruction	31	30
                        --    Opcode	     		30	29	28	27

                        -- Example
                        -- add $r3 $r4 $r5 - 0x00C85000
                        --                 - 0000 0000 1100 1000 0101 0000 0000 0000 0000
                        -- New Inst : Opcode : 31:27 : 0000 0
                        --            R1     : 26:22 :  000 11
                        --            R2     : 21:17 :   00 100
                        --            R3     : 16:12 :    0 0101
                        
                        op_addr_r1 <= instruction(26 downto 22)    ; -- Result Store
                        op_addr_r2 <= instruction(21 downto 17)    ; -- OpA
                        op_addr_r3 <= instruction(16 downto 12)    ; -- OpB
                        -- 5 bit Operand, 27 bits (5 bit address is required to address any registers between 0 to 31)
                        -- NextState : 
                        -- jr if opcode is 01101 else recv if 01100 else rpix if 01111 else wpix if 01110 else send if 01011 else calc
                        if (opcode = "01101") then
                            curr <= jr;
                            rID1 <= instruction(26 downto 22);
                            rID2 <= instruction(21 downto 17);
                        elsif (opcode = "01100") then
                            curr <= recv;
                            rID1 <= instruction(26 downto 22);
                            rID2 <= instruction(21 downto 17);
                        elsif (opcode = "01111") then
                            curr <= rpix;
                            rID1 <= instruction(26 downto 22);
                            rID2 <= instruction(21 downto 17);
                        elsif (opcode = "01110") then
                            curr <= wpix;
                            rID1 <= instruction(26 downto 22);
                            rID2 <= instruction(21 downto 17);
                        elsif (opcode = "01011") then
                            curr <= send_st;
                            rID1 <= instruction(26 downto 22);
                        else
                            curr <= calc;
                            rID1 <= instruction(21 downto 17);
                            rID2 <= instruction(16 downto 12);
                        end if;
                        
                    when iops   =>
                        -- ToDo :
                        -- Break up instruction into arguments.  Use arguments to fetch register contents for reg2 into signal                        
                        -- [op][reg1][reg2][imm]
                        -- New Inst : Opcode : 31:27 
                        --            R1     : 26:22 
                        --            R2     : 21:17 
                        --            Imm    : 16:1  

                        op_addr_r1 <= instruction(26 downto 22)    ; 
                        op_addr_r2 <= instruction(21 downto 17)    ; 
                        -- NextState : 
                        -- equals if opcode bottom 3 bits are 000 else nequal if 001 else ori if 010 else lw if 011 else sw 
                        if (opcode_btm3bits = "000") then
                            curr <= equals;
                            rID1     <= instruction(26 downto 22);
                            rID2     <= instruction(21 downto 17);
                        elsif (opcode_btm3bits = "001") then
                            curr <= nequals;
                            rID1     <= instruction(26 downto 22);
                            rID2     <= instruction(21 downto 17);
                        elsif (opcode_btm3bits = "010") then
                            curr <= ori;
                            rID1     <= instruction(26 downto 22);
                            rID2     <= instruction(21 downto 17);
                        elsif (opcode_btm3bits = "011") then
                            curr <= lw;
                            rID1 <= instruction(26 downto 22);
                            rID2 <= instruction(21 downto 17);
                        else
                            curr <= sw;
                            rID1     <= instruction(26 downto 22);
                            rID2     <= instruction(21 downto 17);
                        end if;

                    when jops   =>
                        -- ToDo :
                        -- Break up instruction into arguments
                        -- NextState : 
                        -- jmp if opcode is 11000 else jal if 11001 else clrscr
                        rID1         <= "00001"; -- PC @ Address 1
                        if (opcode = "11000") then
                            curr <= jmp;
                        elsif (opcode = "11001") then
                            curr <= jal ;
                        else
                            curr <= clrscr;
                        end if;

                    when calc   =>
                        -- ToDo :
                        -- Apply the register operands and the correct opcode to the ALU and store the result into an alu result signal
                        aluOp           <= opcode(3 downto 0); -- 4 Bit opcode for ALU 
                        aluA            <= regrD1;
                        aluB            <= regrD2;
                        -- NextState : 
                        -- Store
                        store_aluResult <= aluResult;
                        curr <= store;
                    

                    when store  =>
                        -- ToDo :
                        -- Store the alu result signal into the appropriate register given by argument reg1
                        rID1    <= op_addr_r1;
                        wr_enR1 <= '1';
                        -- regwD1  <= store_aluResult when curr_d1 \= idle else aluResult;
                        -- regwD1  <= aluResult when (curr_d1 = calc) else 
                        --            dIn when (curr_d1 = lw) else 
                        --            store_aluResult ;
                        if(curr_d1 = calc) then
                            regwD1 <= aluResult;
                        elsif (curr_d1 = lw) then
                            regwD1 <= dIn;
                        elsif (curr_d1 = rpix) then
                            regwD1 <= fbDin1;
                            fbLd   <= '0';
                        else 
                            regwD1 <= store_aluResult;
                        end if;
                        -- NextState : 
                        -- finish
                        curr <= finish;

                    when jr     =>
                        -- ToDo :
                        -- Read the register value specified and store it in alu result signal
                        store_aluResult    <= regrD1;
                        op_addr_r1         <= "00001";  -- PC @ Address 1
                        -- NextState : 
                        -- store
                        curr <= store;

                    when recv   =>
                        -- ToDo :
                        -- Store charRec into alu result signal 
                        store_aluResult(7 downto 0) <= charRec;
                        -- NextState : 
                        -- recv if newChar is 0 else store
                        if (newChar = '0') then 
                            curr <= recv;
                        else
                            curr <= store;
                        end if;

                    when rpix   =>
                        -- ToDo :
                        -- Read the framebuffer memory at the address of the value in reg2 and store it in alu result signal
                        fbAddr1         <= regrD2(11 downto 0); 
                        fbLd            <= '1';
                        store_aluResult <= fbDin1; 
                        -- NextState : 
                        -- store
                        curr <= store;

                    when wpix   =>
                        -- ToDo :
                        -- Store the value read from reg2 into framebuffer[reg1]
                        fbAddr1 <= regrD1(11 downto 0); 
                        fbDout1 <= regrD2;
                        -- NextState : 
                        -- store
                        curr <= finish;

                    when send_st   =>
                        -- ToDo :
                        -- Make send 1 and assign the value read from reg1 to charSend
                        send     <= '1';
                        charSend <= regrD1(7 downto 0);
                        -- NextState : 
                        -- If ready is 1 finish, else send
                        if (ready   = '1') then 
                            curr <= finish;
                        else
                            curr <= send_st  ;
                        end if;

                    when equals =>
                        -- ToDo :
                        if (regrD1 = regrD2) then
                            store_aluResult <= "00" & imm(15 downto 2);  
                            op_addr_r1 <= "00001"; -- Adderess 1 is for PC
                        else
                            store_aluResult <= (others => '0');  
                        end if;

                        -- If values equal set alu signal to immediate and set reg1 signal to pc id
                        -- NextState : 
                        -- store
                        curr <= store;

                    when nequals =>
                        -- ToDo :
                        -- If values not equal set alu signal to immediate and set reg1 signal to pc id
                        if (regrD1 /= regrD2) then
                            store_aluResult <= "00" & imm(15 downto 2);  
                            op_addr_r1 <= "00001"; -- Adderess 1 is for PC
                        else
                            store_aluResult <= (others => '0');  
                        end if;
                        -- NextState : 
                        -- store
                        curr <= store;

                    when ori     =>
                        -- ToDo :
                        -- Store the result of the immediate bitwise ORed with the value from reg2 into the alu signal
                        store_aluResult  <= regrD2 or imm;
                        -- NextState : 
                        -- store
                        curr <= store;

                    when lw      =>
                        -- ToDo :
                        -- Set the value of the alu signal to the value in dmem[reg2+imm]
                        dAddr      <= regrD2(14 downto 0) + imm(14 downto 0);
                        store_aluResult  <= dIn;
                        -- NextState : 
                        -- store
                        curr <= store;
                        
                    when sw      =>
                        -- ToDo :
                        -- Store the value of reg1 into dmem[reg2+imm]
                        dAddr      <= regrD2(14 downto 0) + imm(14 downto 0); -- reg2 + imm
                        dOut       <= regrD1;
                        d_wr_en    <= '1';
                        -- NextState : 
                        -- finish
                        curr <= finish;

                    when jmp     =>
                        -- ToDo :
                        -- [op][imm]
                        -- Set the value of the pc register to the immediate
                        --rID1         <= "00001"; -- PC @ Address 1
                        wr_enR1      <= '1';
                        regwD1       <= "00" & imm_pc; -- store immediate value to PC
                        -- NextState : 
                        -- finish
                        curr <= finish;

                    when jal     =>
                        -- ToDo :
                        -- Set the value of the ra register to the value of the pc register and set the value of the pc register to the immediate
                        -- ra = pc, pc = imm
                        --rID1         <= "00001"; -- PC @ Address 1
                        rID2         <= "00010"; -- RA @ Address 2
                        wr_enR2      <= '1';
                        regwD2       <= regrD1; -- store immediate value to PC
                        wr_enR1      <= '1';
                        regwD1       <= "00" & imm_pc; -- store immediate value to PC
                        -- NextState : 
                        -- finish
                        curr <= finish;

                    when clrscr  =>
                        -- ToDo :
                        -- Set fbRST to 1
                        -- NextState : 
                        -- finish
                        fbRST <= '1';  
                        curr <= finish;

                    when finish  =>
                        -- ToDo :
                        -- De-assert control signals
                        op_addr_r1   <= (others => '0');
                        op_addr_r2   <= (others => '0');
                        op_addr_r3   <= (others => '0');
                        --instruction  <= (others => '0');
                        wr_enR1      <= '0'; 
                        wr_enR2      <= '0'; 
                        fbRST        <= '0'; 
                        d_wr_en      <= '0'; 
                        send         <= '0'; 
                        rID1         <= (others => '0');                         
                        rID2         <= (others => '0'); 
                        regwD1       <= (others => '0'); 
                        regwD2       <= (others => '0'); 
                        fbAddr1      <= (others => '0'); 
                        fbDout1      <= (others => '0'); 
                        dAddr        <= (others => '0'); 
                        dOut         <= (others => '0'); 
                        aluA         <= (others => '0'); 
                        aluB         <= (others => '0'); 
                        aluOp        <= (others => '0'); 
                        charSend     <= (others => '0'); 
                        store_aluResult  <= (others => '0'); 
                        rID1         <= "00001"; -- PC @ Address 1
                        -- NextState :
                        -- Fetch
                        curr <= fetch;
                end case;
            end if;
        end if;
    end process control_fsm;
end rtl; 




