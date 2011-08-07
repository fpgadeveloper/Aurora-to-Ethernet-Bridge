--
--      Project:  Aurora Module Generator version 2.8
--
--         Date:  $Date: 2007/08/08 11:13:33 $
--          Tag:  $Name: i+IP+144838 $
--         File:  $RCSfile: frame_gen_vhd.ejava,v $
--          Rev:  $Revision: 1.1.2.1 $
--
--      Company:  Xilinx
--
--   Disclaimer:  XILINX IS PROVIDING THIS DESIGN, CODE, OR
--                INFORMATION "AS IS" SOLELY FOR USE IN DEVELOPING
--                PROGRAMS AND SOLUTIONS FOR XILINX DEVICES.  BY
--                PROVIDING THIS DESIGN, CODE, OR INFORMATION AS
--                ONE POSSIBLE IMPLEMENTATION OF THIS FEATURE,
--                APPLICATION OR STANDARD, XILINX IS MAKING NO
--                REPRESENTATION THAT THIS IMPLEMENTATION IS FREE
--                FROM ANY CLAIMS OF INFRINGEMENT, AND YOU ARE
--                RESPONSIBLE FOR OBTAINING ANY RIGHTS YOU MAY
--                REQUIRE FOR YOUR IMPLEMENTATION.  XILINX
--                EXPRESSLY DISCLAIMS ANY WARRANTY WHATSOEVER WITH
--                RESPECT TO THE ADEQUACY OF THE IMPLEMENTATION,
--                INCLUDING BUT NOT LIMITED TO ANY WARRANTIES OR
--                REPRESENTATIONS THAT THIS IMPLEMENTATION IS FREE
--                FROM CLAIMS OF INFRINGEMENT, IMPLIED WARRANTIES
--                OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
--                PURPOSE.
--
--                (c) Copyright 2004 Xilinx, Inc.
--                All rights reserved.
--

--
--  FRAME GEN
--
--
--
--  Description: This module is a pattern generator to test the Aurora
--               designs in hardware. It generates data and passes it 
--               through the Aurora channel. If connected to a framing 
--               interface, it generates frames of varying size and 
--               separation. The data it generates on each cycle is 
--               a word of all zeros, except for one high bit which 
--               is shifted right each cycle. REM is always set to 
--               the maximum value.


library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use WORK.AURORA_PKG.all;

-- synthesis translate_off
library UNISIM;
use UNISIM.all;
-- synthesis translate_on


entity aurora_201_FRAME_GEN is
port
(
    -- User Interface
    TX_D            : out  std_logic_vector(0 to 15); 
    TX_REM          : out  std_logic;     
    TX_SOF_N        : out  std_logic;
    TX_EOF_N        : out  std_logic;
    TX_SRC_RDY_N    : out  std_logic;
    TX_DST_RDY_N    : in   std_logic;    

    -- System Interface
    USER_CLK        : in  std_logic;   
    RESET           : in  std_logic
); 
end aurora_201_FRAME_GEN;


architecture RTL of aurora_201_FRAME_GEN is


--***********************************Parameter Declarations***************************

    constant DLY : time := 1 ns;


--***************************Internal Register Declarations*************************** 

    signal  tx_d_r                      :   std_logic_vector(0 to 15);    
    signal  frame_size_r                :   std_logic_vector(0 to 7);
    signal  bytes_sent_r                :   std_logic_vector(0 to 7);
    signal  ifg_size_r                  :   std_logic_vector(0 to 3);
    
    --State registers for one-hot state machine
    signal  idle_r                      :   std_logic;
    signal  single_cycle_frame_r        :   std_logic;
    signal  sof_r                       :   std_logic;
    signal  data_cycle_r                :   std_logic;
    signal  eof_r                       :   std_logic;    


 
--*********************************Wire Declarations**********************************
   
    signal  ifg_done_c                  :   std_logic;
    
    --Next state signals for one-hot state machine
    signal  next_idle_c                 :   std_logic;
    signal  next_single_cycle_frame_c   :   std_logic;
    signal  next_sof_c                  :   std_logic;
    signal  next_data_cycle_c           :   std_logic;
    signal  next_eof_c                  :   std_logic;
    
    
begin
--*********************************Main Body of Code**********************************


    --______________________________ Transmit Data  __________________________________    
    --Transmit data when TX_DST_RDY_N is asserted and not in an IFG
    process(USER_CLK)
    begin
        if(USER_CLK'event and USER_CLK='1') then
            if(RESET = '1') then
                tx_d_r          <=  "0000000000000001" after DLY;
            elsif( (not TX_DST_RDY_N and not idle_r)='1' ) then
                tx_d_r          <=  (tx_d_r(15) & tx_d_r(0 to 14) ) after DLY;
            end if;
        end if;
    end process;   


    --Connect TX_D to the internal tx_d_r register
    TX_D    <=   tx_d_r;
    
    
    --Tie REM to indicate all words valid
    TX_REM  <=   '1';
    

    --Use a counter to determine the size of the next frame to send
    process(USER_CLK)
    begin
        if(USER_CLK'event and USER_CLK = '1') then
            if(RESET = '1') then
                frame_size_r    <=  "00000000" after DLY;
            elsif( (single_cycle_frame_r or eof_r)='1' ) then
                frame_size_r    <=  frame_size_r + 1 after DLY;
            end if;
        end if;
    end process;
            
    
    --Use a second counter to determine how many bytes of the frame have already been sent
    process(USER_CLK)
    begin
        if(USER_CLK'event and USER_CLK = '1') then
            if(RESET = '1') then
                bytes_sent_r    <=  "00000000" after DLY;
            elsif( sof_r = '1' ) then
                bytes_sent_r    <=  "00000001" after DLY;
            elsif( (not TX_DST_RDY_N and not idle_r)='1' ) then
                bytes_sent_r    <=  bytes_sent_r + 1 after DLY;
            end if;
        end if;
    end process;
    
    
    --Use a freerunning counter to determine the IFG
    process(USER_CLK)
    begin
        if(USER_CLK'event and USER_CLK = '1') then
            if(RESET = '1') then
                ifg_size_r  <=  "0000" after DLY;
            else
                ifg_size_r  <=  ifg_size_r + 1 after DLY;
            end if;
        end if;
    end process;
            
    
    --IFG is done when ifg_size register is 0
    ifg_done_c  <=   std_bool(ifg_size_r = "0000");
    
    
    
    --_____________________________ Framing State machine______________________________ 
    --Use a state machine to determine whether to start a frame, end a frame, send
    --data or send nothing
    
    --State registers for 1-hot state machine
    process(USER_CLK)
    begin
        if(USER_CLK'event and USER_CLK = '1') then
            if(RESET = '1') then
                idle_r                  <=  '1' after DLY;
                single_cycle_frame_r    <=  '0' after DLY;
                sof_r                   <=  '0' after DLY;
                data_cycle_r            <=  '0' after DLY;
                eof_r                   <=  '0' after DLY;
            elsif( (not TX_DST_RDY_N)= '1' ) then
                idle_r                  <=  next_idle_c after DLY;
                single_cycle_frame_r    <=  next_single_cycle_frame_c after DLY;
                sof_r                   <=  next_sof_c after DLY;
                data_cycle_r            <=  next_data_cycle_c after DLY;
                eof_r                   <=  next_eof_c after DLY;
            end if;
        end if;
    end process;
        
        
    --Nextstate logic for 1-hot state machine
    next_idle_c                 <=   not ifg_done_c and
                                     (single_cycle_frame_r or eof_r or idle_r);
    
    next_single_cycle_frame_c   <=   (ifg_done_c and std_bool(frame_size_r = "00000000")) and
                                     (idle_r or single_cycle_frame_r or eof_r);
                                    
    next_sof_c                  <=   (ifg_done_c and std_bool(frame_size_r /= "00000000")) and
                                     (idle_r or single_cycle_frame_r or eof_r);
                                    
    next_data_cycle_c           <=   std_bool(frame_size_r /= bytes_sent_r) and
                                     (sof_r or data_cycle_r);
                                    
    next_eof_c                  <=   std_bool(frame_size_r = bytes_sent_r) and
                                     (sof_r or data_cycle_r);
    
    
    --Output logic for 1-hot state machine
    process(USER_CLK)
    begin
        if(USER_CLK'event and USER_CLK = '1') then
            if(RESET = '1') then
                TX_SOF_N        <=  '1' after DLY;
                TX_EOF_N        <=  '1' after DLY;
                TX_SRC_RDY_N    <=  '1' after DLY;       
            elsif( (not TX_DST_RDY_N)='1' ) then
                TX_SOF_N        <=  not (sof_r or single_cycle_frame_r) after DLY;
                TX_EOF_N        <=  not (eof_r or single_cycle_frame_r) after DLY;
                TX_SRC_RDY_N    <=  idle_r after DLY;
            end if;
        end if;
    end process;

                

end RTL;
