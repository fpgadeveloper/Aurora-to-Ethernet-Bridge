--
--      Project:  Aurora Module Generator version 2.8
--
--         Date:  $Date: 2007/08/08 11:13:34 $
--          Tag:  $Name: i+IP+144838 $
--         File:  $RCSfile: tx_ll_control_vhd.ejava,v $
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
--  TX_LL_CONTROL
--
--
--                    Xilinx - Garden Valley Design Team
--
--  Description: This module provides the transmitter state machine
--               control logic to connect the LocalLink interface to
--               the Aurora Channel.
--
--               This module supports 1 2-byte lane designs
--

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use WORK.AURORA_PKG.all;

-- synthesis translate_off
library UNISIM;
use UNISIM.all;
-- synthesis translate_on

entity aurora_201_TX_LL_CONTROL is

    port (

    -- LocalLink PDU Interface

            TX_SRC_RDY_N  : in std_logic;
            TX_SOF_N      : in std_logic;
            TX_EOF_N      : in std_logic;
            TX_REM        : in std_logic;
            TX_DST_RDY_N  : out std_logic;

    -- Clock Compensation Interface

            WARN_CC       : in std_logic;
            DO_CC         : in std_logic;

    -- Global Logic Interface

            CHANNEL_UP    : in std_logic;

    -- TX_LL Control Module Interface

            HALT_C        : out std_logic;

    -- Aurora Lane Interface

            GEN_SCP       : out std_logic;
            GEN_ECP       : out std_logic;
            GEN_CC        : out std_logic;

    -- System Interface

            USER_CLK      : in std_logic

         );

end aurora_201_TX_LL_CONTROL;

architecture RTL of aurora_201_TX_LL_CONTROL is

-- Parameter Declarations --

    constant DLY : time := 1 ns;

-- External Register Declarations --

    signal TX_DST_RDY_N_Buffer  : std_logic;
    signal HALT_C_Buffer        : std_logic;
    signal GEN_SCP_Buffer       : std_logic;
    signal GEN_ECP_Buffer       : std_logic;
    signal GEN_CC_Buffer        : std_logic;

-- Internal Register Declarations --

    signal do_cc_r                      : std_logic;
    signal warn_cc_r                    : std_logic;

    signal idle_r                       : std_logic;
    signal sof_r                        : std_logic;
    signal sof_data_eof_1_r             : std_logic;
    signal sof_data_eof_2_r             : std_logic;
    signal sof_data_eof_3_r             : std_logic;
    signal data_r                       : std_logic;
    signal data_eof_1_r                 : std_logic;
    signal data_eof_2_r                 : std_logic;
    signal data_eof_3_r                 : std_logic;

-- Wire Declarations --


    signal next_idle_c           : std_logic;
    signal next_sof_c            : std_logic;
    signal next_sof_data_eof_1_c : std_logic;
    signal next_sof_data_eof_2_c : std_logic;
    signal next_sof_data_eof_3_c : std_logic;
    signal next_data_c           : std_logic;
    signal next_data_eof_1_c     : std_logic;
    signal next_data_eof_2_c     : std_logic;
    signal next_data_eof_3_c     : std_logic;

    signal tx_dst_rdy_n_c        : std_logic;
    signal do_sof_c              : std_logic;
    signal do_eof_c              : std_logic;
    signal channel_full_c        : std_logic;
    signal pdu_ok_c              : std_logic;

-- Declarations to handle VHDL limitations
    signal reset_i               : std_logic;

-- Component Declarations --

    component FDR

        generic (INIT : bit := '0');

        port (

                Q : out std_ulogic;
                C : in  std_ulogic;
                D : in  std_ulogic;
                R : in  std_ulogic

             );

    end component;

begin

    TX_DST_RDY_N  <= TX_DST_RDY_N_Buffer;
    HALT_C        <= HALT_C_Buffer;
    GEN_SCP       <= GEN_SCP_Buffer;
    GEN_ECP       <= GEN_ECP_Buffer;
    GEN_CC        <= GEN_CC_Buffer;

-- Main Body of Code --



    reset_i <=  not CHANNEL_UP;


    -- Clock Compensation --

    -- Register the DO_CC and WARN_CC signals for internal use.  Note that the raw DO_CC
    -- signal is used for some logic so the DO_CC signal should be driven directly
    -- from a register whenever possible.

    process (USER_CLK)

    begin

        if (USER_CLK 'event and USER_CLK = '1') then

            if (CHANNEL_UP = '0') then

                do_cc_r <= '0' after DLY;

            else

                do_cc_r <= DO_CC after DLY;

            end if;

        end if;

    end process;


    process (USER_CLK)

    begin

        if (USER_CLK 'event and USER_CLK = '1') then

            if (CHANNEL_UP = '0') then

                warn_cc_r <= '0' after DLY;

            else

                warn_cc_r <= WARN_CC after DLY;

            end if;

        end if;

    end process;




    -- PDU State Machine --

    -- The PDU state machine handles the encapsulation and transmission of user
    -- PDUs.  It can use the channel when there is no CC, NFC message, UFC header,
    -- UFC message or remote NFC request.

    -- State Registers

    process (USER_CLK)

    begin

        if (USER_CLK 'event and USER_CLK = '1') then

            if (CHANNEL_UP = '0') then

                idle_r           <= '1' after DLY;
                sof_r            <= '0' after DLY;
                sof_data_eof_1_r <= '0' after DLY;
                sof_data_eof_2_r <= '0' after DLY;
                sof_data_eof_3_r <= '0' after DLY;
                data_r           <= '0' after DLY;
                data_eof_1_r     <= '0' after DLY;
                data_eof_2_r     <= '0' after DLY;
                data_eof_3_r     <= '0' after DLY;

            else

                if (pdu_ok_c = '1') then

                    idle_r           <= next_idle_c           after DLY;
                    sof_r            <= next_sof_c            after DLY;
                    sof_data_eof_1_r <= next_sof_data_eof_1_c after DLY;
                    sof_data_eof_2_r <= next_sof_data_eof_2_c after DLY;
                    sof_data_eof_3_r <= next_sof_data_eof_3_c after DLY;
                    data_r           <= next_data_c           after DLY;
                    data_eof_1_r     <= next_data_eof_1_c     after DLY;
                    data_eof_2_r     <= next_data_eof_2_c     after DLY;
                    data_eof_3_r     <= next_data_eof_3_c     after DLY;

                end if;

            end if;

        end if;

    end process;


    -- Next State Logic

    next_idle_c           <= (idle_r and not do_sof_c)           or
                             (sof_data_eof_3_r and not do_sof_c) or
                             (data_eof_3_r and not do_sof_c);



    next_sof_c            <= ((idle_r and do_sof_c) and not do_eof_c)           or
                             ((sof_data_eof_3_r and do_sof_c) and not do_eof_c) or
                             ((data_eof_3_r and do_sof_c) and not do_eof_c);



    next_data_c           <= (sof_r and not do_eof_c ) or
                             (data_r and not do_eof_c);


    next_data_eof_1_c     <= (sof_r and do_eof_c) or
                             (data_r and do_eof_c);


    next_data_eof_2_c     <= data_eof_1_r;


    next_data_eof_3_c     <= data_eof_2_r;


    next_sof_data_eof_1_c <= ((idle_r and do_sof_c) and do_eof_c)           or
                             ((sof_data_eof_3_r and do_sof_c) and do_eof_c) or
                             ((data_eof_3_r and do_sof_c) and do_eof_c);


    next_sof_data_eof_2_c <= sof_data_eof_1_r;


    next_sof_data_eof_3_c <= sof_data_eof_2_r;


    -- Generate an SCP character when the PDU state machine is active and in an SOF state.

    process (USER_CLK)

    begin

        if (USER_CLK 'event and USER_CLK = '1') then

            if (CHANNEL_UP = '0') then

                GEN_SCP_Buffer <= '0' after DLY;

            else

                GEN_SCP_Buffer <= ((sof_r or sof_data_eof_1_r) and pdu_ok_c) after DLY;

            end if;

        end if;

    end process;


    -- Generate an ECP character when the PDU state machine is active and in and EOF state.

    process (USER_CLK)

    begin

        if (USER_CLK 'event and USER_CLK = '1') then

            if (CHANNEL_UP = '0') then

                GEN_ECP_Buffer <= '0' after DLY;

            else

                GEN_ECP_Buffer <= (data_eof_3_r or sof_data_eof_3_r) and pdu_ok_c after DLY;

            end if;

        end if;

    end process;


    tx_dst_rdy_n_c <= (next_sof_data_eof_1_c and pdu_ok_c) or
                       sof_data_eof_1_r                    or
                      (next_data_eof_1_c and pdu_ok_c)     or
                       DO_CC                               or
                       data_eof_1_r                        or
                      (data_eof_2_r and not pdu_ok_c)      or
                      (sof_data_eof_2_r and not pdu_ok_c);


    -- The flops for the GEN_CC signal are replicated for timing and instantiated to allow us
    -- to set their value reliably on powerup.

    gen_cc_flop_0_i : FDR

        port map (

                    D => do_cc_r,
                    C => USER_CLK,
                    R => reset_i,
                    Q => GEN_CC_Buffer

                 );


    -- The TX_DST_RDY_N signal is registered.

    process (USER_CLK)

    begin

        if (USER_CLK 'event and USER_CLK = '1') then

            if (CHANNEL_UP = '0') then

                TX_DST_RDY_N_Buffer <= '1' after DLY;

            else

                TX_DST_RDY_N_Buffer <= tx_dst_rdy_n_c after DLY;

            end if;

        end if;

    end process;


    -- Helper Logic

    -- SOF requests are valid when TX_SRC_RDY_N. TX_DST_RDY_N and TX_SOF_N are asserted

    do_sof_c <=     not TX_SRC_RDY_N            and
                    not TX_DST_RDY_N_Buffer     and
                    not TX_SOF_N;    


    -- EOF requests are valid when TX_SRC_RDY_N, TX_DST_RDY_N and TX_EOF_N are asserted

    do_eof_c <=     not TX_SRC_RDY_N            and
                    not TX_DST_RDY_N_Buffer     and
                    not TX_EOF_N;
                 
                 


    -- Freeze the PDU state machine when CCs must be handled.

    pdu_ok_c <= not do_cc_r;


    -- Halt the flow of data through the datastream when the PDU state machine is frozen.

    HALT_C_Buffer <= not pdu_ok_c;


    -- The aurora channel is 'full' if there is more than enough data to fit into
    -- a channel that is already carrying an SCP and an ECP character.

    channel_full_c <= '1';

end RTL;
