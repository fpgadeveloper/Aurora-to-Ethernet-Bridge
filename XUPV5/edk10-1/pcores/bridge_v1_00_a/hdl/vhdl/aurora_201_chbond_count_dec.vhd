--
--      Project:  Aurora Module Generator version 2.8
--
--         Date:  $Date: 2007/08/08 11:13:33 $
--          Tag:  $Name: i+IP+144838 $
--         File:  $RCSfile: chbond_count_dec_gtp_vhd.ejava,v $
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
--  CHBOND_COUNT_DEC
--
--
--                    Xilinx - Garden Valley Design Team
--
--  Description: This module decodes the GTP's RXSTATUS signals. RXSTATUS[5] indicates
--               that Channel Bonding is complete
--
--               * Supports GTP
--

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use WORK.AURORA_PKG.all;

entity aurora_201_CHBOND_COUNT_DEC is

    port (

            RX_STATUS         : in std_logic_vector(5 downto 0);
            CHANNEL_BOND_LOAD : out std_logic;
            USER_CLK          : in std_logic

         );

end aurora_201_CHBOND_COUNT_DEC;

architecture RTL of aurora_201_CHBOND_COUNT_DEC is

-- Parameter Declarations --

    constant DLY : time := 1 ns;

    constant CHANNEL_BOND_LOAD_CODE : std_logic_vector(5 downto 0) := "100111"; -- Status bus code: Channel Bond load complete

-- External Register Declarations --

    signal CHANNEL_BOND_LOAD_Buffer : std_logic;

begin

    CHANNEL_BOND_LOAD <= CHANNEL_BOND_LOAD_Buffer;

-- Main Body of Code --

    process (USER_CLK)

    begin

        if (USER_CLK 'event and USER_CLK = '1') then

            CHANNEL_BOND_LOAD_Buffer <= std_bool(RX_STATUS = CHANNEL_BOND_LOAD_CODE);

        end if;

    end process;

end RTL;
