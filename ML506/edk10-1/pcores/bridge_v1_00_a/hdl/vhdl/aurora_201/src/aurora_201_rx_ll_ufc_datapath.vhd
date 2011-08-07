--
--      Project:  Aurora Module Generator version 2.8
--
--         Date:  $Date: 2007/08/08 11:13:33 $
--          Tag:  $Name: i+IP+144838 $
--         File:  $RCSfile: rx_ll_ufc_datapath_vhd.ejava,v $
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
--  RX_LL_UFC_DATAPATH
--
--
--
--  Description: the RX_LL_UFC_DATAPATH module takes UFC data in Aurora format
--               and transforms it to LocalLink formatted data
--
--               This module supports 1 2-byte lane designs
--

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

entity aurora_201_RX_LL_UFC_DATAPATH is

    port (

    --Traffic Separator Interface

            UFC_DATA          : in std_logic_vector(0 to 15);
            UFC_DATA_V        : in std_logic;
            UFC_MESSAGE_START : in std_logic;
            UFC_START         : in std_logic;

    --LocalLink UFC Interface

            UFC_RX_DATA       : out std_logic_vector(0 to 15);
            UFC_RX_REM        : out std_logic;
            UFC_RX_SRC_RDY_N  : out std_logic;
            UFC_RX_SOF_N      : out std_logic;
            UFC_RX_EOF_N      : out std_logic;

    --System Interface

            USER_CLK          : in std_logic;
            RESET             : in std_logic

         );

end aurora_201_RX_LL_UFC_DATAPATH;

architecture RTL of aurora_201_RX_LL_UFC_DATAPATH is

-- Parameter Declarations --

    constant DLY : time := 1 ns;

-- External Register Declarations --

    signal UFC_RX_DATA_Buffer      : std_logic_vector(0 to 15);
    signal UFC_RX_REM_Buffer       : std_logic;
    signal UFC_RX_SRC_RDY_N_Buffer : std_logic;
    signal UFC_RX_SOF_N_Buffer     : std_logic;
    signal UFC_RX_EOF_N_Buffer     : std_logic;

-- Internal Register Declarations --

    signal  ufc_storage_data_r     : std_logic_vector(0 to 15);
    signal  ufc_storage_v_r        : std_logic;
    signal  ufc_start_r            : std_logic;
    signal  ufc_start_delayed_r    : std_logic;



begin

    UFC_RX_DATA      <= UFC_RX_DATA_Buffer;
    UFC_RX_REM       <= UFC_RX_REM_Buffer;
    UFC_RX_SRC_RDY_N <= UFC_RX_SRC_RDY_N_Buffer;
    UFC_RX_SOF_N     <= UFC_RX_SOF_N_Buffer;
    UFC_RX_EOF_N     <= UFC_RX_EOF_N_Buffer;

-- Main Body of Code --


    -- All input goes into a storage register before it is sent on to the output.
    process (USER_CLK)
    begin
        if (USER_CLK 'event and USER_CLK = '1') then
            ufc_storage_data_r <= UFC_DATA after DLY;
        end if;
    end process;


    -- Keep track of whether or not there is data in storage.
    process (USER_CLK)
    begin
        if (USER_CLK 'event and USER_CLK = '1') then
            if (RESET = '1') then
                ufc_storage_v_r <= '0' after DLY;
            else
                ufc_storage_v_r <= UFC_DATA_V after DLY;
            end if;
        end if;
    end process;


    -- Output data is registered.
    process (USER_CLK)
    begin
        if (USER_CLK 'event and USER_CLK = '1') then
            UFC_RX_DATA_Buffer <= ufc_storage_data_r after DLY;
        end if;
    end process;


    -- Assert the UFC_RX_SRC_RDY_N signal when there is data in storage.
    process (USER_CLK)
    begin
        if (USER_CLK 'event and USER_CLK = '1') then
            if (RESET = '1') then
                UFC_RX_SRC_RDY_N_Buffer <= '1' after DLY;
            else
                UFC_RX_SRC_RDY_N_Buffer <= not ufc_storage_v_r after DLY;
            end if;
        end if;
    end process;


    -- Hold start of frame until it can be asserted with data.
    process (USER_CLK)
    begin
        if (USER_CLK 'event and USER_CLK = '1') then
            ufc_start_r         <= UFC_START after DLY;
            ufc_start_delayed_r <= ufc_start_r after DLY;
        end if;
    end process;


    -- Register the start of frame signal for use with the LocalLink output.
    process (USER_CLK)
    begin
        if (USER_CLK 'event and USER_CLK = '1') then
            UFC_RX_SOF_N_Buffer <= not ufc_start_delayed_r after DLY;
        end if;
    end process;


    -- Assert EOF when the storage goes from full to empty.
    process (USER_CLK)
    begin
        if (USER_CLK 'event and USER_CLK = '1') then
            UFC_RX_EOF_N_Buffer <= not (not UFC_DATA_V and ufc_storage_v_r) after DLY;
        end if;
    end process;


    -- REM is always high in the single lane case.
    UFC_RX_REM_Buffer <= '1';

end RTL;
