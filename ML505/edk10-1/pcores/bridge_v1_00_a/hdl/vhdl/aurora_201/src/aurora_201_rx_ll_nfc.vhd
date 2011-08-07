--
--      Project:  Aurora Module Generator version 2.8
--
--         Date:  $Date: 2007/08/08 11:13:33 $
--          Tag:  $Name: i+IP+144838 $
--         File:  $RCSfile: rx_ll_nfc_vhd.ejava,v $
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
--  RX_LL_NFC
--
--
--
--  Description: the RX_LL_NFC module detects, decodes and executes NFC messages
--               from the channel partner. When a message is recieved, the module
--               signals the TX_LL module that idles are required until the number
--               of idles the TX_LL module sends are enough to fulfil the request.
--
--               This module supports 1 2-byte lane designs
--

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use WORK.AURORA_PKG.all;

entity aurora_201_RX_LL_NFC is

    port (

    -- Aurora Lane Interface

            RX_SNF        : in  std_logic;
            RX_FC_NB      : in  std_logic_vector(0 to 3);

    -- TX_LL Interface

            DECREMENT_NFC : in  std_logic;
            TX_WAIT       : out std_logic;

    -- Global Logic Interface

            CHANNEL_UP    : in  std_logic;

    -- USER Interface

            USER_CLK      : in  std_logic

         );

end aurora_201_RX_LL_NFC;

architecture RTL of aurora_201_RX_LL_NFC is

-- Parameter Declarations --

    constant DLY : time := 1 ns;

-- External Register Declarations --

    signal TX_WAIT_Buffer : std_logic;

-- Internal Register Declarations --

    signal load_nfc_r           : std_logic;
    signal fcnb_r               : std_logic_vector(0 to 3);
    signal nfc_counter_r        : std_logic_vector(0 to 8);
    signal xoff_r               : std_logic;
    signal fcnb_decode_c        : std_logic_vector(0 to 8);

begin

    TX_WAIT <= TX_WAIT_Buffer;

-- Main Body of Code --

    
    -- ____________________Stage 1: Detect the most recent NFC message___________ 

    -- Generate the load NFC signal if an NFC signal is detected.

    process(USER_CLK)
    begin
        if (USER_CLK 'event and USER_CLK = '1') then
            load_nfc_r <= RX_SNF after DLY;
        end if;
    end process;


    -- Register the FC_NB signal.
    process(USER_CLK)
    begin
        if (USER_CLK 'event and USER_CLK = '1') then
            fcnb_r <= RX_FC_NB after DLY;
        end if;
    end process;


    -- _________________Stage 2: Use the FCNB code to set the counter ______________

    -- We use a counter to keep track of the number of dead cycles we must produce to
    -- satisfy the NFC request from the Channel Partner.  Note we *increment* nfc_counter
    -- when decrement NFC is asserted.  This is because the nfc counter uses the difference
    -- between the max value and the current value to determine how many cycles to demand
    -- a pause.  This allows us to use the carry chain more effectively to save LUTS, and
    -- gives us a registered output from the counter.

    process (USER_CLK)
    begin
        if (USER_CLK 'event and USER_CLK = '1') then
            if (CHANNEL_UP = '0') then
                nfc_counter_r <= "100000000" after DLY;
            else
                if (load_nfc_r = '1') then
                    nfc_counter_r <= fcnb_decode_c after DLY;
                else
                    if ((not nfc_counter_r(0) and DECREMENT_NFC and not xoff_r) = '1') then
                        nfc_counter_r <= nfc_counter_r + "000000001";
                    end if;
                end if;
            end if;
        end if;
    end process;


    -- We load the counter with a decoded version of the FCNB code.  The decode values are
    -- chosen such that the counter will assert TX_WAIT for the number of cycles required
    -- by the FCNB code.

    process (fcnb_r)
    begin
        case fcnb_r is
            when "0000" =>
                fcnb_decode_c <= "100000000"; -- XON
            when "0001" =>
                fcnb_decode_c <= "011111110"; -- 2
            when "0010" =>
                fcnb_decode_c <= "011111100"; -- 4
            when "0011" =>
                fcnb_decode_c <= "011111000"; -- 8
            when "0100" =>
                fcnb_decode_c <= "011110000"; -- 16
            when "0101" =>
                fcnb_decode_c <= "011100000"; -- 32
            when "0110" =>
                fcnb_decode_c <= "011000000"; -- 64
            when "0111" =>
                fcnb_decode_c <= "010000000"; -- 128
            when "1000" =>
                fcnb_decode_c <= "000000000"; -- 256
            when "1111" =>
                fcnb_decode_c <= "000000000"; -- 8
            when others =>
                fcnb_decode_c <= "100000000"; -- 8
        end case;
    end process;


    -- The XOFF signal forces an indefinite wait.  We decode FCNB to determine whether
    -- XOFF should be asserted.

    process (USER_CLK)
    begin
        if (USER_CLK 'event and USER_CLK = '1') then
            if (CHANNEL_UP = '0') then
                xoff_r <= '0' after DLY;
            else
                if (load_nfc_r = '1') then
                    if (fcnb_r = "1111") then
                        xoff_r <= '1' after DLY;
                    else
                        xoff_r <= '0' after DLY;
                    end if;
                end if;
            end if;
        end if;
    end process;


    -- The TXWAIT signal comes from the MSBit of the counter.  We wait whenever the counter
    -- is not at max value.

    TX_WAIT_Buffer <= not nfc_counter_r(0);

end RTL;
