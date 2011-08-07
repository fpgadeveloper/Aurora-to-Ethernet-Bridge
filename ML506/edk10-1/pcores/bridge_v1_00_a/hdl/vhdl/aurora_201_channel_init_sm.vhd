--
--      Project:  Aurora Module Generator version 2.8
--
--         Date:  $Date: 2007/08/08 11:13:33 $
--          Tag:  $Name: i+IP+144838 $
--         File:  $RCSfile: channel_init_sm_vhd.ejava,v $
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
--  CHANNEL_INIT_SM
--
--
--                    Xilinx - Garden Valley Design Team
--
--  Description: the CHANNEL_INIT_SM module is a state machine for managing channel
--               bonding and verification.
--
--               The channel init state machine is reset until the lane up signals
--               of all the lanes that constitute the channel are asserted.  It then
--               requests channel bonding until the lanes have been bonded and
--               checks to make sure the bonding was successful.  Channel bonding is
--               skipped if there is only one lane in the channel.  If bonding is
--               unsuccessful, the lanes are reset.
--
--               After the bonding phase is complete, the state machine sends
--               verification sequences through the channel until it is clear that
--               the channel is ready to be used.  If verification is successful,
--               the CHANNEL_UP signal is asserted.  If it is unsuccessful, the
--               lanes are reset.
--
--               After CHANNEL_UP goes high, the state machine is quiescent, and will
--               reset only if one of the lanes goes down, a hard error is detected, or
--               a general reset is requested.
--
--               This module supports 1 2-byte lane designs
--

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use WORK.AURORA_PKG.all;

-- synthesis translate_off

library UNISIM;
use UNISIM.all;

-- synthesis translate_on

entity aurora_201_CHANNEL_INIT_SM is

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

end aurora_201_CHANNEL_INIT_SM;

architecture RTL of aurora_201_CHANNEL_INIT_SM is

-- Parameter Declarations --

    constant DLY : time := 1 ns;

-- External Register Declarations --

    signal EN_CHAN_SYNC_Buffer : std_logic;
    signal RESET_LANES_Buffer  : std_logic;
    signal CHANNEL_UP_Buffer   : std_logic;
    signal START_RX_Buffer     : std_logic;
    signal GEN_VER_Buffer      : std_logic;

-- Internal Register Declarations --

    signal free_count_done_r       : std_logic;
    signal verify_watchdog_r       : std_logic_vector(0 to 15);
    signal all_lanes_v_r           : std_logic;
    signal got_first_v_r           : std_logic;
    signal v_count_r               : std_logic_vector(0 to 31);
    signal bad_v_r                 : std_logic;
    signal rxver_count_r           : std_logic_vector(0 to 2);
    signal txver_count_r           : std_logic_vector(0 to 7);

    -- State registers

    signal wait_for_lane_up_r      : std_logic;
    signal verify_r                : std_logic;
    signal ready_r                 : std_logic;

-- Wire Declarations --

    signal free_count_1_r          : std_logic;
    signal free_count_2_r          : std_logic;
    signal insert_ver_c            : std_logic;
    signal verify_watchdog_done_r  : std_logic;
    signal rxver_3d_done_r         : std_logic;
    signal txver_8d_done_r         : std_logic;
    signal reset_lanes_c           : std_logic;

    -- Next state signals

    signal next_verify_c           : std_logic;
    signal next_ready_c            : std_logic;

    -- VHDL utility signals

    signal  tied_to_vcc        : std_logic;
    signal  tied_to_gnd        : std_logic;

-- Component Declarations

    component SRL16

    -- synthesis translate_off

        generic (INIT : bit_vector := X"0000");

    -- synthesis translate_on

        port (

                Q   : out std_ulogic;
                A0  : in  std_ulogic;
                A1  : in  std_ulogic;
                A2  : in  std_ulogic;
                A3  : in  std_ulogic;
                CLK : in  std_ulogic;
                D   : in  std_ulogic

             );

    end component;

    component SRL16E

    -- synthesis translate_off

        generic (INIT : bit_vector := X"0000");

    -- synthesis translate_on

        port (

                Q   : out std_ulogic;
                A0  : in  std_ulogic;
                A1  : in  std_ulogic;
                A2  : in  std_ulogic;
                A3  : in  std_ulogic;
                CE  : in  std_ulogic;
                CLK : in  std_ulogic;
                D   : in  std_ulogic

             );

    end component;

    component FD

    -- synthesis translate_off

        generic (INIT : bit := '0');

    -- synthesis translate_on

        port (

                Q : out std_ulogic;
                C : in  std_ulogic;
                D : in  std_ulogic

             );

    end component;

begin

    EN_CHAN_SYNC <= EN_CHAN_SYNC_Buffer;
    RESET_LANES  <= RESET_LANES_Buffer;
    CHANNEL_UP   <= CHANNEL_UP_Buffer;
    START_RX     <= START_RX_Buffer;
    GEN_VER      <= GEN_VER_Buffer;

    tied_to_vcc  <= '1';
    tied_to_gnd  <= '0';

-- Main Body of Code --

    -- Main state machine for bonding and verification --

    -- State registers

    process (USER_CLK)

    begin

        if (USER_CLK 'event and USER_CLK = '1') then

            if ((RESET or RESET_CHANNEL) = '1') then

                wait_for_lane_up_r <= '1' after DLY;
                verify_r           <= '0' after DLY;
                ready_r            <= '0' after DLY;

            else

                wait_for_lane_up_r <= '0' after DLY;
                verify_r           <= next_verify_c after DLY;
                ready_r            <= next_ready_c after DLY;

            end if;

        end if;

    end process;


    -- Next state logic

    next_verify_c       <= wait_for_lane_up_r or
                           (verify_r and (not rxver_3d_done_r or not txver_8d_done_r));

    next_ready_c        <= ((verify_r and txver_8d_done_r) and rxver_3d_done_r) or
                           ready_r;


    -- Output Logic

    -- Channel up is high as long as the Global Logic is in the ready state.

    CHANNEL_UP_Buffer <= ready_r;


    -- Turn the receive engine on as soon as all the lanes are up.

    process (USER_CLK)

    begin

        if (USER_CLK 'event and USER_CLK = '1') then

            if (RESET = '1') then

                START_RX_Buffer <= '0' after DLY;

            else

                START_RX_Buffer <= not wait_for_lane_up_r after DLY;

            end if;

        end if;

    end process;


    -- Generate the Verification sequence when in the verify state.

    GEN_VER_Buffer <= verify_r;


    -- Channel Reset --

    -- Some problems during channel bonding and verification require the lanes to
    -- be reset.  When this happens, we assert the Reset Lanes signal, which gets
    -- sent to all Aurora Lanes.  When the Aurora Lanes reset, their LANE_UP signals
    -- go down.  This causes the Channel Error Detector to assert the Reset Channel
    -- signal.

    reset_lanes_c <= (verify_r and verify_watchdog_done_r) or
                     (verify_r and bad_v_r and not rxver_3d_done_r) or
                     (RESET_CHANNEL and not wait_for_lane_up_r) or
                     RESET;

    reset_lanes_flop_i : FD

    -- synthesis translate_off

        generic map (INIT => '1')

    -- synthesis translate_on

        port map (

                    D => reset_lanes_c,
                    C => USER_CLK,
                    Q => RESET_LANES_Buffer

                 );


    -- Watchdog timers --

    -- We create a free counter out of SRLs to count large values without excessive cost.

    free_count_1_i : SRL16

    -- synthesis translate_off

        generic map (INIT => X"8000")

    -- synthesis translate_on

        port map (

                    Q   => free_count_1_r,
                    A0  => tied_to_vcc,
                    A1  => tied_to_vcc,
                    A2  => tied_to_vcc,
                    A3  => tied_to_vcc,
                    CLK => USER_CLK,
                    D   => free_count_1_r

                 );


    free_count_2_i : SRL16E

    -- synthesis translate_off

        generic map (INIT => X"8000")

    -- synthesis translate_on

        port map (

                    Q   => free_count_2_r,
                    A0  => tied_to_vcc,
                    A1  => tied_to_vcc,
                    A2  => tied_to_vcc,
                    A3  => tied_to_vcc,
                    CLK => USER_CLK,
                    CE  => free_count_1_r,
                    D   => free_count_2_r

                 );


    -- Finally we have logic hat registers a pulse when both the inner and the
    -- outer SRLs have a bit in their last position.  This should map to carry logic
    -- and a register.

    process (USER_CLK)

    begin

        if (USER_CLK 'event and USER_CLK = '1') then

            free_count_done_r <= free_count_2_r and free_count_1_r after DLY;

        end if;

    end process;


    -- We use the free running count as a CE for the verify watchdog.  The
    -- count runs continuously so the watchdog will vary between a count of 4096
    -- and 3840 cycles - acceptable for this application.

    process (USER_CLK)

    begin

        if (USER_CLK 'event and USER_CLK = '1') then

            if ((free_count_done_r or not verify_r) = '1') then

                verify_watchdog_r <= verify_r & verify_watchdog_r(0 to 14) after DLY;

            end if;

        end if;

    end process;


    verify_watchdog_done_r <= verify_watchdog_r(15);


    -- Channel Bonding --

    -- We don't use channel bonding for the single lane case, so we tie the
    -- EN_CHAN_SYNC signal low.

    EN_CHAN_SYNC_Buffer <= '0';


    -- Verification --

    -- Vs need to appear on all lanes simultaneously.

    process (USER_CLK)

    begin

        if (USER_CLK 'event and USER_CLK = '1') then

            all_lanes_v_r <= GOT_V after DLY;

        end if;

    end process;


    -- Vs need to be decoded by the aurora lane and then checked by the
    -- Global logic.  They must appear periodically.

    process (USER_CLK)

    begin

        if (USER_CLK 'event and USER_CLK = '1') then

            if (verify_r = '0') then

                got_first_v_r <= '0' after DLY;

            else

                if (all_lanes_v_r = '1') then

                    got_first_v_r <= '1' after DLY;

                end if;

            end if;

        end if;

    end process;


    insert_ver_c <= (all_lanes_v_r and not got_first_v_r) or (v_count_r(31) and verify_r);


    -- Shift register for measuring the time between V counts.

    process (USER_CLK)

    begin

        if (USER_CLK 'event and USER_CLK = '1') then

            v_count_r <= insert_ver_c & v_count_r(0 to 30) after DLY;

        end if;

    end process;


    -- Assert bad_v_r if a V does not arrive when expected.

    process (USER_CLK)

    begin

        if (USER_CLK 'event and USER_CLK = '1') then

            bad_v_r <= (v_count_r(31) xor all_lanes_v_r) and got_first_v_r after DLY;

        end if;

    end process;


    -- Count the number of Ver sequences received.  You're done after you receive four.

    process (USER_CLK)

    begin

        if (USER_CLK 'event and USER_CLK = '1') then

            if (((v_count_r(31) and all_lanes_v_r) or not verify_r) = '1') then

                rxver_count_r <= verify_r & rxver_count_r(0 to 1) after DLY;

            end if;

        end if;

    end process;


    rxver_3d_done_r <= rxver_count_r(2);


    -- Count the number of Ver sequences transmitted. You're done after you send eight.

    process (USER_CLK)

    begin

        if (USER_CLK 'event and USER_CLK = '1') then

            if ((DID_VER or not verify_r) = '1') then

                txver_count_r <= verify_r & txver_count_r(0 to 6) after DLY;

            end if;

        end if;

    end process;


    txver_8d_done_r <= txver_count_r(7);

end RTL;
