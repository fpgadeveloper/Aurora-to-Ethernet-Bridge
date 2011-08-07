--
--      Project:  Aurora Module Generator version 2.8
--
--         Date:  $Date: 2007/08/08 11:13:33 $
--          Tag:  $Name: i+IP+144838 $
--         File:  $RCSfile: aurora_gtp_vhd.ejava,v $
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
--  aurora_201
--
--
--  Description: This is the top level module for a 1 2-byte lane Aurora
--               reference design module. This module supports the following features:
--
--               * Supports GTP
--

library IEEE;
use IEEE.STD_LOGIC_1164.all;

-- synthesis translate_off

library UNISIM;
use UNISIM.all;

-- synthesis translate_on

entity aurora_201 is
   generic(
           SIM_GTPRESET_SPEEDUP   :integer :=   0      --Set to 1 to speed up sim reset
         );
    port (

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

    --GTP Reference Clock Interface

            GTPD1   : in  std_logic;

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

            DCM_NOT_LOCKED   : in  std_logic;
            USER_CLK         : in  std_logic;
            SYNC_CLK         : in  std_logic;
            RESET            : in  std_logic;
            POWER_DOWN       : in  std_logic;
            LOOPBACK         : in  std_logic_vector(2 downto 0);
            PMA_INIT         : in  std_logic;
            TX_LOCK          : out std_logic;
            TX_OUT_CLK       : out std_logic

         );

end aurora_201;

architecture MAPPED of aurora_201 is

-- Component Declarations --

    component FD

-- synthesis translate_off

        generic (

                    INIT : bit := '0'

                );

-- synthesis translate_on

        port (

                Q : out std_ulogic;
                C : in  std_ulogic;
                D : in  std_ulogic
             );

    end component;


    component aurora_201_AURORA_LANE

        port (

        -- GTP Interface

                RX_DATA           : in std_logic_vector(15 downto 0);  -- 2-byte data bus from the GTP.
                RX_NOT_IN_TABLE   : in std_logic_vector(1 downto 0);   -- Invalid 10-bit code was recieved.
                RX_DISP_ERR       : in std_logic_vector(1 downto 0);   -- Disparity error detected on RX interface.
                RX_CHAR_IS_K      : in std_logic_vector(1 downto 0);   -- Indicates which bytes of RX_DATA are control.
                RX_CHAR_IS_COMMA  : in std_logic_vector(1 downto 0);   -- Comma received on given byte.
                RX_STATUS         : in std_logic_vector(5 downto 0);   -- Part of GTP status and error bus.
                RX_BUF_ERR        : in std_logic;                      -- Overflow/Underflow of RX buffer detected.
                TX_BUF_ERR        : in std_logic;                      -- Overflow/Underflow of TX buffer detected.
                RX_REALIGN        : in std_logic;                      -- SERDES was realigned because of a new comma.
                RX_POLARITY       : out std_logic;                     -- Controls interpreted polarity of serial data inputs.
                RX_RESET          : out std_logic;                     -- Reset RX side of GTP logic.
                TX_CHAR_IS_K      : out std_logic_vector(1 downto 0);  -- TX_DATA byte is a control character.
                TX_DATA           : out std_logic_vector(15 downto 0); -- 2-byte data bus to the GTP.
                TX_RESET          : out std_logic;                     -- Reset TX side of GTP logic.

        -- Comma Detect Phase Align Interface

                ENA_COMMA_ALIGN   : out std_logic;                     -- Request comma alignment.

        -- TX_LL Interface

                GEN_SCP           : in std_logic;                      -- SCP generation request from TX_LL.
                GEN_ECP           : in std_logic;                      -- ECP generation request from TX_LL.
                GEN_PAD           : in std_logic;                      -- PAD generation request from TX_LL.
                TX_PE_DATA        : in std_logic_vector(0 to 15);      -- Data from TX_LL to send over lane.
                TX_PE_DATA_V      : in std_logic;                      -- Indicates TX_PE_DATA is Valid.
                GEN_CC            : in std_logic;                      -- CC generation request from TX_LL.

        -- RX_LL Interface

                RX_PAD            : out std_logic;                     -- Indicates lane received PAD.
                RX_PE_DATA        : out std_logic_vector(0 to 15);     -- RX data from lane to RX_LL.
                RX_PE_DATA_V      : out std_logic;                     -- RX_PE_DATA is data, not control symbol.
                RX_SCP            : out std_logic;                     -- Indicates lane received SCP.
                RX_ECP            : out std_logic;                     -- Indicates lane received ECP.

        -- Global Logic Interface

                GEN_A             : in std_logic;                      -- 'A character' generation request from Global Logic.
                GEN_K             : in std_logic_vector(0 to 1);       -- 'K character' generation request from Global Logic.
                GEN_R             : in std_logic_vector(0 to 1);       -- 'R character' generation request from Global Logic.
                GEN_V             : in std_logic_vector(0 to 1);       -- Verification data generation request.
                LANE_UP           : out std_logic;                     -- Lane is ready for bonding and verification.
                SOFT_ERROR        : out std_logic;                     -- Soft error detected.
                HARD_ERROR        : out std_logic;                     -- Hard error detected.
                CHANNEL_BOND_LOAD : out std_logic;                     -- Channel Bonding done code received.
                GOT_A             : out std_logic_vector(0 to 1);      -- Indicates lane recieved 'A character' bytes.
                GOT_V             : out std_logic;                     -- Verification symbols received.

        -- System Interface

                USER_CLK          : in std_logic;                      -- System clock for all non-GTP Aurora Logic.
                RESET             : in std_logic                       -- Reset the lane.

             );

    end component;



    component aurora_201_GTP_WRAPPER
       generic(
                SIM_GTPRESET_SPEEDUP   :integer :=   0      --Set to 1 to speed up sim reset
              );
        port  (
                ENCHANSYNC_IN           : in    std_logic;
                ENMCOMMAALIGN_IN        : in    std_logic;
                ENPCOMMAALIGN_IN        : in    std_logic;
                REFCLK                  : in    std_logic;
                LOOPBACK_IN             : in    std_logic_vector (2 downto 0);
                POWERDOWN_IN            : in    std_logic;
                RXPOLARITY_IN           : in    std_logic;
                RXRESET_IN              : in    std_logic;
                RXUSRCLK_IN             : in    std_logic;
                RXUSRCLK2_IN            : in    std_logic;
                RX1N_IN                 : in    std_logic;
                RX1P_IN                 : in    std_logic;
                TXCHARISK_IN            : in    std_logic_vector (1 downto 0);
                TXDATA_IN               : in    std_logic_vector (15 downto 0);
                GTPRESET_IN                                     : in    std_logic;
                TXRESET_IN              : in    std_logic;
                TXUSRCLK_IN             : in    std_logic;
                TXUSRCLK2_IN            : in    std_logic;
                RXBUFERR_OUT            : out   std_logic;
                RXCHARISCOMMA_OUT       : out   std_logic_vector (1 downto 0);
                RXCHARISK_OUT           : out   std_logic_vector (1 downto 0);
                RXDATA_OUT              : out   std_logic_vector (15 downto 0);
                RXDISPERR_OUT           : out   std_logic_vector (1 downto 0);
                RXNOTINTABLE_OUT        : out   std_logic_vector (1 downto 0);
                RXREALIGN_OUT           : out   std_logic;
                RXRECCLK1_OUT           : out   std_logic;
                RXRECCLK2_OUT           : out   std_logic;
                CHBONDDONE_OUT          : out   std_logic;
                TXBUFERR_OUT            : out   std_logic;
                PLLLKDET_OUT            : out   std_logic;
                TXOUTCLK1_OUT           : out   std_logic;
                TXOUTCLK2_OUT           : out   std_logic;
                TX1N_OUT                : out   std_logic;
                TX1P_OUT                : out   std_logic
             );

    end component;


    component BUFG

        port (

                O : out STD_ULOGIC;
                I : in STD_ULOGIC

             );

    end component;


    component aurora_201_GLOBAL_LOGIC

        port (

        -- GTP Interface

                CH_BOND_DONE       : in std_logic;
                EN_CHAN_SYNC       : out std_logic;

        -- Aurora Lane Interface

                LANE_UP            : in std_logic;
                SOFT_ERROR         : in std_logic;
                HARD_ERROR         : in std_logic;
                CHANNEL_BOND_LOAD  : in std_logic;
                GOT_A              : in std_logic_vector(0 to 1);
                GOT_V              : in std_logic;
                GEN_A              : out std_logic;
                GEN_K              : out std_logic_vector(0 to 1);
                GEN_R              : out std_logic_vector(0 to 1);
                GEN_V              : out std_logic_vector(0 to 1);
                RESET_LANES        : out std_logic;

        -- System Interface

                USER_CLK           : in std_logic;
                RESET              : in std_logic;
                POWER_DOWN         : in std_logic;
                CHANNEL_UP         : out std_logic;
                START_RX           : out std_logic;
                CHANNEL_SOFT_ERROR : out std_logic;
                CHANNEL_HARD_ERROR : out std_logic

             );

    end component;


    component aurora_201_TX_LL

        port (

        -- LocalLink PDU Interface

                TX_D           : in std_logic_vector(0 to 15);
                TX_REM         : in std_logic;
                TX_SRC_RDY_N   : in std_logic;
                TX_SOF_N       : in std_logic;
                TX_EOF_N       : in std_logic;
                TX_DST_RDY_N   : out std_logic;

        -- Clock Compensation Interface

                WARN_CC        : in std_logic;
                DO_CC          : in std_logic;

        -- Global Logic Interface

                CHANNEL_UP     : in std_logic;

        -- Aurora Lane Interface

                GEN_SCP        : out std_logic;
                GEN_ECP        : out std_logic;
                TX_PE_DATA_V   : out std_logic;
                GEN_PAD        : out std_logic;
                TX_PE_DATA     : out std_logic_vector(0 to 15);
                GEN_CC         : out std_logic;

        -- System Interface

                USER_CLK       : in std_logic

             );

    end component;


    component aurora_201_RX_LL

        port (

        -- LocalLink PDU Interface

                RX_D             : out std_logic_vector(0 to 15);
                RX_REM           : out std_logic;
                RX_SRC_RDY_N     : out std_logic;
                RX_SOF_N         : out std_logic;
                RX_EOF_N         : out std_logic;

        -- Global Logic Interface

                START_RX         : in std_logic;

        -- Aurora Lane Interface

                RX_PAD           : in std_logic;
                RX_PE_DATA       : in std_logic_vector(0 to 15);
                RX_PE_DATA_V     : in std_logic;
                RX_SCP           : in std_logic;
                RX_ECP           : in std_logic;

        -- Error Interface

                FRAME_ERROR      : out std_logic;

        -- System Interface

                USER_CLK         : in std_logic

             );

    end component;

-- Wire Declarations --
    signal ch_bond_done_i           : std_logic;
    signal ch_bond_load_not_used_i  : std_logic;
    signal channel_bond_load_i      : std_logic;
    signal channel_up_i             : std_logic;
    signal chbondi_not_used_i       : std_logic_vector(4 downto 0);
    signal chbondo_not_used_i       : std_logic_vector(4 downto 0);
    signal en_chan_sync_i           : std_logic;
    signal ena_comma_align_i        : std_logic;
    signal gen_a_i                  : std_logic;
    signal gen_cc_i                 : std_logic;
    signal gen_ecp_i                : std_logic;
    signal gen_k_i                  : std_logic_vector(0 to 1);
    signal gen_pad_i                : std_logic;
    signal gen_r_i                  : std_logic_vector(0 to 1);
    signal gen_scp_i                : std_logic;
    signal gen_v_i                  : std_logic_vector(0 to 1);
    signal got_a_i                  : std_logic_vector(0 to 1);
    signal got_v_i                  : std_logic;
    signal hard_error_i             : std_logic;
    signal lane_up_i                : std_logic;
    signal master_chbondo_i         : std_logic;
    signal open_rx_char_is_comma_i  : std_logic_vector(5 downto 0);
    signal open_rx_char_is_k_i      : std_logic_vector(5 downto 0);
    signal open_rx_comma_det_i      : std_logic;
    signal open_rx_data_i           : std_logic_vector(47 downto 0);
    signal open_rx_disp_err_i       : std_logic_vector(5 downto 0);
    signal open_rx_loss_of_sync_i   : std_logic_vector(1 downto 0);
    signal open_rx_not_in_table_i   : std_logic_vector(5 downto 0);
    signal open_rx_rec1_clk_i       : std_logic;
    signal open_rx_rec2_clk_i       : std_logic;
    signal open_rx_run_disp_i       : std_logic_vector(7 downto 0);
    signal open_tx_k_err_i          : std_logic_vector(7 downto 0);
    signal open_tx_run_disp_i       : std_logic_vector(7 downto 0);
    signal raw_tx_out_clk_i         : std_logic;
    signal reset_lanes_i            : std_logic;
    signal rx_buf_err_i             : std_logic;
    signal rx_char_is_comma_i       : std_logic_vector(1 downto 0);
    signal rx_char_is_comma_gtp_i   : std_logic_vector(7 downto 0);
    signal rx_char_is_k_i           : std_logic_vector(1 downto 0);
    signal rx_char_is_k_gtp_i       : std_logic_vector(7 downto 0);
    signal rx_clk_cor_cnt_i         : std_logic_vector(2 downto 0);
    signal rx_data_0_vec    : std_logic_vector(63 downto 0);
    signal rx_data_i                : std_logic_vector(15 downto 0);
    signal rx_data_gtp_i            : std_logic_vector(63 downto 0);
    signal rx_data_width_i          : std_logic_vector(1 downto 0);
    signal rx_disp_err_i            : std_logic_vector(1 downto 0);
    signal rx_disp_err_gtp_i        : std_logic_vector(7 downto 0);
    signal rx_ecp_i                 : std_logic;
    signal rx_int_data_width_i      : std_logic_vector(1 downto 0);
    signal rx_not_in_table_i        : std_logic_vector(1 downto 0);
    signal rx_not_in_table_gtp_i    : std_logic_vector(7 downto 0);
    signal rx_pad_i                 : std_logic;
    signal rx_pe_data_i             : std_logic_vector(0 to 15);
    signal rx_pe_data_v_i           : std_logic;
    signal rx_polarity_i            : std_logic;
    signal rx_realign_i             : std_logic;
    signal rx_reset_i               : std_logic;
    signal rx_scp_i                 : std_logic;
    signal rxchariscomma_0_vec      : std_logic_vector(7 downto 0);
    signal rxcharisk_0_vec          : std_logic_vector(7 downto 0);
    signal rxdisperr_0_vec          : std_logic_vector(7 downto 0);
    signal rxmclk_out_not_used_i    : std_logic;
    signal rxnotintable_0_vec       : std_logic_vector(7 downto 0);
    signal rxpcshclkout_not_used_i  : std_logic;
    signal soft_error_i             : std_logic;
    signal start_rx_i               : std_logic;
    signal system_reset_c           : std_logic;
    signal tied_to_ground_i         : std_logic;
    signal tied_to_ground_vec_i     : std_logic_vector(47 downto 0);
    signal tied_to_vcc_i            : std_logic;
    signal tx_buf_err_i             : std_logic;
    signal tx_char_is_k_i           : std_logic_vector(1 downto 0);
    signal tx_char_is_k_gtp_i       : std_logic_vector(7 downto 0);
    signal tx_data_i                : std_logic_vector(15 downto 0);
    signal tx_data_gtp_i            : std_logic_vector(63 downto 0);
    signal tx_data_width_i          : std_logic_vector(1 downto 0);
    signal tx_int_data_width_i      : std_logic_vector(1 downto 0);
    signal tx_lock_i                :   std_logic;
    signal tx_pe_data_i             : std_logic_vector(0 to 15);
    signal tx_pe_data_v_i           : std_logic;
    signal tx_reset_i               : std_logic;
    signal txcharisk_lane_0_i       : std_logic_vector(7 downto 0);
    signal txdata_lane_0_i          : std_logic_vector(63 downto 0);
    signal txoutclk2_out_not_used_i : std_logic;
    signal txpcshclkout_not_used_i  : std_logic;

begin

-- Main Body of Code --

    -- Tie off top level constants

    tied_to_ground_vec_i <= (others => '0');
    tied_to_ground_i     <= '0';
    tied_to_vcc_i        <= '1';
    chbondi_not_used_i   <= (others => '0');

    -- Connect top level logic

    CHANNEL_UP           <=  channel_up_i;
    system_reset_c       <=  RESET or DCM_NOT_LOCKED  or not tx_lock_i ;

    -- Set the data widths for all lanes

    rx_data_width_i      <= "01";
    rx_int_data_width_i  <= "01";
    tx_data_width_i      <= "01";
    tx_int_data_width_i  <= "01";

    -- Connect the TXOUTCLK of lane 0 to TX_OUT_CLK

    TX_OUT_CLK <= raw_tx_out_clk_i;
    
    
    -- Connect TX_LOCK to tx_lock_i from lane 0
    TX_LOCK    <=   tx_lock_i;      
    

    -- Instantiate Lane 0 --

    LANE_UP <=   lane_up_i;

    aurora_lane_0_i : aurora_201_AURORA_LANE

        port map (

        -- GTP Interface

                    RX_DATA             => rx_data_i(15 downto 0),
                    RX_NOT_IN_TABLE     => rx_not_in_table_i(1 downto 0),
                    RX_DISP_ERR         => rx_disp_err_i(1 downto 0),
                    RX_CHAR_IS_K        => rx_char_is_k_i(1 downto 0),
                    RX_CHAR_IS_COMMA    => rx_char_is_comma_i(1 downto 0),
                    RX_STATUS           => tied_to_ground_vec_i(5 downto 0),
                    TX_BUF_ERR          => tx_buf_err_i,
                    RX_BUF_ERR          => rx_buf_err_i,
                    RX_REALIGN          => rx_realign_i,
                    RX_POLARITY         => rx_polarity_i,
                    RX_RESET            => rx_reset_i,
                    TX_CHAR_IS_K        => tx_char_is_k_i(1 downto 0),
                    TX_DATA             => tx_data_i(15 downto 0),
                    TX_RESET            => tx_reset_i,

        -- Comma Detect Phase Align Interface

                    ENA_COMMA_ALIGN     => ena_comma_align_i,

        -- TX_LL Interface
                    GEN_SCP             => gen_scp_i,
                    GEN_ECP             => gen_ecp_i,
                    GEN_PAD             => gen_pad_i,
                    TX_PE_DATA          => tx_pe_data_i(0 to 15),
                    TX_PE_DATA_V        => tx_pe_data_v_i,
                    GEN_CC              => gen_cc_i,

        -- RX_LL Interface

                    RX_PAD              => rx_pad_i,
                    RX_PE_DATA          => rx_pe_data_i(0 to 15),
                    RX_PE_DATA_V        => rx_pe_data_v_i,
                    RX_SCP              => rx_scp_i,
                    RX_ECP              => rx_ecp_i,

        -- Global Logic Interface

                    GEN_A               => gen_a_i,
                    GEN_K               => gen_k_i(0 to 1),
                    GEN_R               => gen_r_i(0 to 1),
                    GEN_V               => gen_v_i(0 to 1),
                    LANE_UP             => lane_up_i,
                    SOFT_ERROR          => soft_error_i,
                    HARD_ERROR          => hard_error_i,
                    CHANNEL_BOND_LOAD   => ch_bond_load_not_used_i,
                    GOT_A               => got_a_i(0 to 1),
                    GOT_V               => got_v_i,

        -- System Interface

                    USER_CLK            => USER_CLK,
                    RESET               => reset_lanes_i

                 );


    -- Instantiate GTP Wrapper --

    gtp_wrapper_i : aurora_201_GTP_WRAPPER
        generic map(
                     SIM_GTPRESET_SPEEDUP  => SIM_GTPRESET_SPEEDUP
                   )
        port map   (

        -- Aurora Lane Interface

                    RXPOLARITY_IN           => rx_polarity_i,
                    RXRESET_IN              => rx_reset_i,
                    TXCHARISK_IN            => tx_char_is_k_i(1 downto 0),
                    TXDATA_IN               => tx_data_i(15 downto 0),
                    TXRESET_IN              => tx_reset_i,
                    RXDATA_OUT              => rx_data_i(15 downto 0),
                    RXNOTINTABLE_OUT        => rx_not_in_table_i(1 downto 0),
                    RXDISPERR_OUT           => rx_disp_err_i(1 downto 0),
                    RXCHARISK_OUT           => rx_char_is_k_i(1 downto 0),
                    RXCHARISCOMMA_OUT       => rx_char_is_comma_i(1 downto 0),
                    TXBUFERR_OUT            => tx_buf_err_i,
                    RXBUFERR_OUT            => rx_buf_err_i,
                    RXREALIGN_OUT           => rx_realign_i,

        -- Phase Align Interface

                    ENMCOMMAALIGN_IN        => ena_comma_align_i,
                    ENPCOMMAALIGN_IN        => ena_comma_align_i,
                    RXRECCLK1_OUT           => open_rx_rec1_clk_i,  
                    RXRECCLK2_OUT           => open_rx_rec2_clk_i,  
        -- Global Logic Interface

                    ENCHANSYNC_IN           => en_chan_sync_i,
                    CHBONDDONE_OUT          => ch_bond_done_i,

        -- Serial IO

                    RX1N_IN       => RXN,
                    RX1P_IN       => RXP,
                    TX1N_OUT      => TXN,
                    TX1P_OUT      => TXP,


        -- Reference Clocks and User Clock

                    RXUSRCLK_IN             => SYNC_CLK,
                    RXUSRCLK2_IN            => USER_CLK,
                    TXUSRCLK_IN             => SYNC_CLK,
                    TXUSRCLK2_IN            => USER_CLK,

                    REFCLK                  =>  GTPD1,

                    TXOUTCLK1_OUT           => raw_tx_out_clk_i,

                    TXOUTCLK2_OUT           => txoutclk2_out_not_used_i,    
                    PLLLKDET_OUT            => tx_lock_i,       

        -- System Interface


                    GTPRESET_IN                                    => PMA_INIT,                      LOOPBACK_IN                                    => LOOPBACK,
                    POWERDOWN_IN                                   => POWER_DOWN

                 );


       -- Instantiate Global Logic to combine Lanes into a Channel --

    global_logic_i : aurora_201_GLOBAL_LOGIC

        port map (

        -- GTP Interface

                    CH_BOND_DONE            => ch_bond_done_i,
                    EN_CHAN_SYNC            => en_chan_sync_i,

        -- Aurora Lane Interface

                    LANE_UP                 => lane_up_i,
                    SOFT_ERROR              => soft_error_i,
                    HARD_ERROR              => hard_error_i,
                    CHANNEL_BOND_LOAD       => ch_bond_done_i,
                    GOT_A                   => got_a_i,
                    GOT_V                   => got_v_i,
                    GEN_A                   => gen_a_i,
                    GEN_K                   => gen_k_i,
                    GEN_R                   => gen_r_i,
                    GEN_V                   => gen_v_i,
                    RESET_LANES             => reset_lanes_i,

        -- System Interface

                    USER_CLK                => USER_CLK,
                    RESET                   => system_reset_c,
                    POWER_DOWN              => POWER_DOWN,
                    CHANNEL_UP              => channel_up_i,
                    START_RX                => start_rx_i,
                    CHANNEL_SOFT_ERROR      => SOFT_ERROR,
                    CHANNEL_HARD_ERROR      => HARD_ERROR

                 );


    -- Instantiate TX_LL --

    tx_ll_i : aurora_201_TX_LL

        port map (

        -- LocalLink PDU Interface

                    TX_D                    => TX_D,
                    TX_REM                  => TX_REM,
                    TX_SRC_RDY_N            => TX_SRC_RDY_N,
                    TX_SOF_N                => TX_SOF_N,
                    TX_EOF_N                => TX_EOF_N,
                    TX_DST_RDY_N            => TX_DST_RDY_N,

        -- Clock Compenstaion Interface

                    WARN_CC                 => WARN_CC,
                    DO_CC                   => DO_CC,

        -- Global Logic Interface

                    CHANNEL_UP              => channel_up_i,

        -- Aurora Lane Interface

                    GEN_SCP                 => gen_scp_i,
                    GEN_ECP                 => gen_ecp_i,
                    TX_PE_DATA_V            => tx_pe_data_v_i,
                    GEN_PAD                 => gen_pad_i,
                    TX_PE_DATA              => tx_pe_data_i,
                    GEN_CC                  => gen_cc_i,

        -- System Interface

                    USER_CLK                => USER_CLK

                 );


    -- Instantiate RX_LL --

    rx_ll_i : aurora_201_RX_LL

        port map (

        -- LocalLink PDU Interface

                    RX_D             => RX_D,
                    RX_REM           => RX_REM,
                    RX_SRC_RDY_N     => RX_SRC_RDY_N,
                    RX_SOF_N         => RX_SOF_N,
                    RX_EOF_N         => RX_EOF_N,

        -- Global Logic Interface

                    START_RX         => start_rx_i,

        -- Aurora Lane Interface

                    RX_PAD           => rx_pad_i,
                    RX_PE_DATA       => rx_pe_data_i,
                    RX_PE_DATA_V     => rx_pe_data_v_i,
                    RX_SCP           => rx_scp_i,
                    RX_ECP           => rx_ecp_i,

        -- Error Interface

                    FRAME_ERROR      => FRAME_ERROR,

        -- System Interface

                    USER_CLK         => USER_CLK

                 );

end MAPPED;
