--
--      Project:  Aurora Module Generator version 2.8
--
--         Date:  $Date: 2007/08/08 11:13:33 $
--          Tag:  $Name: i+IP+144838 $
--         File:  $RCSfile: global_logic_vhd.ejava,v $
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
--  GLOBAL_LOGIC
--
--
--                    Xilinx - Garden Valley Design Team
--
--  Description: The GLOBAL_LOGIC module handles channel bonding, channel
--               verification, channel error manangement and idle generation.
--
--               This module supports 1 2-byte lane designs
--

library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity aurora_201_GLOBAL_LOGIC is

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

end aurora_201_GLOBAL_LOGIC;

architecture MAPPED of aurora_201_GLOBAL_LOGIC is

-- External Register Declarations --

    signal EN_CHAN_SYNC_Buffer       : std_logic;
    signal GEN_A_Buffer              : std_logic;
    signal GEN_K_Buffer              : std_logic_vector(0 to 1);
    signal GEN_R_Buffer              : std_logic_vector(0 to 1);
    signal GEN_V_Buffer              : std_logic_vector(0 to 1);
    signal RESET_LANES_Buffer        : std_logic;
    signal CHANNEL_UP_Buffer         : std_logic;
    signal START_RX_Buffer           : std_logic;
    signal CHANNEL_SOFT_ERROR_Buffer : std_logic;
    signal CHANNEL_HARD_ERROR_Buffer : std_logic;

-- Wire Declarations --

    signal gen_ver_i       : std_logic;
    signal reset_channel_i : std_logic;
    signal did_ver_i       : std_logic;

-- Component Declarations --

    component aurora_201_CHANNEL_INIT_SM

        port (

        -- GTP Interface

                CH_BOND_DONE      : in std_logic;
                EN_CHAN_SYNC      : out std_logic;

        -- Aurora Lane Interface

                CHANNEL_BOND_LOAD : in std_logic;
                GOT_A             : in std_logic_vector(0 to 1);
                GOT_V             : in std_logic;
                RESET_LANES       : out std_logic;

        -- System Interface

                USER_CLK          : in std_logic;
                RESET             : in std_logic;
                CHANNEL_UP        : out std_logic;
                START_RX          : out std_logic;

        -- Idle and Verification Sequence Generator Interface

                DID_VER           : in std_logic;
                GEN_VER           : out std_logic;

        -- Channel Init State Machine Interface

                RESET_CHANNEL     : in std_logic

             );

    end component;


    component aurora_201_IDLE_AND_VER_GEN

        port (

        -- Channel Init SM Interface

                GEN_VER  : in std_logic;
                DID_VER  : out std_logic;

        -- Aurora Lane Interface

                GEN_A    : out std_logic;
                GEN_K    : out std_logic_vector(0 to 1);
                GEN_R    : out std_logic_vector(0 to 1);
                GEN_V    : out std_logic_vector(0 to 1);

        -- System Interface

                RESET    : in std_logic;
                USER_CLK : in std_logic

             );

    end component;


    component aurora_201_CHANNEL_ERROR_DETECT

        port (

        -- Aurora Lane Interface

                SOFT_ERROR         : in std_logic;
                HARD_ERROR         : in std_logic;
                LANE_UP            : in std_logic;

        -- System Interface

                USER_CLK           : in std_logic;
                POWER_DOWN         : in std_logic;

                CHANNEL_SOFT_ERROR : out std_logic;
                CHANNEL_HARD_ERROR : out std_logic;

        -- Channel Init SM Interface

                RESET_CHANNEL      : out std_logic

             );

    end component;

begin

    EN_CHAN_SYNC       <= EN_CHAN_SYNC_Buffer;
    GEN_A              <= GEN_A_Buffer;
    GEN_K              <= GEN_K_Buffer;
    GEN_R              <= GEN_R_Buffer;
    GEN_V              <= GEN_V_Buffer;
    RESET_LANES        <= RESET_LANES_Buffer;
    CHANNEL_UP         <= CHANNEL_UP_Buffer;
    START_RX           <= START_RX_Buffer;
    CHANNEL_SOFT_ERROR <= CHANNEL_SOFT_ERROR_Buffer;
    CHANNEL_HARD_ERROR <= CHANNEL_HARD_ERROR_Buffer;

-- Main Body of Code --

    -- State Machine for channel bonding and verification.

    channel_init_sm_i : aurora_201_CHANNEL_INIT_SM

        port map (

        -- GTP Interface

                    CH_BOND_DONE => CH_BOND_DONE,
                    EN_CHAN_SYNC => EN_CHAN_SYNC_Buffer,

        -- Aurora Lane Interface

                    CHANNEL_BOND_LOAD => CHANNEL_BOND_LOAD,
                    GOT_A => GOT_A,
                    GOT_V => GOT_V,
                    RESET_LANES => RESET_LANES_Buffer,

        -- System Interface

                    USER_CLK => USER_CLK,
                    RESET => RESET,
                    START_RX => START_RX_Buffer,
                    CHANNEL_UP => CHANNEL_UP_Buffer,

        -- Idle and Verification Sequence Generator Interface

                    DID_VER => did_ver_i,
                    GEN_VER => gen_ver_i,

        -- Channel Error Management Module Interface

                    RESET_CHANNEL => reset_channel_i

                 );


    -- Idle and verification sequence generator module.

    idle_and_ver_gen_i : aurora_201_IDLE_AND_VER_GEN

        port map (

        -- Channel Init SM Interface

                    GEN_VER => gen_ver_i,
                    DID_VER => did_ver_i,

        -- Aurora Lane Interface

                    GEN_A => GEN_A_Buffer,
                    GEN_K => GEN_K_Buffer,
                    GEN_R => GEN_R_Buffer,
                    GEN_V => GEN_V_Buffer,

        -- System Interface

                    RESET => RESET,
                    USER_CLK => USER_CLK

                 );



    -- Channel Error Management module.

    channel_error_detect_i : aurora_201_CHANNEL_ERROR_DETECT

        port map (

        -- Aurora Lane Interface

                    SOFT_ERROR => SOFT_ERROR,
                    HARD_ERROR => HARD_ERROR,
                    LANE_UP => LANE_UP,

        -- System Interface

                    USER_CLK => USER_CLK,
                    POWER_DOWN => POWER_DOWN,
                    CHANNEL_SOFT_ERROR => CHANNEL_SOFT_ERROR_Buffer,
                    CHANNEL_HARD_ERROR => CHANNEL_HARD_ERROR_Buffer,

        -- Channel Init State Machine Interface

                    RESET_CHANNEL => reset_channel_i

                 );

end MAPPED;
