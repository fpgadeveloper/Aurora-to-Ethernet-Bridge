--
--      Project:  Aurora Module Generator version 2.8
--
--         Date:  $Date: 2007/08/08 11:13:33 $
--          Tag:  $Name: i+IP+144838 $
--         Date:  $Date: 2007/08/08 11:13:33 $
--          Tag:  $Name: i+IP+144838 $
--         File:  $RCSfile: aurora_example_tb_gtp_vhd.ejava,v $
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
--  AURORA_SAMPLE_TB
--
--  Aurora Generator
--
--          Xilinx Embedded Networking Systems Engineering Group
--
--                    Xilinx - Garden Valley Design Team
--
--
--  Description:  This testbench instantiates 2 Aurora Sample Modules. The serial TX pins from  
--                one module are connected to the RX pins of the other and vice versa. A simple Local-Link
--                frame generator is used to generate packets for the TX data interface while a frame checker
--                module is connected to the RX data interface to check the incoming frames and keep 
--                track of any errors.
--         

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use WORK.AURORA_PKG.all;

-- synthesis translate_off
library UNISIM;
use UNISIM.all;
-- synthesis translate_on

entity SAMPLE_TB is
end SAMPLE_TB;

architecture MAPPED of SAMPLE_TB is

--*************************Parameter Declarations**************************

    constant  CLOCKPERIOD_1 : time := 8.0 ns;
    constant  CLOCKPERIOD_2 : time := 8.0 ns;
    constant  DLY           : time := 1 ns;


--********************************Signal Declarations**********************************

--Freerunning Clock
    signal  reference_clk_1_n_r   :  std_logic;
    signal  reference_clk_2_n_r   :  std_logic;          
    signal  reference_clk_1_p_r   :  std_logic;
    signal  reference_clk_2_p_r   :  std_logic;          

--Reset
    signal  reset_i               :  std_logic;            
    signal  pma_reset_i           :  std_logic;         

--Dut1

    --Error Detection Interface
    signal  hard_error_1_i        :  std_logic;        
    signal  soft_error_1_i        :  std_logic;        
    signal  frame_error_1_i       :  std_logic;        

    --Status 
    signal   channel_up_1_i       :  std_logic;        
    signal   lane_up_1_i          :  std_logic;


    --GTP Serial I/O
    signal   rxp_1_i              :  std_logic; 
    signal   rxn_1_i              :  std_logic; 
    
    signal   txp_1_i              :  std_logic; 
    signal   txn_1_i              :  std_logic; 

    -- Error signals from the Local Link packet checker
    signal   error_count_1_i      :  std_logic_vector(0 to 7); 


--Dut2

    --Error Detection Interface
    signal  hard_error_2_i        :  std_logic;        
    signal  soft_error_2_i        :  std_logic;        
    signal  frame_error_2_i       :  std_logic;        

    --Status 
    signal   channel_up_2_i       :  std_logic;        
    signal   lane_up_2_i          :  std_logic;


    --GTP Serial I/O
    signal   rxp_2_i              :  std_logic; 
    signal   rxn_2_i              :  std_logic; 
    
    signal   txp_2_i              :  std_logic; 
    signal   txn_2_i              :  std_logic; 

    -- Error signals from the Local Link packet checker
    signal   error_count_2_i      :  std_logic_vector(0 to 7); 


-- Component Declarations --

    component aurora_201_aurora_example 
    generic(
           SIM_GTPRESET_SPEEDUP   :integer :=   0      --Set to 1 to speed up sim reset
           );
    port   (

    -- User I/O

            RESET             : in std_logic;
            HARD_ERROR        : out std_logic;
            SOFT_ERROR        : out std_logic;
            FRAME_ERROR       : out std_logic;
            ERROR_COUNT       : out std_logic_vector(0 to 7);
            LANE_UP           : out std_logic;
            CHANNEL_UP        : out std_logic;
            PMA_INIT          : in  std_logic;
            INIT_CLK          : in  std_logic;
    -- Clocks

           GTPD1_P   : in  std_logic;
           GTPD1_N   : in  std_logic;
   -- GTP I/O

            RXP               : in std_logic;
            RXN               : in std_logic;
            TXP               : out std_logic;
            TXN               : out std_logic

         );

    end component;


begin

    
    --_________________________GTP Serial Connections________________
   

    rxn_1_i      <=    txn_2_i;
    rxp_1_i      <=    txp_2_i;
    rxn_2_i      <=    txn_1_i;
    rxp_2_i      <=    txp_1_i;

    --____________________________Clocks____________________________

    process  
    begin
        reference_clk_1_p_r <= '0';
        wait for CLOCKPERIOD_1 / 2;
        reference_clk_1_p_r <= '1';
        wait for CLOCKPERIOD_1 / 2;
    end process;

    reference_clk_1_n_r <= not reference_clk_1_p_r;

    --____________________________Clocks____________________________

    process  
    begin
        reference_clk_2_p_r <= '0';
        wait for CLOCKPERIOD_2 / 2;
        reference_clk_2_p_r <= '1';
        wait for CLOCKPERIOD_2 / 2;
    end process;

    reference_clk_2_n_r <= not reference_clk_2_p_r;


    --____________________________Resets____________________________

    process
    begin
        reset_i <= '0';
        wait for 45 ns;
        reset_i <= '1';
        wait; 
    end process;

    --____________________________Reseting PMA____________________________

    process
    begin
        pma_reset_i <= '1';
        wait for 16*CLOCKPERIOD_1;
        pma_reset_i <= '0';
        wait; 
    end process;
        

    --________________________Instantiate Dut 1 ________________

aurora_example_1_i : aurora_201_aurora_example 
generic map(
             SIM_GTPRESET_SPEEDUP => 1
           )
port map   (
    -- User IO
    RESET           =>      reset_i,
    -- Error signals from Aurora    
    HARD_ERROR      =>      hard_error_1_i,
    SOFT_ERROR      =>      soft_error_1_i,
    FRAME_ERROR     =>      frame_error_1_i,

    -- Status Signals
    LANE_UP         =>      lane_up_1_i,
    CHANNEL_UP      =>      channel_up_1_i,

    INIT_CLK        =>      reference_clk_1_p_r,
    PMA_INIT        =>      pma_reset_i,

    -- Clock Signals
    GTPD1_P          =>      reference_clk_1_p_r,
    GTPD1_N          =>      reference_clk_1_n_r,


    -- GTP I/O
    RXP             =>      rxp_1_i,
    RXN             =>      rxn_1_i,

    TXP             =>      txp_1_i,
    TXN             =>      txn_1_i,

    -- Error signals from the Local Link packet checker
    ERROR_COUNT     =>      error_count_1_i
);

    --________________________Instantiate Dut 2 ________________

aurora_example_2_i : aurora_201_aurora_example 
generic map(
             SIM_GTPRESET_SPEEDUP => 1
           )
port map   (
    -- User IO
    RESET           =>      reset_i,
    -- Error signals from Aurora    
    HARD_ERROR      =>      hard_error_2_i,
    SOFT_ERROR      =>      soft_error_2_i,
    FRAME_ERROR     =>      frame_error_2_i,

    -- Status Signals
    LANE_UP         =>      lane_up_2_i,
    CHANNEL_UP      =>      channel_up_2_i,

    INIT_CLK        =>      reference_clk_2_p_r,
    PMA_INIT        =>      pma_reset_i,

    -- Clock Signals
    GTPD1_P          =>      reference_clk_2_p_r,
    GTPD1_N          =>      reference_clk_2_n_r,


    -- GTP I/O
    RXP             =>      rxp_2_i,
    RXN             =>      rxn_2_i,

    TXP             =>      txp_2_i,
    TXN             =>      txn_2_i,

    -- Error signals from the Local Link packet checker
    ERROR_COUNT     =>      error_count_2_i
);


end MAPPED;
