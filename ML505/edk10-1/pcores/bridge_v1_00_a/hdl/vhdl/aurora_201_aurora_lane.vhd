------------------------------------------------------------------------------
--
--      Project:  Aurora Module Generator version 2.8
--
--         Date:  $Date: 2007/08/08 11:13:33 $
--          Tag:  $Name: i+IP+144838 $
--         File:  $RCSfile: aurora_lane_gtp_vhd.ejava,v $
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
--  AURORA_LANE
--
--
--                    Xilinx - Garden Valley Design Team
--
--  Description: The AURORA_LANE module provides a full duplex 2-byte aurora
--               lane connection using a single GTP.  The module handles lane
--               initialization, symbol generation and decoding as well as
--               error detection.  It also decodes some of the channel bonding
--               indicator signals needed by the Global logic.
--
--               * Supports GTP
--

library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity aurora_201_AURORA_LANE is
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

end aurora_201_AURORA_LANE;

architecture MAPPED of aurora_201_AURORA_LANE is

-- External Register Declarations --

    signal RX_POLARITY_Buffer       : std_logic;
    signal RX_RESET_Buffer          : std_logic;
    signal TX_CHAR_IS_K_Buffer      : std_logic_vector(1 downto 0);
    signal TX_DATA_Buffer           : std_logic_vector(15 downto 0);
    signal TX_RESET_Buffer          : std_logic;
    signal ENA_COMMA_ALIGN_Buffer   : std_logic;
    signal RX_PAD_Buffer            : std_logic;
    signal RX_PE_DATA_Buffer        : std_logic_vector(0 to 15);
    signal RX_PE_DATA_V_Buffer      : std_logic;
    signal RX_SCP_Buffer            : std_logic;
    signal RX_ECP_Buffer            : std_logic;
    signal LANE_UP_Buffer           : std_logic;
    signal SOFT_ERROR_Buffer        : std_logic;
    signal HARD_ERROR_Buffer        : std_logic;
    signal CHANNEL_BOND_LOAD_Buffer : std_logic;
    signal GOT_A_Buffer             : std_logic_vector(0 to 1);
    signal GOT_V_Buffer             : std_logic;

-- Wire Declarations --

    signal gen_k_i                  : std_logic;
    signal gen_sp_data_i            : std_logic_vector(0 to 1);
    signal gen_spa_data_i           : std_logic_vector(0 to 1);
    signal rx_sp_i                  : std_logic;
    signal rx_spa_i                 : std_logic;
    signal rx_neg_i                 : std_logic;
    signal enable_error_detect_i    : std_logic;
    signal do_word_align_i          : std_logic;
    signal hard_error_reset_i       : std_logic;

    signal tx_char_is_k_i           : std_logic_vector(1 downto 0);
    signal tx_data_buffer_i         : std_logic_vector(15 downto 0);
    signal rx_data_i                : std_logic_vector(15 downto 0);
    signal rx_char_is_k_i           : std_logic_vector(1 downto 0);
    signal rx_char_is_comma_i       : std_logic_vector(1 downto 0);
    signal rx_disp_err_i            : std_logic_vector(1 downto 0);
    signal rx_not_in_table_i        : std_logic_vector(1 downto 0);

-- Component Declarations --

    component aurora_201_LANE_INIT_SM

        port (

        -- GTP Interface

                RX_NOT_IN_TABLE     : in std_logic_vector(1 downto 0);  -- GTP received invalid 10b code.
                RX_DISP_ERR         : in std_logic_vector(1 downto 0);  -- GTP received 10b code w/ wrong disparity.
                RX_CHAR_IS_COMMA    : in std_logic_vector(1 downto 0);  -- GTP received a Comma.
                RX_REALIGN          : in std_logic;                     -- GTP had to change alignment due to new comma.
                RX_RESET            : out std_logic;                    -- Reset the RX side of the GTP.
                TX_RESET            : out std_logic;                    -- Reset the TX side of the GTP.
                RX_POLARITY         : out std_logic;                    -- Sets polarity used to interpet rx'ed symbols.

        -- Comma Detect Phase Alignment Interface

                ENA_COMMA_ALIGN     : out std_logic;                    -- Turn on SERDES Alignment in GTP.

        -- Symbol Generator Interface

                GEN_K               : out std_logic;                    -- Generate a comma on the MSByte of the Lane.
                GEN_SP_DATA         : out std_logic_vector(0 to 1);     -- Generate SP data symbol on selected byte(s).
                GEN_SPA_DATA        : out std_logic_vector(0 to 1);     -- Generate SPA data symbol on selected byte(s).

        -- Symbol Decoder Interface

                RX_SP               : in std_logic;                     -- Lane rx'ed SP sequence w/ + or - data.
                RX_SPA              : in std_logic;                     -- Lane rx'ed SPA sequence.
                RX_NEG              : in std_logic;                     -- Lane rx'ed inverted SP or SPA data.
                DO_WORD_ALIGN       : out std_logic;                    -- Enable word alignment.

        -- Error Detection Logic Interface

                ENABLE_ERROR_DETECT : out std_logic;                    -- Turn on Soft Error detection.
                HARD_ERROR_RESET    : in std_logic;                     -- Reset lane due to hard error.

        -- Global Logic Interface

                LANE_UP             : out std_logic;                    -- Lane is initialized.

        -- System Interface

                USER_CLK            : in std_logic;                     -- Clock for all non-GTP Aurora logic.
                RESET               : in std_logic                      -- Reset Aurora Lane.

             );

    end component;


    component aurora_201_CHBOND_COUNT_DEC

        port (

                RX_STATUS         : in  std_logic_vector(5 downto 0);
                CHANNEL_BOND_LOAD : out std_logic;
                USER_CLK          : in  std_logic

             );

    end component;


    component aurora_201_SYM_GEN

        port (

        -- TX_LL Interface                                        -- See description for info about GEN_PAD and TX_PE_DATA_V.

                GEN_SCP      : in std_logic;                      -- Generate SCP.
                GEN_ECP      : in std_logic;                      -- Generate ECP.
                GEN_PAD      : in std_logic;                      -- Replace LSB with Pad character.
                TX_PE_DATA   : in std_logic_vector(0 to 15);      -- Data.  Transmitted when TX_PE_DATA_V is asserted.
                TX_PE_DATA_V : in std_logic;                      -- Transmit data.
                GEN_CC       : in std_logic;                      -- Generate Clock Correction symbols.

        -- Global Logic Interface                                 -- See description for info about GEN_K,GEN_R and GEN_A.

                GEN_A        : in std_logic;                      -- Generate A character for selected bytes.
                GEN_K        : in std_logic_vector(0 to 1);       -- Generate K character for selected bytes.
                GEN_R        : in std_logic_vector(0 to 1);       -- Generate R character for selected bytes.
                GEN_V        : in std_logic_vector(0 to 1);       -- Generate Ver data character on selected bytes.

        -- Lane Init SM Interface

                GEN_K_FSM    : in std_logic;                      -- Generate K character on byte 0.
                GEN_SP_DATA  : in std_logic_vector(0 to 1);       -- Generate SP data character on selected bytes.
                GEN_SPA_DATA : in std_logic_vector(0 to 1);       -- Generate SPA data character on selected bytes.

        -- GTP Interface

                TX_CHAR_IS_K : out std_logic_vector(1 downto 0);  -- Transmit TX_DATA as a control character.
                TX_DATA      : out std_logic_vector(15 downto 0); -- Data to GTP for transmission to channel partner.

        -- System Interface

                USER_CLK     : in std_logic                       -- Clock for all non-GTP Aurora Logic.

             );

    end component;


    component aurora_201_SYM_DEC

        port (

        -- RX_LL Interface

                RX_PAD           : out std_logic;                    -- LSByte is PAD.
                RX_PE_DATA       : out std_logic_vector(0 to 15);    -- Word aligned data from channel partner.
                RX_PE_DATA_V     : out std_logic;                    -- Data is valid data and not a control character.
                RX_SCP           : out std_logic;                    -- SCP symbol received.
                RX_ECP           : out std_logic;                    -- ECP symbol received.

        -- Lane Init SM Interface

                DO_WORD_ALIGN    : in std_logic;                     -- Word alignment is allowed.
                RX_SP            : out std_logic;                    -- SP sequence received with positive or negative data.
                RX_SPA           : out std_logic;                    -- SPA sequence received.
                RX_NEG           : out std_logic;                    -- Intverted data for SP or SPA received.

        -- Global Logic Interface

                GOT_A            : out std_logic_vector(0 to 1);     -- A character received on indicated byte(s).
                GOT_V            : out std_logic;                    -- V sequence received.

        -- GTP Interface

                RX_DATA          : in std_logic_vector(15 downto 0); -- Raw RX data from GTP.
                RX_CHAR_IS_K     : in std_logic_vector(1 downto 0);  -- Bits indicating which bytes are control characters.
                RX_CHAR_IS_COMMA : in std_logic_vector(1 downto 0);  -- Rx'ed a comma.

        -- System Interface

                USER_CLK         : in std_logic;                     -- System clock for all non-GTP Aurora Logic.
                RESET            : in std_logic

             );

    end component;


    component aurora_201_ERROR_DETECT

        port (

        -- Lane Init SM Interface

                ENABLE_ERROR_DETECT : in std_logic;
                HARD_ERROR_RESET    : out std_logic;

        -- Global Logic Interface

                SOFT_ERROR          : out std_logic;
                HARD_ERROR          : out std_logic;

        -- GTP Interface

                RX_DISP_ERR         : in std_logic_vector(1 downto 0);
                RX_NOT_IN_TABLE     : in std_logic_vector(1 downto 0);
                RX_BUF_ERR          : in std_logic;
                TX_BUF_ERR          : in std_logic;
                RX_REALIGN          : in std_logic;

        -- System Interface

                USER_CLK            : in std_logic

             );

    end component;

begin

    RX_POLARITY         <= RX_POLARITY_Buffer;
    RX_RESET            <= RX_RESET_Buffer;
    TX_CHAR_IS_K        <= TX_CHAR_IS_K_Buffer;
    TX_DATA             <= TX_DATA_Buffer;
    TX_RESET            <= TX_RESET_Buffer;
    ENA_COMMA_ALIGN     <= ENA_COMMA_ALIGN_Buffer;
    RX_PAD              <= RX_PAD_Buffer;
    RX_PE_DATA          <= RX_PE_DATA_Buffer;
    RX_PE_DATA_V        <= RX_PE_DATA_V_Buffer;
    RX_SCP              <= RX_SCP_Buffer;
    RX_ECP              <= RX_ECP_Buffer;
    LANE_UP             <= LANE_UP_Buffer;
    SOFT_ERROR          <= SOFT_ERROR_Buffer;
    HARD_ERROR          <= HARD_ERROR_Buffer;
    CHANNEL_BOND_LOAD   <= CHANNEL_BOND_LOAD_Buffer;
    GOT_A               <= GOT_A_Buffer;
    GOT_V               <= GOT_V_Buffer;


-- Main Body of Code --

    -- Buffers for twisting data from ProX --

    -- GTP GTPs order their data in the opposite direction from Pro GTPs. To reuse the
    -- Pro Aurora logic, we twist the data to make it compatible.

    TX_CHAR_IS_K_Buffer(0)      <=  tx_char_is_k_i(1);
    TX_CHAR_IS_K_Buffer(1)      <=  tx_char_is_k_i(0);
    TX_DATA_Buffer(7 downto 0)  <=  tx_data_buffer_i(15 downto 8);
    TX_DATA_Buffer(15 downto 8) <=  tx_data_buffer_i(7 downto 0);

    rx_data_i                   <=  RX_DATA(7 downto 0) & RX_DATA(15 downto 8);
    rx_char_is_k_i              <=  RX_CHAR_IS_K(0) & RX_CHAR_IS_K(1);
    rx_char_is_comma_i          <=  RX_CHAR_IS_COMMA(0) & RX_CHAR_IS_COMMA(1);
    rx_disp_err_i               <=  RX_DISP_ERR(0) & RX_DISP_ERR(1);
    rx_not_in_table_i           <=  RX_NOT_IN_TABLE(0) & RX_NOT_IN_TABLE(1);


    -- Lane Initialization state machine

    lane_init_sm_i : aurora_201_LANE_INIT_SM

        port map (

        -- GTP Interface

                    RX_NOT_IN_TABLE     => RX_NOT_IN_TABLE,
                    RX_DISP_ERR         => RX_DISP_ERR,
                    RX_CHAR_IS_COMMA    => RX_CHAR_IS_COMMA,
                    RX_REALIGN          => RX_REALIGN,

                    RX_RESET            => RX_RESET_Buffer,
                    TX_RESET            => TX_RESET_Buffer,
                    RX_POLARITY         => RX_POLARITY_Buffer,

        -- Comma Detect Phase Alignment Interface

                    ENA_COMMA_ALIGN     => ENA_COMMA_ALIGN_Buffer,

        -- Symbol Generator Interface

                    GEN_K               => gen_k_i,
                    GEN_SP_DATA         => gen_sp_data_i,
                    GEN_SPA_DATA        => gen_spa_data_i,

        -- Symbol Decoder Interface

                    RX_SP               => rx_sp_i,
                    RX_SPA              => rx_spa_i,
                    RX_NEG              => rx_neg_i,

                    DO_WORD_ALIGN       => do_word_align_i,

        -- Error Detection Logic Interface

                    HARD_ERROR_RESET    => hard_error_reset_i,
                    ENABLE_ERROR_DETECT => enable_error_detect_i,

        -- Global Logic Interface

                    LANE_UP             => LANE_UP_Buffer,

        -- System Interface

                    USER_CLK            => USER_CLK,
                    RESET               => RESET

                 );


    -- Channel Bonding Count Decode module

    chbond_count_dec_i : aurora_201_CHBOND_COUNT_DEC

        port map (

                    RX_STATUS         => RX_STATUS,
                    CHANNEL_BOND_LOAD => CHANNEL_BOND_LOAD_Buffer,
                    USER_CLK          => USER_CLK

                 );


    -- Symbol Generation module

    sym_gen_i : aurora_201_SYM_GEN

        port map (

        -- TX_LL Interface

                    GEN_SCP      => GEN_SCP,
                    GEN_ECP      => GEN_ECP,
                    GEN_PAD      => GEN_PAD,
                    TX_PE_DATA   => TX_PE_DATA,
                    TX_PE_DATA_V => TX_PE_DATA_V,
                    GEN_CC       => GEN_CC,

        -- Global Logic Interface

                    GEN_A        => GEN_A,
                    GEN_K        => GEN_K,
                    GEN_R        => GEN_R,
                    GEN_V        => GEN_V,

        -- Lane Init SM Interface

                    GEN_K_FSM    => gen_k_i,
                    GEN_SP_DATA  => gen_sp_data_i,
                    GEN_SPA_DATA => gen_spa_data_i,

        -- GTP Interface

                    TX_CHAR_IS_K => tx_char_is_k_i,
                    TX_DATA      => tx_data_buffer_i,

        -- System Interface

                    USER_CLK     => USER_CLK

                 );


    -- Symbol Decode module

    sym_dec_i : aurora_201_SYM_DEC

        port map (

        -- RX_LL Interface

                    RX_PAD           => RX_PAD_Buffer,
                    RX_PE_DATA       => RX_PE_DATA_Buffer,
                    RX_PE_DATA_V     => RX_PE_DATA_V_Buffer,
                    RX_SCP           => RX_SCP_Buffer,
                    RX_ECP           => RX_ECP_Buffer,

        -- Lane Init SM Interface

                    DO_WORD_ALIGN    => do_word_align_i,
                    RX_SP            => rx_sp_i,
                    RX_SPA           => rx_spa_i,
                    RX_NEG           => rx_neg_i,

        -- Global Logic Interface

                    GOT_A            => GOT_A_Buffer,
                    GOT_V            => GOT_V_Buffer,

        -- GTP Interface

                    RX_DATA          => rx_data_i,
                    RX_CHAR_IS_K     => rx_char_is_k_i,
                    RX_CHAR_IS_COMMA => rx_char_is_comma_i,

        -- System Interface

                    USER_CLK         => USER_CLK,
                    RESET            => RESET

                 );


    -- Error Detection module

    error_detect_i : aurora_201_ERROR_DETECT

        port map (

        -- Lane Init SM Interface

                    ENABLE_ERROR_DETECT => enable_error_detect_i,
                    HARD_ERROR_RESET    => hard_error_reset_i,

        -- Global Logic Interface

                    SOFT_ERROR          => SOFT_ERROR_Buffer,
                    HARD_ERROR          => HARD_ERROR_Buffer,

        -- GTP Interface

                    RX_DISP_ERR         => rx_disp_err_i,
                    RX_NOT_IN_TABLE     => rx_not_in_table_i,
                    RX_BUF_ERR          => RX_BUF_ERR,
                    TX_BUF_ERR          => TX_BUF_ERR,
                    RX_REALIGN          => RX_REALIGN,

        -- System Interface

                    USER_CLK            => USER_CLK

                 );

end MAPPED;
