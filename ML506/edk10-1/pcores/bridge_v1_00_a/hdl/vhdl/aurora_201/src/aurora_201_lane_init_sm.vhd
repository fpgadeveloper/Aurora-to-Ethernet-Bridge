--
--      Project:  Aurora Module Generator version 2.8
--
--         Date:  $Date: 2007/08/08 11:13:33 $
--          Tag:  $Name: i+IP+144838 $
--         File:  $RCSfile: lane_init_sm_gtp_vhd.ejava,v $
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
--  LANE_INIT_SM
--
--
--                    Xilinx - Garden Valley Design Team
--
--  Description: This logic manages the initialization of the GTP in 2-byte mode.
--               It consists of a small state machine, a set of counters for
--               tracking the progress of initializtion and detecting problems,
--               and some additional support logic.
--

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use WORK.AURORA_PKG.all;

-- synthesis translate_off
library UNISIM;
use UNISIM.all;
-- synthesis translate_on


entity aurora_201_LANE_INIT_SM is

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

end aurora_201_LANE_INIT_SM;

architecture RTL of aurora_201_LANE_INIT_SM is

-- Parameter Declarations --

    constant DLY : time := 1 ns;

-- External Register Declarations

    signal RX_RESET_Buffer            : std_logic;
    signal TX_RESET_Buffer            : std_logic;
    signal RX_POLARITY_Buffer         : std_logic;
    signal ENA_COMMA_ALIGN_Buffer     : std_logic;
    signal GEN_K_Buffer               : std_logic;
    signal GEN_SP_DATA_Buffer         : std_logic_vector(0 to 1);
    signal GEN_SPA_DATA_Buffer        : std_logic_vector(0 to 1);
    signal DO_WORD_ALIGN_Buffer       : std_logic;
    signal ENABLE_ERROR_DETECT_Buffer : std_logic;
    signal LANE_UP_Buffer             : std_logic;

-- Internal Register Declarations

    signal odd_word_r              : std_logic := '1';
    -- counter1 is intitialized to ensure that the counter comes up at some value other than X.
    -- We have tried different initial values and it does not matter what the value is, as long
    -- as it is not X since X breaks the state machine
    signal counter1_r             : unsigned(0 to 7) := "00000001";
    signal counter2_r              : std_logic_vector(0 to 15);
    signal counter3_r              : std_logic_vector(0 to 3);
    signal counter4_r              : std_logic_vector(0 to 15);
    signal counter5_r              : std_logic_vector(0 to 15);
    signal rx_polarity_r           : std_logic := '0';
    signal prev_char_was_comma_r   : std_logic;
    signal comma_over_two_cycles_r : std_logic;
    signal prev_count_128d_done_r  : std_logic;
    signal do_watchdog_count_r     : std_logic;
    signal reset_count_r           : std_logic;

    -- FSM states, encoded for one-hot implementation

    signal begin_r    : std_logic;  -- Begin initialization
    signal rst_r      : std_logic;  -- Reset GTPs
    signal align_r    : std_logic;  -- Align SERDES
    signal realign_r  : std_logic;  -- Verify no spurious realignment
    signal polarity_r : std_logic;  -- Verify polarity of rx'ed symbols
    signal ack_r      : std_logic;  -- Ack initialization with partner
    signal ready_r    : std_logic;  -- Lane ready for Bonding/Verification

-- Wire Declarations

    signal send_sp_c                    : std_logic;
    signal send_spa_r                   : std_logic;
    signal count_8d_done_r              : std_logic;
    signal count_32d_done_r             : std_logic;
    signal count_128d_done_r            : std_logic;
    signal symbol_error_c               : std_logic;
    signal txack_16d_done_r             : std_logic;
    signal rxack_4d_done_r              : std_logic;
    signal sp_polarity_c                : std_logic;
    signal inc_count_c                  : std_logic;
    signal change_in_state_c            : std_logic;
    signal watchdog_done_r              : std_logic;
    signal remote_reset_watchdog_done_r : std_logic;

    signal next_begin_c                 : std_logic;
    signal next_rst_c                   : std_logic;
    signal next_align_c                 : std_logic;
    signal next_realign_c               : std_logic;
    signal next_polarity_c              : std_logic;
    signal next_ack_c                   : std_logic;
    signal next_ready_c                 : std_logic;

    component FDR

        port (
                D : in std_logic;
                C : in std_logic;
                R : in std_logic;
                Q : out std_logic
             );

    end component;

begin

    RX_RESET <= RX_RESET_Buffer;
    TX_RESET <= TX_RESET_Buffer;
    RX_POLARITY <= RX_POLARITY_Buffer;
    ENA_COMMA_ALIGN <= ENA_COMMA_ALIGN_Buffer;
    GEN_K <= GEN_K_Buffer;
    GEN_SP_DATA <= GEN_SP_DATA_Buffer;
    GEN_SPA_DATA <= GEN_SPA_DATA_Buffer;
    DO_WORD_ALIGN <= DO_WORD_ALIGN_Buffer;
    ENABLE_ERROR_DETECT <= ENABLE_ERROR_DETECT_Buffer;
    LANE_UP <= LANE_UP_Buffer;

-- Main Body of Code

    -- Main state machine for managing initialization --

    -- State registers

    process (USER_CLK)

    begin

        if (USER_CLK 'event and USER_CLK = '1') then

            if ((RESET or HARD_ERROR_RESET) = '1') then

                begin_r    <= '1' after DLY;
                rst_r      <= '0' after DLY;
                align_r    <= '0' after DLY;
                realign_r  <= '0' after DLY;
                polarity_r <= '0' after DLY;
                ack_r      <= '0' after DLY;
                ready_r    <= '0' after DLY;

            else

                begin_r    <= next_begin_c    after DLY;
                rst_r      <= next_rst_c      after DLY;
                align_r    <= next_align_c    after DLY;
                realign_r  <= next_realign_c  after DLY;
                polarity_r <= next_polarity_c after DLY;
                ack_r      <= next_ack_c      after DLY;
                ready_r    <= next_ready_c    after DLY;

            end if;

        end if;

    end process;

    -- Next state logic

    next_begin_c    <= (realign_r and RX_REALIGN) or
                       (polarity_r and not sp_polarity_c) or
                       (ack_r and watchdog_done_r) or
                       (ready_r and remote_reset_watchdog_done_r);

    next_rst_c      <= begin_r or
                       (rst_r and not count_8d_done_r);

    next_align_c    <= (rst_r and count_8d_done_r) or
                       (align_r and not count_128d_done_r);

    next_realign_c  <= (align_r and count_128d_done_r) or
                       ((realign_r and not count_32d_done_r) and not RX_REALIGN);

    next_polarity_c <= ((realign_r and count_32d_done_r) and not RX_REALIGN) or
                       ((polarity_r and sp_polarity_c) and odd_word_r);

    next_ack_c      <= ((polarity_r and sp_polarity_c) and not odd_word_r) or
                       (ack_r and (not txack_16d_done_r or not rxack_4d_done_r) and not watchdog_done_r);

    next_ready_c    <= (((ack_r and txack_16d_done_r) and rxack_4d_done_r) and not watchdog_done_r) or
                       (ready_r and not remote_reset_watchdog_done_r);


    -- Output Logic


    -- Enable comma align when in the ALIGN state.

    ENA_COMMA_ALIGN_Buffer <= align_r;


    -- Hold RX_RESET when in the RST state.

    RX_RESET_Buffer        <= rst_r;


    -- Hold TX_RESET when in the RST state.

    TX_RESET_Buffer        <= rst_r;


    -- LANE_UP is asserted when in the READY state.

    lane_up_flop_i : FDR

    port map (
                D => ready_r,
                C => USER_CLK,
                R => RESET,
                Q => LANE_UP_Buffer
             );


    -- ENABLE_ERROR_DETECT is asserted when in the ACK or READY states.  Asserting
    -- it earlier will result in too many false errors.  After it is asserted,
    -- higher level modules can respond to Hard Errors by resetting the Aurora Lane.
    -- We register the signal before it leaves the lane_init_sm submodule.

    process (USER_CLK)

    begin

        if (USER_CLK 'event and USER_CLK = '1') then

            ENABLE_ERROR_DETECT_Buffer <= ack_r or ready_r after DLY;

        end if;

    end process;


    -- The Aurora Lane should transmit SP sequences when not ACKing or Ready.

    send_sp_c            <= not (ack_r or ready_r);


    -- The Aurora Lane transmits SPA sequences while in the ACK state.

    send_spa_r           <= ack_r;


    -- Do word alignment when in the ALIGN state.

    DO_WORD_ALIGN_Buffer <= align_r or ready_r;


    -- Transmission Logic for SP and SPA sequences --

    -- Select either the even or the odd word of the current sequence for transmission.
    -- There is no reset for odd word.  It is initialized when the FPGA is configured.
    -- The variable, odd_word_r, is initialized for simulation (See SIGNAL declarations).

    process (USER_CLK)

    begin

        if (USER_CLK 'event and USER_CLK = '1') then

            odd_word_r <= not odd_word_r after DLY;

        end if;

    end process;


    -- Request transmission of the commas needed for the SP and SPA sequences.
    -- These commas are sent on the MSByte of the lane on all odd bytes.

    GEN_K_Buffer           <= odd_word_r and (send_sp_c or send_spa_r);


    -- Request transmission of the SP_DATA sequence.

    GEN_SP_DATA_Buffer(0)  <= not odd_word_r and send_sp_c;
    GEN_SP_DATA_Buffer(1)  <= send_sp_c;


    -- Request transmission of the SPA_DATA sequence.

    GEN_SPA_DATA_Buffer(0) <= not odd_word_r and send_spa_r;
    GEN_SPA_DATA_Buffer(1) <= send_spa_r;


    -- Counter 1, for reset cycles, align cycles and realign cycles --

    -- Core of the counter

    process (USER_CLK)

    begin

        if (USER_CLK 'event and USER_CLK = '1') then

            if (reset_count_r = '1') then

                counter1_r <= "00000001" after DLY;

            else

                if (inc_count_c = '1') then

                    counter1_r <= counter1_r + "00000001" after DLY;

                end if;

            end if;

        end if;

    end process;


    -- Assert count_8d_done_r when bit 4 in the register first goes high.

    count_8d_done_r   <= std_bool(counter1_r(4) = '1');


    -- Assert count_32d_done_r when bit 2 in the register first goes high.

    count_32d_done_r  <= std_bool(counter1_r(2) = '1');


    -- Assert count_128d_done_r when bit 0 in the register first goes high.

    count_128d_done_r <= std_bool(counter1_r(0) = '1');


    -- The counter resets any time the RESET signal is asserted, there is a change in
    -- state, there is a symbol error, or commas are not consecutive in the align state.

    process (USER_CLK)

    begin

        if (USER_CLK 'event and USER_CLK = '1') then

            reset_count_r <= RESET or change_in_state_c or ( not rst_r and (symbol_error_c or not comma_over_two_cycles_r));

        end if;

    end process;


    -- The counter should be reset when entering and leaving the reset state.

    change_in_state_c <= std_bool(rst_r /= next_rst_c);


    -- Symbol error is asserted whenever there is a disparity error or an invalid
    -- 10b code.

    symbol_error_c    <= std_bool((RX_DISP_ERR /= "00") or (RX_NOT_IN_TABLE /= "00"));


    -- Previous cycle comma is used to check for consecutive commas.

    process (USER_CLK)

    begin

        if (USER_CLK 'event and USER_CLK = '1') then

            prev_char_was_comma_r <= std_bool(RX_CHAR_IS_COMMA /= "00") after DLY;

        end if;

    end process;


    -- Check to see that commas are consecutive in the align state.

    process (USER_CLK)

    begin

        if (USER_CLK 'event and USER_CLK = '1') then

            comma_over_two_cycles_r <= (prev_char_was_comma_r xor
                                       std_bool(RX_CHAR_IS_COMMA /= "00")) or not align_r after DLY;

        end if;

    end process;


    -- Increment count is always asserted, except in the ALIGN state when it is asserted
    -- only upon the arrival of a comma character.

    inc_count_c <= not align_r or (align_r and std_bool(RX_CHAR_IS_COMMA /= "00"));


    -- Counter 2, for counting tx_acks --

    -- This counter is implemented as a shift register.  It is constantly shifting.  As a
    -- result, when the state machine is not in the ack state, the register clears out.
    -- When the state machine goes into the ack state, the count is incremented every
    -- cycle.  The txack_16d_done signal goes high and stays high after 16 cycles in the
    -- ack state.  The signal deasserts only after it has had enough time for all the ones
    -- to clear out after the machine leaves the ack state, but this is tolerable because
    -- the machine will spend at least 8 cycles in reset, 256 in ALIGN and 32 in REALIGN.
    --
    -- The counter is implemented seperately from the main counter because it is required
    -- to stop counting when it reaches the end of its count. Adding this functionality
    -- to the main counter is more expensive and more complex than implementing it seperately.

    -- Counter Logic

    process (USER_CLK)

    begin

        if (USER_CLK 'event and USER_CLK = '1') then

            counter2_r <= ack_r & counter2_r(0 to 14) after DLY;

        end if;

    end process;


    -- The counter is done when bit 15 of the shift register goes high.

    txack_16d_done_r <= counter2_r(15);


    -- Counter 3, for counting rx_acks --

    -- This counter is also implemented as a shift register. It is always shifting when
    -- the state machine is not in the ack state to clear it out. When the state machine
    -- goes into the ack state, the register shifts only when a SPA is received. When
    -- 4 SPAs have been received in the ACK state, the rxack_4d_done_r signal is triggered.
    --
    -- This counter is implemented seperately from the main counter because it is required
    -- to increment only when ACKs are received, and then hold its count. Adding this
    -- functionality to the main counter is more expensive than creating a second counter,
    -- and more complex.

    -- Counter Logic

    process (USER_CLK)

    begin

        if (USER_CLK 'event and USER_CLK = '1') then

            if (RX_SPA = '1' or ack_r = '0') then

                counter3_r <= ack_r & counter3_r(0 to 2) after DLY;

            end if;

        end if;

    end process;


    -- The counter is done when bit 7 of the shift register goes high.

    rxack_4d_done_r <= counter3_r(3);


    -- Counter 4, remote reset watchdog timer --

    -- Another counter implemented as a shift register.  This counter puts an upper limit on
    -- the number of SPs that can be received in the Ready state.  If the number of SPs
    -- exceeds the limit, the Aurora Lane resets itself.  The Global logic module will reset
    -- all the lanes if this occurs while they are all in the lane ready state (i.e. lane_up
    -- is asserted for all.

    -- Counter logic

    process (USER_CLK)

    begin

        if (USER_CLK 'event and USER_CLK = '1') then

            if (RX_SP = '1' or ready_r = '0') then

                counter4_r <= ready_r & counter4_r(0 to 14) after DLY;

            end if;

        end if;

    end process;


    -- The counter is done when bit 15 of the shift register goes high.

    remote_reset_watchdog_done_r <= counter4_r(15);


    -- Counter 5, internal watchdog timer --

    -- This counter puts an upper limit on the number of cycles the state machine can
    -- spend in the ack state before it gives up and resets.
    --
    -- The counter is implemented as a shift register extending counter 1.  The counter
    -- clears out in all non-ack cycles by keeping CE asserted.  When it gets into the
    -- ack state, CE is asserted only when there is a transition on the most
    -- significant bit of counter 1.  This happens every 128 cycles.  We count out 32
    -- of these transitions to get a count of approximately 4096 cycles.  The actual
    -- number of cycles is less than this because we don't reset counter1, so it starts
    -- off about 34 cycles into its count.

    -- Counter logic

    process (USER_CLK)

    begin

        if (USER_CLK 'event and USER_CLK = '1') then

            if (do_watchdog_count_r = '1' or ack_r = '0') then

                counter5_r <= ack_r & counter5_r(0 to 14) after DLY;

            end if;

        end if;

    end process;


    -- Store the count_128d_done_r result from the previous cycle.

    process (USER_CLK)

    begin

        if (USER_CLK 'event and USER_CLK = '1') then

            prev_count_128d_done_r <= count_128d_done_r after DLY;

        end if;

    end process;

    -- Trigger CE only when the previous 128d_done is not the same as the
    -- current one, and the current value is high.

    process (USER_CLK)

    begin

        if (USER_CLK 'event and USER_CLK = '1') then

            do_watchdog_count_r <= count_128d_done_r and not prev_count_128d_done_r after DLY;

        end if;

    end process;


    -- The counter is done when bit 15 of the shift register goes high.

    watchdog_done_r <= counter5_r(15);


    -- Polarity Control --

    -- sp_polarity_c, is low if neg symbols received, otherwise high.

    sp_polarity_c <= not RX_NEG;


    -- The Polarity flop drives the polarity setting of the GTP.  We initialize it for the
    -- sake of simulation. In hardware, it is initialized after configuration.

    process (USER_CLK)

    begin

        if (USER_CLK 'event and USER_CLK = '1') then

            if (polarity_r = '1' and sp_polarity_c = '0') then

                rx_polarity_r <= not rx_polarity_r after DLY;

            end if;

        end if;

    end process;


    -- Drive the rx_polarity register value on the interface.

    RX_POLARITY_Buffer <= rx_polarity_r;

end RTL;
