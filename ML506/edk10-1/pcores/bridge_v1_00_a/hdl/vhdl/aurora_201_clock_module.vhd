--
--      Project:  Aurora Module Generator version 2.8
--
--         Date:  $Date: 2007/08/08 11:13:33 $
--          Tag:  $Name: i+IP+144838 $
--         File:  $RCSfile: clock_module_gtp_vhd.ejava,v $
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
--  CLOCK_MODULE
--
--
--                    Xilinx - Garden Valley Design Team
--
--  Description: A module provided as a convenience for desingners using 4-byte
--               lane Aurora Modules. This module takes the GTP reference clock as
--               input, and produces a divided clock on a global clock net suitable
--               for driving application logic connected to the Aurora User Interface.
--

library IEEE;
use IEEE.STD_LOGIC_1164.all;

-- synthesis translate_off
library UNISIM;
use UNISIM.all;
-- synthesis translate_on

entity aurora_201_CLOCK_MODULE is

    port (

            GTP_CLK                 : in std_logic;
            GTP_CLK_LOCKED          : in std_logic;
            USER_CLK                : out std_logic;
            SYNC_CLK                : out std_logic;
            DCM_NOT_LOCKED          : out std_logic

         );

end aurora_201_CLOCK_MODULE;

architecture MAPPED of aurora_201_CLOCK_MODULE is

-- External Register Declarations --

    signal USER_CLK_Buffer          : std_logic;
    signal SYNC_CLK_Buffer          : std_logic;
    signal DCM_NOT_LOCKED_Buffer    : std_logic;

-- Wire Declarations --

    signal not_connected_i          : std_logic_vector(15 downto 0);
    signal gtp_clk_not_locked_i     : std_logic;
    signal clkfb_i                  : std_logic;
    signal clkdv_i                  : std_logic;
    signal clk0_i                   : std_logic;
    signal locked_i                 : std_logic;

    signal tied_to_ground_i         : std_logic;

-- Component Declarations --

    component DCM


        generic (CLKDV_DIVIDE            : real       := 2.0;
                 CLKFX_DIVIDE            : integer    := 1;
                 CLKFX_MULTIPLY          : integer    := 4;
                 CLKIN_DIVIDE_BY_2       : boolean    := false;
                 CLKIN_PERIOD            : real       := 0.0;                  --non-simulatable
                 CLKOUT_PHASE_SHIFT      : string     := "NONE";
                 CLK_FEEDBACK            : string     := "1X";
                 DESKEW_ADJUST           : string     := "SYSTEM_SYNCHRONOUS"; --non-simulatable
                 DFS_FREQUENCY_MODE      : string     := "LOW";
                 DLL_FREQUENCY_MODE      : string     := "LOW";
                 DSS_MODE                : string     := "NONE";               --non-simulatable
                 DUTY_CYCLE_CORRECTION   : boolean    := true;
                 FACTORY_JF              : bit_vector := X"C080";              --non-simulatable
                 PHASE_SHIFT             : integer    := 0;
                 STARTUP_WAIT            : boolean    := false);               --non-simulatable


        port (
                CLK0     : out std_ulogic                   := '0';
                CLK180   : out std_ulogic                   := '0';
                CLK270   : out std_ulogic                   := '0';
                CLK2X    : out std_ulogic                   := '0';
                CLK2X180 : out std_ulogic                   := '0';
                CLK90    : out std_ulogic                   := '0';
                CLKDV    : out std_ulogic                   := '0';
                CLKFX    : out std_ulogic                   := '0';
                CLKFX180 : out std_ulogic                   := '0';
                LOCKED   : out std_ulogic                   := '0';
                PSDONE   : out std_ulogic                   := '0';
                STATUS   : out std_logic_vector(7 downto 0) := "00000000";
                CLKFB    : in std_ulogic                    := '0';
                CLKIN    : in std_ulogic                    := '0';
                DSSEN    : in std_ulogic                    := '0';
                PSCLK    : in std_ulogic                    := '0';
                PSEN     : in std_ulogic                    := '0';
                PSINCDEC : in std_ulogic                    := '0';
                RST      : in std_ulogic                    := '0'
             );

    end component;


    component BUFG

        port (

                O : out std_ulogic;
                I : in  std_ulogic

             );

    end component;


    component INV

        port (

                O : out std_ulogic;
                I : in  std_ulogic

             );

    end component;

begin

    USER_CLK       <= USER_CLK_Buffer;
    SYNC_CLK       <= clkfb_i;
    DCM_NOT_LOCKED <= DCM_NOT_LOCKED_Buffer;

    tied_to_ground_i <= '0';

-- ************************Main Body of Code *************************--


    -- Invert the GTP_CLK_LOCKED signal
    gtp_clk_not_locked_i    <=  not GTP_CLK_LOCKED;

    -- Instantiate a DCM module to divide the reference clock.

    clock_divider_i : DCM
       generic map(
        CLKDV_DIVIDE               =>  2.0,
        DFS_FREQUENCY_MODE         => "LOW",
        DLL_FREQUENCY_MODE         => "LOW"
                 )
        port map (

                    CLK0     => clk0_i,
                    CLK180   => open,
                    CLK270   => open,
                    CLK2X    => open,
                    CLK2X180 => open,
                    CLK90    => open,
                    CLKDV    => clkdv_i,
                    CLKFX    => open,
                    CLKFX180 => open,
                    LOCKED   => locked_i,
                    PSDONE   => open,
                    STATUS   => open,
                    CLKFB    => clkfb_i,
                    CLKIN    => GTP_CLK,
                    DSSEN    => tied_to_ground_i,
                    PSCLK    => tied_to_ground_i,
                    PSEN     => tied_to_ground_i,
                    PSINCDEC => tied_to_ground_i,
                    RST      => gtp_clk_not_locked_i

                 );


    -- BUFG for the feedback clock.  The feedback signal is phase aligned to the input
    -- and must come from the CLK0 or CLK2X output of the DCM.  In this case, we use
    -- the CLK0 output.

    feedback_clock_net_i : BUFG

        port map (

                    I => clk0_i,
                    O => clkfb_i

                 );



    -- The User Clock is distributed on a global clock net.

    sync_clk_net_i : BUFG

        port map (

                    I => clkdv_i,
                    O => USER_CLK_Buffer

                 );


    -- The DCM_NOT_LOCKED signal is created by inverting the DCM's locked signal.

    DCM_NOT_LOCKED_Buffer <= not locked_i;


end MAPPED;
