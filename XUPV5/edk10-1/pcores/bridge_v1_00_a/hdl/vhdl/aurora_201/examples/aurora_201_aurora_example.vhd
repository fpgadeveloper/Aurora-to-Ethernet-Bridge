--
--      Project:  Aurora Module Generator version 2.8
--
--         Date:  $Date: 2007/08/08 11:13:33 $
--          Tag:  $Name: i+IP+144838 $
--         File:  $RCSfile: aurora_example_gtp_vhd.ejava,v $
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
--  AURORA_SAMPLE
--
--  Aurora Generator
--
--          Xilinx Embedded Networking Systems Engineering Group
--
--                    Xilinx - Garden Valley Design Team
--
--  Description: Sample Instantiation of a 1 2-byte lane module.
--               Only tests initialization in hardware.
--
--  Note:  This Example design is intended for use on a Xilinx MLXXX
--         prototyping Board which contains an XXXXXXX part.  Aurora
--         configurations that are too large to fit within this part
--         cannot use this example design as is.  If you wish to use
--         this design with larger configurations of Aurora or with
--         a custom board, you must modify this source file and the
--         aurora_example.ucf file as needed.
--         

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use WORK.AURORA_PKG.all;

-- synthesis translate_off
library UNISIM;
use UNISIM.all;
-- synthesis translate_on

entity aurora_201_aurora_example is
   generic(
           SIM_GTPRESET_SPEEDUP   :integer :=   0      --Set to 1 to speed up sim reset
         );
    port (

    -- User I/O

            RESET             : in std_logic;
            HARD_ERROR        : out std_logic;
            SOFT_ERROR        : out std_logic;
            FRAME_ERROR       : out std_logic;
            ERROR_COUNT       : out std_logic_vector(0 to 7);
            LANE_UP           : out std_logic;
            CHANNEL_UP        : out std_logic;
            INIT_CLK          : in  std_logic;
            PMA_INIT          : in  std_logic;

    -- Clocks

           GTPD1_P   : in  std_logic;
           GTPD1_N   : in  std_logic;
   -- GTP I/O

            RXP               : in std_logic;
            RXN               : in std_logic;
            TXP               : out std_logic;
            TXN               : out std_logic

         );

end aurora_201_aurora_example;

architecture MAPPED of aurora_201_aurora_example is

-- Parameter Declarations --

    constant DLY : time := 1 ns;

-- External Register Declarations --
    signal ila_data_i         : std_logic_vector(41 downto 0);
    signal icon_ila_i         : std_logic_vector(35 downto 0);

    signal HARD_ERROR_Buffer  : std_logic;
    signal SOFT_ERROR_Buffer  : std_logic;
    signal FRAME_ERROR_Buffer : std_logic;
    signal LANE_UP_Buffer     : std_logic;
    signal CHANNEL_UP_Buffer  : std_logic;
    signal TXP_Buffer         : std_logic;
    signal TXN_Buffer         : std_logic;

-- Internal Register Declarations --

    signal reset_debounce_r   : std_logic_vector(0 to 3);
    signal pma_init_r         : std_logic; 
    signal init_clk_i         : std_logic; 

-- Wire Declarations --

    -- LocalLink TX Interface

    signal tx_d_i             : std_logic_vector(0 to 15);
    signal tx_rem_i           : std_logic;
    signal tx_src_rdy_n_i     : std_logic;
    signal tx_sof_n_i         : std_logic;
    signal tx_eof_n_i         : std_logic;

    signal tx_dst_rdy_n_i     : std_logic;

    -- LocalLink RX Interface

    signal rx_d_i             : std_logic_vector(0 to 15);
    signal rx_rem_i           : std_logic;
    signal rx_src_rdy_n_i     : std_logic;
    signal rx_sof_n_i         : std_logic;
    signal rx_eof_n_i         : std_logic;


    -- GTP Reference Clock Interface

    signal GTPD1_left_i      : std_logic;

    -- Error Detection Interface

    signal hard_error_i       : std_logic;
    signal soft_error_i       : std_logic;
    signal frame_error_i      : std_logic;

    -- Status

    signal channel_up_i       : std_logic;
    signal lane_up_i          : std_logic;
    signal lane_up_i_i        : std_logic;

    -- Clock Compensation Control Interface

    signal warn_cc_i          : std_logic;
    signal do_cc_i            : std_logic;

    -- System Interface

    signal dcm_not_locked_i   : std_logic;
    signal user_clk_i         : std_logic;
    signal sync_clk_i    : std_logic;
    signal reset_i            : std_logic;
    signal power_down_i       : std_logic;
    signal loopback_i         : std_logic_vector(0 to 2);
    signal tx_lock_i          : std_logic;
    signal tx_out_clk_i       : std_logic;
    signal buf_tx_out_clk_i     : std_logic; 
     

    --Frame check signals
    signal error_count_i      : std_logic_vector(0 to 7);
    signal ERROR_COUNT_Buffer : std_logic_vector(0 to 7);
    signal test_reset_i       : std_logic;

    signal debounce_pma_init_r  : std_logic_vector(0 to 3);

-- Component Declarations --

    component IBUFGDS

    port (
                O  :  out STD_ULOGIC;
                I  : in STD_ULOGIC;
                IB : in STD_ULOGIC);

    end component;


    component IBUFDS
        port (

                O : out std_ulogic;
                I : in std_ulogic;
                IB : in std_ulogic);

    end component;


    component BUFG

        port (

                O : out std_ulogic;
                I : in  std_ulogic

             );

    end component;

    component IBUFG

        port (

                O : out std_ulogic;
                I : in  std_ulogic

             );
    
    end component;


    component aurora_201_CLOCK_MODULE
        port (
                GTP_CLK                 : in std_logic;
                GTP_CLK_LOCKED          : in std_logic;
                USER_CLK                : out std_logic;
                SYNC_CLK                : out std_logic;
                DCM_NOT_LOCKED          : out std_logic
             );
    end component;


    component aurora_201
        generic(
                 SIM_GTPRESET_SPEEDUP :integer := 0
               );
        port   (
        -- LocalLink TX Interface

                TX_D             : in std_logic_vector(0 to 15);
                TX_REM           : in std_logic;
                TX_SRC_RDY_N     : in std_logic;
                TX_SOF_N         : in std_logic;
                TX_EOF_N         : in std_logic;
                TX_DST_RDY_N     : out std_logic;

        -- LocalLink RX Interface

                RX_D             : out std_logic_vector(0 to 15);
                RX_REM           : out std_logic;
                RX_SRC_RDY_N     : out std_logic;
                RX_SOF_N         : out std_logic;
                RX_EOF_N         : out std_logic;
        -- GTP Serial I/O

                RXP              : in std_logic;
                RXN              : in std_logic;

                TXP              : out std_logic;
                TXN              : out std_logic;

        -- GTP Reference Clock Interface

                GTPD1   : in std_logic;


        -- Error Detection Interface

                HARD_ERROR       : out std_logic;
                SOFT_ERROR       : out std_logic;
                
                FRAME_ERROR      : out std_logic;

        -- Status

                CHANNEL_UP       : out std_logic;
                LANE_UP          : out std_logic;

        -- Clock Compensation Control Interface

                WARN_CC          : in std_logic;
                DO_CC            : in std_logic;

        -- System Interface

                DCM_NOT_LOCKED   : in std_logic;
                USER_CLK         : in std_logic;
                SYNC_CLK         : in std_logic;
                PMA_INIT         : in std_logic;
                RESET            : in std_logic;
                POWER_DOWN       : in std_logic;
                LOOPBACK         : in std_logic_vector(2 downto 0);
                TX_LOCK          : out std_logic;
                TX_OUT_CLK       : out std_logic
            );

    end component;


    component aurora_201_STANDARD_CC_MODULE

        port (

        -- Clock Compensation Control Interface

                WARN_CC        : out std_logic;
                DO_CC          : out std_logic;

        -- System Interface

                DCM_NOT_LOCKED : in std_logic;
                USER_CLK       : in std_logic;
                CHANNEL_UP     : in std_logic

             );

    end component;
    
 
    component aurora_201_FRAME_GEN
    port
    (
        -- User Interface
        TX_D            : out  std_logic_vector(0 to 15); 
        TX_REM          : out  std_logic;     
        TX_SOF_N        : out  std_logic;
        TX_EOF_N        : out  std_logic;
        TX_SRC_RDY_N    : out  std_logic;
        TX_DST_RDY_N    : in  std_logic;    

        -- System Interface
        USER_CLK        : in  std_logic;   
        RESET           : in  std_logic
    ); 
    end component;
 
 
    component aurora_201_FRAME_CHECK
    port
    (
        -- User Interface
        RX_D            : in  std_logic_vector(0 to 15); 
        RX_REM          : in  std_logic;     
        RX_SOF_N        : in  std_logic;
        RX_EOF_N        : in  std_logic;
        RX_SRC_RDY_N    : in  std_logic;  

        -- System Interface
        USER_CLK        : in  std_logic;   
        RESET           : in  std_logic;
        ERROR_COUNT     : out std_logic_vector(0 to 7)
  
    );
    end component;
    
   

begin

    HARD_ERROR  <= HARD_ERROR_Buffer;
    SOFT_ERROR  <= SOFT_ERROR_Buffer;
    FRAME_ERROR <= FRAME_ERROR_Buffer;
    ERROR_COUNT <= ERROR_COUNT_Buffer;
    LANE_UP     <= LANE_UP_Buffer;
    CHANNEL_UP  <= CHANNEL_UP_Buffer;
    TXP         <= TXP_Buffer;
    TXN         <= TXN_Buffer;

                                  -- Main Body of Code --
                 

    -- ___________________________Debouncing circuit for PMA_INIT________________________

    -- Assign an IBUFG to INIT_CLK
    init_clk_ibufg_i : IBUFG 
    port map
    (
        I   =>  INIT_CLK,
        O   =>  init_clk_i
    );


    -- Debounce the PMA_INIT signal using the INIT_CLK
    process(init_clk_i)
    begin
        if(init_clk_i'event and init_clk_i='1') then
            debounce_pma_init_r <=  PMA_INIT & debounce_pma_init_r(0 to 2);
        end if;
    end process;
        
    pma_init_r  <=   debounce_pma_init_r(0) and 
                     debounce_pma_init_r(1) and
                     debounce_pma_init_r(2) and
                     debounce_pma_init_r(3);


    -- ___________________________Clock Buffers________________________
   


      IBUFDS_i :  IBUFDS
      port map (
           I  => GTPD1_P ,
           IB => GTPD1_N ,
           O  => GTPD1_left_i
               );

      BUFG_i : BUFG
      port map(
           I => tx_out_clk_i ,
           O => buf_tx_out_clk_i
              );

    -- Instantiate a clock module for clock division

    clock_module_i : aurora_201_CLOCK_MODULE

        port map (

                    GTP_CLK             => buf_tx_out_clk_i,
                    GTP_CLK_LOCKED      => tx_lock_i,
                    USER_CLK            => user_clk_i,
                    SYNC_CLK            => sync_clk_i,
                    DCM_NOT_LOCKED      => dcm_not_locked_i

                 );




    -- Register User I/O --

    -- Register User Outputs from core.

    process (user_clk_i)

    begin

        if (user_clk_i 'event and user_clk_i = '1') then

            HARD_ERROR_Buffer  <= hard_error_i;
            SOFT_ERROR_Buffer  <= soft_error_i;
            FRAME_ERROR_Buffer <= frame_error_i;
            ERROR_COUNT_Buffer <= error_count_i;
            LANE_UP_Buffer     <= lane_up_i;
            CHANNEL_UP_Buffer  <= channel_up_i;

        end if;

    end process;


    -- Tie off unused signals --



    -- System Interface

    power_down_i     <= '0';
    loopback_i       <= "000";


    -- _______________________Debounce the Reset signal________________________ --

    -- Simple Debouncer for Reset button. The debouncer has an
    -- asynchronous reset tied to PMA_INIT. This is primarily for simulation, to ensure
    -- that unknown values are not driven into the reset line
    process (user_clk_i, pma_init_r)
    begin
        if (pma_init_r = '1') then
            reset_debounce_r <= "1111";
        elsif (user_clk_i 'event and user_clk_i = '1') then
            reset_debounce_r <= not RESET & reset_debounce_r(0 to 2);
        end if;
    end process;


    reset_i <= reset_debounce_r(0) and
               reset_debounce_r(1) and
               reset_debounce_r(2) and
               reset_debounce_r(3);


    -- _______________________________ Module Instantiations ________________________--



    --Use one of the lane up signals to reset the test logic
    test_reset_i <= not lane_up_i;


    --Connect a frame checker to the user interface
    frame_check_i : aurora_201_FRAME_CHECK
    port map
    (
        -- User Interface
        RX_D            =>  rx_d_i, 
        RX_REM          =>  rx_rem_i,
        RX_SOF_N        =>  rx_sof_n_i,
        RX_EOF_N        =>  rx_eof_n_i,
        RX_SRC_RDY_N    =>  rx_src_rdy_n_i,  

        -- System Interface
        USER_CLK        =>  user_clk_i,   
        RESET           =>  test_reset_i,
        ERROR_COUNT     =>  error_count_i
  
    );



    --Connect a frame generator to the user interface
    frame_gen_i : aurora_201_FRAME_GEN
    port map
    (
        -- User Interface
        TX_D            =>  tx_d_i,
            TX_REM          =>  tx_rem_i,
        TX_SOF_N        =>  tx_sof_n_i,
        TX_EOF_N        =>  tx_eof_n_i,
            TX_SRC_RDY_N    =>  tx_src_rdy_n_i,
        TX_DST_RDY_N    =>  tx_dst_rdy_n_i,    

        -- System Interface
        USER_CLK        =>  user_clk_i,
        RESET           =>  test_reset_i
    ); 




    -- Module Instantiations --

    aurora_module_i : aurora_201
        generic map(
                    SIM_GTPRESET_SPEEDUP => SIM_GTPRESET_SPEEDUP
                   )
        port map   (
        -- LocalLink TX Interface

                    TX_D             => tx_d_i,
                    TX_REM           => tx_rem_i,
                    TX_SRC_RDY_N     => tx_src_rdy_n_i,
                    TX_SOF_N         => tx_sof_n_i,
                    TX_EOF_N         => tx_eof_n_i,
                    TX_DST_RDY_N     => tx_dst_rdy_n_i,

        -- LocalLink RX Interface

                    RX_D             => rx_d_i,
                    RX_REM           => rx_rem_i,
                    RX_SRC_RDY_N     => rx_src_rdy_n_i,
                    RX_SOF_N         => rx_sof_n_i,
                    RX_EOF_N         => rx_eof_n_i,

        -- GTP Serial I/O

                    RXP              => RXP,
                    RXN              => RXN,
                    TXP              => TXP_Buffer,
                    TXN              => TXN_Buffer,

        -- GTP Reference Clock Interface

                   GTPD1    => GTPD1_left_i,
        -- Error Detection Interface

                    HARD_ERROR       => hard_error_i,
                    SOFT_ERROR       => soft_error_i,
                    FRAME_ERROR      => frame_error_i,

        -- Status

                    CHANNEL_UP       => channel_up_i,
                    LANE_UP          => lane_up_i,

        -- Clock Compensation Control Interface

                    WARN_CC          => warn_cc_i,
                    DO_CC            => do_cc_i,

        -- System Interface

                    DCM_NOT_LOCKED   => dcm_not_locked_i,
                    USER_CLK         => user_clk_i,
                    SYNC_CLK         => sync_clk_i,
                    RESET            => reset_i,
                    POWER_DOWN       => power_down_i,
                    LOOPBACK         => loopback_i,
                    PMA_INIT         => pma_init_r,
                    TX_LOCK          => tx_lock_i,
                    TX_OUT_CLK       => tx_out_clk_i
                 );


    standard_cc_module_i : aurora_201_STANDARD_CC_MODULE

        port map (

        -- Clock Compensation Control Interface

                    WARN_CC        => warn_cc_i,
                    DO_CC          => do_cc_i,

        -- System Interface

                    DCM_NOT_LOCKED => dcm_not_locked_i,
                    USER_CLK       => user_clk_i,
                    CHANNEL_UP     => channel_up_i

                 );



end MAPPED;
