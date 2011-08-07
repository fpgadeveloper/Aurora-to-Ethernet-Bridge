--
--      Project:  Aurora Module Generator version 2.8
--
--         Date:  $Date: 2007/08/08 11:13:34 $
--          Tag:  $Name: i+IP+144838 $
--         File:  $RCSfile: ufc_filter_vhd.ejava,v $
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
--  UFC_FILTER
--
--
--
--  Description: The UFC module separates data into UFC data and regular data.
--
--               This module supports 1 2-byte lane designs.
--

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use WORK.AURORA_PKG.all;

entity aurora_201_UFC_FILTER is

    port (

    -- Aurora Channel Interface

            RX_PAD            : in std_logic;
            RX_PE_DATA        : in std_logic_vector(0 to 15);
            RX_PE_DATA_V      : in std_logic;
            RX_SCP            : in std_logic;
            RX_ECP            : in std_logic;
            RX_SUF            : in std_logic;
            RX_FC_NB          : in std_logic_vector(0 to 3);

    -- PDU Datapath Interface

            PDU_DATA          : out std_logic_vector(0 to 15);
            PDU_DATA_V        : out std_logic;
            PDU_PAD           : out std_logic;
            PDU_SCP           : out std_logic;
            PDU_ECP           : out std_logic;

    -- UFC Datapath Interface

            UFC_DATA          : out std_logic_vector(0 to 15);
            UFC_DATA_V        : out std_logic;
            UFC_MESSAGE_START : out std_logic;
            UFC_START         : out std_logic;

    -- System Interface

            USER_CLK          : in std_logic;
            RESET             : in std_logic

         );

end aurora_201_UFC_FILTER;

architecture RTL of aurora_201_UFC_FILTER is

-- Parameter Declarations --

    constant DLY : time := 1 ns;

-- External Register Declarations --

    signal PDU_DATA_Buffer          : std_logic_vector(0 to 15);
    signal PDU_DATA_V_Buffer        : std_logic;
    signal PDU_PAD_Buffer           : std_logic;
    signal PDU_SCP_Buffer           : std_logic;
    signal PDU_ECP_Buffer           : std_logic;
    signal UFC_DATA_Buffer          : std_logic_vector(0 to 15);
    signal UFC_DATA_V_Buffer        : std_logic;
    signal UFC_MESSAGE_START_Buffer : std_logic;
    signal UFC_START_Buffer         : std_logic;

-- Internal Register Declarations --

    signal ufc_command_decode_c            : std_logic_vector(0 to 3);
    signal ufc_count_r                     : std_logic_vector(0 to 3);

begin

    PDU_DATA          <= PDU_DATA_Buffer;
    PDU_DATA_V        <= PDU_DATA_V_Buffer;
    PDU_PAD           <= PDU_PAD_Buffer;
    PDU_SCP           <= PDU_SCP_Buffer;
    PDU_ECP           <= PDU_ECP_Buffer;
    UFC_DATA          <= UFC_DATA_Buffer;
    UFC_DATA_V        <= UFC_DATA_V_Buffer;
    UFC_MESSAGE_START <= UFC_MESSAGE_START_Buffer;
    UFC_START         <= UFC_START_Buffer;

-- Main Body of Code --

    -- UFC data is invalid pdu data.

    PDU_DATA_V_Buffer <= RX_PE_DATA_V and std_bool(ufc_count_r = "0000");


    -- The UFC counter is a 4 bit counter that is loaded only when an SUF arrives.

    process (USER_CLK)

    begin

        if (USER_CLK 'event and USER_CLK = '1') then

            if (RESET = '1') then

                ufc_count_r <= "0000" after DLY;

            else

                if (RX_SUF = '1') then

                    ufc_count_r <= ufc_command_decode_c after DLY;

                else

                    if (ufc_count_r > 0) then

                        ufc_count_r <= ufc_count_r - "0001";

                    end if;

                end if;

            end if;

        end if;

    end process;


    -- The command decoder for UFC converts the FC_NB code to a starting count value.

    process (RX_FC_NB)

    begin

        case RX_FC_NB(0 to 2) is

            when "000" =>

                ufc_command_decode_c <= "0001";

            when "001" =>

                ufc_command_decode_c <= "0010";

            when "010" =>

                ufc_command_decode_c <= "0011";

            when "011" =>

                ufc_command_decode_c <= "0100";

            when "100" =>

                ufc_command_decode_c <= "0101";

            when "101" =>

                ufc_command_decode_c <= "0110";

            when "110" =>

                ufc_command_decode_c <= "0111";

            when "111" =>

                ufc_command_decode_c <= "1000";

            when others =>

                ufc_command_decode_c <= "0000";

        end case;

    end process;


    --Pipe the remaining signals through.

    PDU_PAD_Buffer           <= RX_PAD;
    PDU_DATA_Buffer          <= RX_PE_DATA;
    PDU_SCP_Buffer           <= RX_SCP;
    PDU_ECP_Buffer           <= RX_ECP;

    UFC_DATA_Buffer          <= RX_PE_DATA;
    UFC_DATA_V_Buffer        <= std_bool(ufc_count_r > "0000");
    UFC_MESSAGE_START_Buffer <= RX_SUF;
    UFC_START_Buffer         <= RX_SUF;

end RTL;
