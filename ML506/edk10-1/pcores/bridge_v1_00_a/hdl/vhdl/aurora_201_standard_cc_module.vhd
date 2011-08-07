 
--
--      Project:  Aurora Module Generator version 2.8
--
--         Date:  $Date: 2007/08/08 11:13:34 $
--          Tag:  $Name: i+IP+144838 $
--         File:  $RCSfile: standard_cc_module_vhd.ejava,v $
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
--  STANDARD_CC_MODULE
--
--          Xilinx - Embedded Networking System Engeneering Group
--
--  Description: This module drives the Aurora module's Clock Compensation
--               interface.  Clock Compensation sequences are generated according
--               to the requirements in the Aurora Protocol specification.
--
--               This module supports Aurora Modules with any number of
--               2-byte lanes and no User Flow Control.
--

library IEEE;
use IEEE.STD_LOGIC_1164.all;

-- synthesis translate_off
library UNISIM;
use UNISIM.all;
-- synthesis translate_on


entity aurora_201_STANDARD_CC_MODULE is
port
(    
    -- Clock Compensation Control Interface
    WARN_CC        : out std_logic;
    DO_CC          : out std_logic;


    -- System Interface
    DCM_NOT_LOCKED : in std_logic;
    USER_CLK       : in std_logic;
    CHANNEL_UP     : in std_logic

);
end aurora_201_STANDARD_CC_MODULE;

architecture RTL of aurora_201_STANDARD_CC_MODULE is


--******************************Parameter Declarations*******************************

    constant DLY : time := 1 ns;
   
    

--************************** Internal Register Declarations **************************

    signal      prepare_count_r     : std_logic_vector(0 to 9) := "0000000000";
    signal      cc_count_r          : std_logic_vector(0 to 5) := "000000";
    signal      reset_r             : std_logic;
    
    signal      count_13d_srl_r     : std_logic_vector(0 to 11);
    signal      count_13d_flop_r    : std_logic;
    signal      count_16d_srl_r     : std_logic_vector(0 to 14);
    signal      count_16d_flop_r    : std_logic;
    signal      count_24d_srl_r     : std_logic_vector(0 to 22);
    signal      count_24d_flop_r    : std_logic;    


--*********************************Wire Declarations**********************************

    signal      start_cc_c              : std_logic;
    signal      inner_count_done_r      : std_logic;
    signal      middle_count_done_c     : std_logic;
    signal      cc_idle_count_done_c    : std_logic;
    
   
--*********************************Main Body of Code**********************************
begin

 
 --________________________Clock Correction State Machine__________________________
 
 
 
    -- The clock correction state machine is a counter with three sections.  The first
    -- section counts out the idle period before a clock correction occurs.  The second
    -- section counts out a period when NFC and UFC operations should not be attempted
    -- because they will not be completed.  The last section counts out the cycles of
    -- the clock correction sequence.
 


 
    -- The inner count for the CC counter counts to 13.  It is implemented using
    -- an SRL16 and a flop

    -- The SRL counts 12 bits of the count
    process(USER_CLK)
    begin
        if(USER_CLK'event and USER_CLK = '1') then
            count_13d_srl_r <=   (count_13d_flop_r & count_13d_srl_r(0 to 10)) after DLY;
        end if;
    end process;
    
   
    
    -- The inner count is done when a 1 reaches the end of the SRL
    inner_count_done_r  <=  count_13d_srl_r(11);
 
 
    -- The flop extends the shift register to 13 bits for counting. It is held at 
    -- zero while channel up is low to clear the register, and is seeded with a 
    -- single 1 when channel up transitions from 0 to 1
    process(USER_CLK)
    begin
        if(USER_CLK'event and USER_CLK = '1') then
            if(CHANNEL_UP = '0') then
                count_13d_flop_r    <=  '0' after DLY;
            elsif( (CHANNEL_UP and reset_r)= '1') then
                count_13d_flop_r    <=  '1' after DLY;
            else
                count_13d_flop_r    <=  inner_count_done_r after DLY;
            end if;
        end if;
    end process;
             
 
 
    -- The middle count for the CC counter counts to 16.  Its count increments only
    -- when the inner count is done.  It is implemented using an SRL16 and a flop
 
    
    -- The SRL counts 15 bits of the count. It is enabled only when the inner count
    -- is done
    process(USER_CLK)
    begin
        if(USER_CLK'event and USER_CLK = '1') then
            if((inner_count_done_r or not CHANNEL_UP) = '1') then
                count_16d_srl_r <=  ( count_16d_flop_r & count_16d_srl_r(0 to 13) ) after DLY;
            end if;
        end if;
    end process;
    
            
    
    -- The middle count is done when a 1 reaches the end of the SRL and the inner
    -- count finishes
    middle_count_done_c <=   inner_count_done_r and count_16d_srl_r(14);     
 
 
    
    -- The flop extends the shift register to 16 bits for counting. It is held at
    -- zero while channel up is low to clear the register, and is seeded with a 
    -- single 1 when channel up transitions from 0 to 1
    process(USER_CLK)
    begin
        if(USER_CLK'event and USER_CLK = '1') then
            if(CHANNEL_UP = '0') then
                count_16d_flop_r    <=  '0' after DLY;
            elsif((CHANNEL_UP and reset_r)='1') then
                count_16d_flop_r    <=  '1' after DLY;
            elsif(inner_count_done_r = '1') then
                count_16d_flop_r    <=  middle_count_done_c after DLY;
            end if;
        end if;
    end process;
                
              
 
    -- The outer count (aka the cc idle count) is done when it reaches 24.  Its count
    -- increments only when the middle count is done.  It is implemented with 2
    -- SRL16Es.             
    
    
    -- The SRL counts 23 bits of the count. It is enabled only when the middle count is
    -- done
    process(USER_CLK)
    begin
        if(USER_CLK'event and USER_CLK = '1') then
            if((middle_count_done_c or not CHANNEL_UP) = '1') then
                count_24d_srl_r     <=  (count_24d_flop_r & count_24d_srl_r(0 to 21)) after DLY;
            end if;
        end if;
    end process;
            
            
            
    -- The cc idle count is done when a 1 reaches the end of the SRL and the middle count finishes
    cc_idle_count_done_c    <=   middle_count_done_c and count_24d_srl_r(22);
    
    
    
    -- The flop extends the shift register to 24 bits for counting. It is held at
    -- zero while channel up is low to clear the register, and is seeded with a single
    -- 1 when channel up transitions from 0 to 1
    process(USER_CLK)
    begin
        if(USER_CLK'event and USER_CLK = '1') then
            if(CHANNEL_UP = '0') then
                count_24d_flop_r    <=  '0' after DLY;
            elsif( (CHANNEL_UP and reset_r) = '1') then
                count_24d_flop_r    <=  '1' after DLY;
            elsif( middle_count_done_c = '1') then
                count_24d_flop_r    <=  cc_idle_count_done_c after DLY;
            end if;
        end if;
    end process;

 
 
     -- Because UFC and CC sequences are not allowed to preempt one another, there
     -- there is a warning signal to indicate an impending CC sequence.  This signal
     -- is used to prevent UFC messages from starting.
    -- For 1 lane, we need an 10-cycle count.
    process(USER_CLK)
    begin
        if(USER_CLK'event and USER_CLK = '1') then
            prepare_count_r <=  (cc_idle_count_done_c & prepare_count_r(0 to 8)) after DLY;
        end if;
    end process;
 
 
    -- The state machine stays in the prepare_cc state from when the cc idle
    -- count finishes, to when the prepare count has finished.  While in this
    -- state, UFC operations cannot start, which prevents them from having to
    -- be pre-empted by CC sequences.
    process(USER_CLK)
    begin
        if(USER_CLK'event and USER_CLK = '1') then
            if(CHANNEL_UP = '0') then
                WARN_CC     <=  '0'     after DLY;
            elsif(cc_idle_count_done_c = '1') then
                WARN_CC     <=  '1'     after DLY;
            elsif(prepare_count_r(9) = '1') then
                WARN_CC    <=   '0'     after DLY;
            end if;
        end if;
    end process;
 

 
 
 
    -- Track the state of channel up on the previous cycle. We use this signal to determine
    -- when to seed the shift register counters with ones
    process(USER_CLK)
    begin
        if(USER_CLK'event and USER_CLK = '1') then
            reset_r <=  not CHANNEL_UP after DLY;
        end if;
    end process;
 
 
 
    --Do a CC after CHANNEL_UP is asserted or CC_warning is complete.
    start_cc_c   <=   prepare_count_r(9) or (CHANNEL_UP and reset_r);
 
 
 
     -- This SRL counter keeps track of the number of cycles spent in the CC
     -- sequence.  It starts counting when the prepare_cc state ends, and
     -- finishes counting after 6 cycles have passed.
    process(USER_CLK)
    begin
        if(USER_CLK'event and USER_CLK = '1') then
            cc_count_r      <=  ( (not CHANNEL_UP or prepare_count_r(9)) & cc_count_r(0 to 4) ) after DLY;
        end if;
    end process;
 
 
 
     -- The TX_LL module stays in the do_cc state for 6 cycles.  It starts
     -- when the prepare_cc state ends.
    process(USER_CLK)
    begin
        if(USER_CLK'event and USER_CLK = '1') then
            if(CHANNEL_UP = '0') then
                DO_CC <=  '0'   after DLY;
            elsif(start_cc_c = '1') then
                DO_CC <=  '1'   after DLY;
            elsif(cc_count_r(5) = '1') then
                DO_CC <=  '0'   after DLY;
            end if;
        end if;
    end process;


end RTL;


