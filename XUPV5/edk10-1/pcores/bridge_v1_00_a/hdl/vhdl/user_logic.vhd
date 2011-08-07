------------------------------------------------------------------------------
-- user_logic.vhd - entity/architecture pair
------------------------------------------------------------------------------
--
-- ***************************************************************************
-- ** Copyright (c) 1995-2008 Xilinx, Inc.  All rights reserved.            **
-- **                                                                       **
-- ** Xilinx, Inc.                                                          **
-- ** XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION "AS IS"         **
-- ** AS A COURTESY TO YOU, SOLELY FOR USE IN DEVELOPING PROGRAMS AND       **
-- ** SOLUTIONS FOR XILINX DEVICES.  BY PROVIDING THIS DESIGN, CODE,        **
-- ** OR INFORMATION AS ONE POSSIBLE IMPLEMENTATION OF THIS FEATURE,        **
-- ** APPLICATION OR STANDARD, XILINX IS MAKING NO REPRESENTATION           **
-- ** THAT THIS IMPLEMENTATION IS FREE FROM ANY CLAIMS OF INFRINGEMENT,     **
-- ** AND YOU ARE RESPONSIBLE FOR OBTAINING ANY RIGHTS YOU MAY REQUIRE      **
-- ** FOR YOUR IMPLEMENTATION.  XILINX EXPRESSLY DISCLAIMS ANY              **
-- ** WARRANTY WHATSOEVER WITH RESPECT TO THE ADEQUACY OF THE               **
-- ** IMPLEMENTATION, INCLUDING BUT NOT LIMITED TO ANY WARRANTIES OR        **
-- ** REPRESENTATIONS THAT THIS IMPLEMENTATION IS FREE FROM CLAIMS OF       **
-- ** INFRINGEMENT, IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS       **
-- ** FOR A PARTICULAR PURPOSE.                                             **
-- **                                                                       **
-- ***************************************************************************
--
------------------------------------------------------------------------------
-- Filename:          user_logic.vhd
-- Version:           1.00.a
-- Description:       User logic.
-- Date:              Wed Sep 23 10:41:11 2009 (by Create and Import Peripheral Wizard)
-- VHDL Standard:     VHDL'93
------------------------------------------------------------------------------
-- Naming Conventions:
--   active low signals:                    "*_n"
--   clock signals:                         "clk", "clk_div#", "clk_#x"
--   reset signals:                         "rst", "rst_n"
--   generics:                              "C_*"
--   user defined types:                    "*_TYPE"
--   state machine next state:              "*_ns"
--   state machine current state:           "*_cs"
--   combinatorial signals:                 "*_com"
--   pipelined or register delay signals:   "*_d#"
--   counter signals:                       "*cnt*"
--   clock enable signals:                  "*_ce"
--   internal version of output port:       "*_i"
--   device pins:                           "*_pin"
--   ports:                                 "- Names begin with Uppercase"
--   processes:                             "*_PROCESS"
--   component instantiations:              "<ENTITY_>I_<#|FUNC>"
------------------------------------------------------------------------------

-- DO NOT EDIT BELOW THIS LINE --------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library proc_common_v2_00_a;
use proc_common_v2_00_a.proc_common_pkg.all;

-- DO NOT EDIT ABOVE THIS LINE --------------------

--USER libraries added here
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;

------------------------------------------------------------------------------
-- Entity section
------------------------------------------------------------------------------
-- Definition of Generics:
--   C_SLV_DWIDTH                 -- Slave interface data bus width
--   C_NUM_REG                    -- Number of software accessible registers
--
-- Definition of Ports:
--   Bus2IP_Clk                   -- Bus to IP clock
--   Bus2IP_Reset                 -- Bus to IP reset
--   Bus2IP_Data                  -- Bus to IP data bus
--   Bus2IP_BE                    -- Bus to IP byte enables
--   Bus2IP_RdCE                  -- Bus to IP read chip enable
--   Bus2IP_WrCE                  -- Bus to IP write chip enable
--   IP2Bus_Data                  -- IP to Bus data bus
--   IP2Bus_RdAck                 -- IP to Bus read transfer acknowledgement
--   IP2Bus_WrAck                 -- IP to Bus write transfer acknowledgement
--   IP2Bus_Error                 -- IP to Bus error response
------------------------------------------------------------------------------

entity user_logic is
  generic
  (
    -- ADD USER GENERICS BELOW THIS LINE ---------------
    --USER generics added here
    -- ADD USER GENERICS ABOVE THIS LINE ---------------

    -- DO NOT EDIT BELOW THIS LINE ---------------------
    -- Bus protocol parameters, do not add to or delete
    C_SLV_DWIDTH                   : integer              := 32;
    C_NUM_REG                      : integer              := 1
    -- DO NOT EDIT ABOVE THIS LINE ---------------------
  );
  port
  (
    -- ADD USER PORTS BELOW THIS LINE ------------------
    REFCLK_N_IN                    : in std_logic;
    REFCLK_P_IN                    : in std_logic;
	 EMAC_READY                     : out std_logic;
	 PHY_RESET_0                    : out std_logic;
    HARD_ERROR                     : out std_logic;
    SOFT_ERROR                     : out std_logic;
    FRAME_ERROR                    : out std_logic;
    LANE_UP                        : out std_logic;
    CHANNEL_UP                     : out std_logic;
    RXP_IN                         : in std_logic_vector(1 downto 0);
    RXN_IN                         : in std_logic_vector(1 downto 0);
    TXP_OUT                        : out std_logic_vector(1 downto 0);
    TXN_OUT                        : out std_logic_vector(1 downto 0);
    -- ADD USER PORTS ABOVE THIS LINE ------------------

    -- DO NOT EDIT BELOW THIS LINE ---------------------
    -- Bus protocol ports, do not add to or delete
    Bus2IP_Clk                     : in  std_logic;
    Bus2IP_Reset                   : in  std_logic;
    Bus2IP_Data                    : in  std_logic_vector(0 to C_SLV_DWIDTH-1);
    Bus2IP_BE                      : in  std_logic_vector(0 to C_SLV_DWIDTH/8-1);
    Bus2IP_RdCE                    : in  std_logic_vector(0 to C_NUM_REG-1);
    Bus2IP_WrCE                    : in  std_logic_vector(0 to C_NUM_REG-1);
    IP2Bus_Data                    : out std_logic_vector(0 to C_SLV_DWIDTH-1);
    IP2Bus_RdAck                   : out std_logic;
    IP2Bus_WrAck                   : out std_logic;
    IP2Bus_Error                   : out std_logic
    -- DO NOT EDIT ABOVE THIS LINE ---------------------
  );

  attribute SIGIS : string;
  attribute SIGIS of Bus2IP_Clk    : signal is "CLK";
  attribute SIGIS of Bus2IP_Reset  : signal is "RST";

end entity user_logic;

------------------------------------------------------------------------------
-- Architecture section
------------------------------------------------------------------------------

architecture IMP of user_logic is

  --USER signal declarations added here, as needed for user logic
  -- Clock signals
  signal ref_clk            : std_logic;
  signal user_clk_eth	    : std_logic;
  signal user_clk_out       : std_logic;

  -- Reset signals
  signal rst_gtp            : std_logic;
  signal rst_fifos          : std_logic;
  signal reset_aurora       : std_logic;
  signal pre_reset_aurora   : std_logic_vector(5 downto 0);

  -- Registers for the status outputs
  signal HARD_ERROR_Buffer  : std_logic;
  signal SOFT_ERROR_Buffer  : std_logic;
  signal FRAME_ERROR_Buffer : std_logic;
  signal LANE_UP_Buffer     : std_logic;
  signal CHANNEL_UP_Buffer  : std_logic;

  -- LocalLink TX Interface
  signal tx_d_i             : std_logic_vector(0 to 15);
  signal tx_rem_i           : std_logic;
  signal tx_src_rdy_n_i     : std_logic;
  signal tx_sof_n_i         : std_logic;
  signal tx_eof_n_i         : std_logic;
  signal tx_dst_rdy_n_i     : std_logic;

  -- LocalLink RX Interface
  signal rx_d_i             : std_logic_vector(0 to 15);
  signal rx_rem_i           : std_logic;
  signal rx_src_rdy_n_i     : std_logic;
  signal rx_sof_n_i         : std_logic;
  signal rx_eof_n_i         : std_logic;

  -- Error Detection Interface
  signal hard_error_i       : std_logic;
  signal soft_error_i       : std_logic;
  signal frame_error_i      : std_logic;

  -- Status
  signal channel_up_i       : std_logic;
  signal lane_up_i          : std_logic;
  signal lane_up_i_i        : std_logic;

  -- Clock Compensation Control Interface
  signal warn_cc_i          : std_logic;
  signal do_cc_i            : std_logic;

  -- System Interface
  signal dcm_not_locked_i   : std_logic;
  signal user_clk_aur       : std_logic;
  signal sync_clk_i         : std_logic;
  signal power_down_i       : std_logic;
  signal loopback_i         : std_logic_vector(0 to 2);
  signal tx_lock_i          : std_logic;
  signal tx_out_clk_i       : std_logic;
  signal buf_tx_out_clk_i   : std_logic; 

  -- Aurora Component Declarations

  component aurora_201_CLOCK_MODULE
  port (
      GTP_CLK        : in std_logic;
      GTP_CLK_LOCKED : in std_logic;
      USER_CLK       : out std_logic;
      SYNC_CLK       : out std_logic;
      DCM_NOT_LOCKED : out std_logic
    );
  end component;

  component aurora_201
  generic(
        SIM_GTPRESET_SPEEDUP :integer := 0
    );
  port(
      -- LocalLink TX Interface
        TX_D             : in std_logic_vector(0 to 15);
        TX_REM           : in std_logic;
        TX_SRC_RDY_N     : in std_logic;
        TX_SOF_N         : in std_logic;
        TX_EOF_N         : in std_logic;
        TX_DST_RDY_N     : out std_logic;
      -- LocalLink RX Interface
        RX_D             : out std_logic_vector(0 to 15);
        RX_REM           : out std_logic;
        RX_SRC_RDY_N     : out std_logic;
        RX_SOF_N         : out std_logic;
        RX_EOF_N         : out std_logic;
      -- GTP Serial I/O
        RXP              : in std_logic;
        RXN              : in std_logic;
        TXP              : out std_logic;
        TXN              : out std_logic;
      -- GTP Reference Clock Interface
        GTPD1            : in std_logic;
      -- Error Detection Interface
        HARD_ERROR       : out std_logic;
        SOFT_ERROR       : out std_logic;
        FRAME_ERROR      : out std_logic;
      -- Status
        CHANNEL_UP       : out std_logic;
        LANE_UP          : out std_logic;
      -- Clock Compensation Control Interface
        WARN_CC          : in std_logic;
        DO_CC            : in std_logic;
      -- System Interface
        DCM_NOT_LOCKED   : in std_logic;
        USER_CLK         : in std_logic;
        SYNC_CLK         : in std_logic;
        PMA_INIT         : in std_logic;
        RESET            : in std_logic;
        POWER_DOWN       : in std_logic;
        LOOPBACK         : in std_logic_vector(2 downto 0);
        TX_LOCK          : out std_logic;
        TX_OUT_CLK       : out std_logic
    );
  end component;

  component aurora_201_STANDARD_CC_MODULE
  port(
      -- Clock Compensation Control Interface
        WARN_CC        : out std_logic;
        DO_CC          : out std_logic;
      -- System Interface
        DCM_NOT_LOCKED : in std_logic;
        USER_CLK       : in std_logic;
        CHANNEL_UP     : in std_logic
    );
  end component;

  -- EMAC Component Declarations

  -- Component Declaration for the TEMAC wrapper with 
  -- Local Link FIFO.
  component v5_emac_v1_5_locallink is
   port(
      -- EMAC0 Clocking
      -- 125MHz clock output from transceiver
      CLK125_OUT                : out std_logic;
      -- 125MHz clock input from BUFG
      CLK125                    : in  std_logic;
      -- Tri-speed clock output from EMAC0
      CLIENT_CLK_OUT_0          : out std_logic;
      -- EMAC0 Tri-speed clock input from BUFG
      client_clk_0              : in  std_logic;

      -- Local link Receiver Interface - EMAC0
      RX_LL_CLOCK_0             : in  std_logic; 
      RX_LL_RESET_0             : in  std_logic;
      RX_LL_DATA_0              : out std_logic_vector(7 downto 0);
      RX_LL_SOF_N_0             : out std_logic;
      RX_LL_EOF_N_0             : out std_logic;
      RX_LL_SRC_RDY_N_0         : out std_logic;
      RX_LL_DST_RDY_N_0         : in  std_logic;
      RX_LL_FIFO_STATUS_0       : out std_logic_vector(3 downto 0);

      -- Local link Transmitter Interface - EMAC0
      TX_LL_CLOCK_0             : in  std_logic;
      TX_LL_RESET_0             : in  std_logic;
      TX_LL_DATA_0              : in  std_logic_vector(7 downto 0);
      TX_LL_SOF_N_0             : in  std_logic;
      TX_LL_EOF_N_0             : in  std_logic;
      TX_LL_SRC_RDY_N_0         : in  std_logic;
      TX_LL_DST_RDY_N_0         : out std_logic;

      -- Client Receiver Interface - EMAC0
      EMAC0CLIENTRXDVLD         : out std_logic;
      EMAC0CLIENTRXFRAMEDROP    : out std_logic;
      EMAC0CLIENTRXSTATS        : out std_logic_vector(6 downto 0);
      EMAC0CLIENTRXSTATSVLD     : out std_logic;
      EMAC0CLIENTRXSTATSBYTEVLD : out std_logic;

      -- Client Transmitter Interface - EMAC0
      CLIENTEMAC0TXIFGDELAY     : in  std_logic_vector(7 downto 0);
      EMAC0CLIENTTXSTATS        : out std_logic;
      EMAC0CLIENTTXSTATSVLD     : out std_logic;
      EMAC0CLIENTTXSTATSBYTEVLD : out std_logic;

      -- MAC Control Interface - EMAC0
      CLIENTEMAC0PAUSEREQ       : in  std_logic;
      CLIENTEMAC0PAUSEVAL       : in  std_logic_vector(15 downto 0);

      --EMAC-MGT link status
      EMAC0CLIENTSYNCACQSTATUS  : out std_logic;

      -- EMAC0 Interrupt
      EMAC0ANINTERRUPT          : out std_logic;

      -- Clock Signals - EMAC0

      -- SGMII Interface - EMAC0
      TXP_0                     : out std_logic;
      TXN_0                     : out std_logic;
      RXP_0                     : in  std_logic;
      RXN_0                     : in  std_logic;
      PHYAD_0                   : in  std_logic_vector(4 downto 0);
      RESETDONE_0               : out std_logic;

      -- unused transceiver
      TXN_1_UNUSED              : out std_logic;
      TXP_1_UNUSED              : out std_logic;
      RXN_1_UNUSED              : in  std_logic;
      RXP_1_UNUSED              : in  std_logic;

      -- SGMII RocketIO Reference Clock buffer inputs 
      CLK_DS                    : in  std_logic;
        
      -- Asynchronous Reset
      RESET                     : in  std_logic
   );
  end component;
 
  -- EMAC Signal Declarations

  -- address swap transmitter connections - EMAC0
  signal tx_ll_data_0_i      : std_logic_vector(7 downto 0);
  signal tx_ll_sof_n_0_i     : std_logic;
  signal tx_ll_eof_n_0_i     : std_logic;
  signal tx_ll_src_rdy_n_0_i : std_logic;
  signal tx_ll_dst_rdy_n_0_i : std_logic;

  -- address swap receiver connections - EMAC0
  signal rx_ll_data_0_i           : std_logic_vector(7 downto 0);
  signal rx_ll_sof_n_0_i          : std_logic;
  signal rx_ll_eof_n_0_i          : std_logic;
  signal rx_ll_src_rdy_n_0_i      : std_logic;
  signal rx_ll_dst_rdy_n_0_i      : std_logic;
  signal rx_ll_fifo_status_0_i    : std_logic_vector(3 downto 0);

  -- create a synchronous reset in the transmitter clock domain
  signal ll_pre_reset_0_i          : std_logic_vector(5 downto 0);
  signal ll_reset_0_i              : std_logic;

  attribute async_reg : string;
  attribute async_reg of ll_pre_reset_0_i : signal is "true";

  signal resetdone_0_i             : std_logic;

  -- EMAC0 Clocking signals

  -- 1.25/12.5/125MHz clock signals for tri-speed SGMII
  signal client_clk_0_o            : std_logic;
  signal client_clk_0              : std_logic;

  -- Clock Domain Crossing FIFO declarations

  -- FIFO 32 bit to 16 bit
  signal fifo1_din            : std_logic_VECTOR(31 downto 0);
  signal fifo1_rd_en          : std_logic;
  signal fifo1_wr_en          : std_logic;
  signal fifo1_almost_full    : std_logic;
  signal fifo1_dout           : std_logic_VECTOR(15 downto 0);
  signal fifo1_valid          : std_logic;

  component fifo_32b_to_16b
  port (
    din            : IN std_logic_VECTOR(31 downto 0);
    rd_clk         : IN std_logic;
    rd_en          : IN std_logic;
    rst            : IN std_logic;
    wr_clk         : IN std_logic;
    wr_en          : IN std_logic;
    almost_full    : OUT std_logic;
    dout           : OUT std_logic_VECTOR(15 downto 0);
    empty          : OUT std_logic;
    full           : OUT std_logic;
    valid          : OUT std_logic);
  end component;
 
  -- FIFO 16 bit to 32 bit
  signal fifo2_din            : std_logic_VECTOR(15 downto 0);
  signal fifo2_rd_en          : std_logic;
  signal fifo2_wr_en          : std_logic;
  signal fifo2_almost_full    : std_logic;
  signal fifo2_dout           : std_logic_VECTOR(31 downto 0);
  signal fifo2_valid          : std_logic;
  signal fifo2_full           : std_logic;
  signal odd_bytes            : std_logic;
  signal insert_blank         : std_logic;

  component fifo_16b_to_32b
  port (
    din            : IN std_logic_VECTOR(15 downto 0);
    rd_clk         : IN std_logic;
    rd_en          : IN std_logic;
    rst            : IN std_logic;
    wr_clk         : IN std_logic;
    wr_en          : IN std_logic;
    almost_full    : OUT std_logic;
    dout           : OUT std_logic_VECTOR(31 downto 0);
    empty          : OUT std_logic;
    full           : OUT std_logic;
    valid          : OUT std_logic);
  end component;
 
  ------------------------------------------
  -- Signals for user logic slave model s/w accessible register example
  ------------------------------------------
  signal slv_reg0                       : std_logic_vector(0 to C_SLV_DWIDTH-1);
  signal slv_reg_write_sel              : std_logic_vector(0 to 0);
  signal slv_reg_read_sel               : std_logic_vector(0 to 0);
  signal slv_ip2bus_data                : std_logic_vector(0 to C_SLV_DWIDTH-1);
  signal slv_read_ack                   : std_logic;
  signal slv_write_ack                  : std_logic;

begin

  --USER logic implementation added here
  -- Clock buffering

  ref_clk_ibufds_i : IBUFDS
  port map(
      O  => ref_clk,
      I  => REFCLK_P_IN,
      IB => REFCLK_N_IN
  );

  emac_out_clk_bufg_i : BUFG
  port map(
      I  => user_clk_out,
      O  => user_clk_eth
  );

  aurora_out_clk_bufg_i : BUFG
  port map(
      I  => tx_out_clk_i,
      O  => buf_tx_out_clk_i
  );

  -- Aurora clock module for clock division
  clock_module_i : aurora_201_CLOCK_MODULE
  port map(
      GTP_CLK        => buf_tx_out_clk_i,
      GTP_CLK_LOCKED => tx_lock_i,
      USER_CLK       => user_clk_aur,
      SYNC_CLK       => sync_clk_i,
      DCM_NOT_LOCKED => dcm_not_locked_i
  );

  -- Reset logic
  rst_gtp <= Bus2IP_Reset;
  rst_fifos <= ll_reset_0_i or reset_aurora;
  PHY_RESET_0 <= not rst_gtp;

  -- 1.25/12.5/125MHz clock from the MAC is routed through a BUFG and  
  -- input to the MAC wrappers to clock the client interface.
  bufg_client_0 : BUFG port map (I => client_clk_0_o, O => client_clk_0);

  -- Status outputs
  HARD_ERROR  <= HARD_ERROR_Buffer;
  SOFT_ERROR  <= SOFT_ERROR_Buffer;
  FRAME_ERROR <= FRAME_ERROR_Buffer;
  LANE_UP     <= LANE_UP_Buffer;
  CHANNEL_UP  <= CHANNEL_UP_Buffer;

  -- Register Status Outputs from core
  process (user_clk_aur)
  begin
    if (user_clk_aur 'event and user_clk_aur = '1') then
      HARD_ERROR_Buffer  <= hard_error_i;
      SOFT_ERROR_Buffer  <= soft_error_i;
      FRAME_ERROR_Buffer <= frame_error_i;
      LANE_UP_Buffer     <= lane_up_i;
      CHANNEL_UP_Buffer  <= channel_up_i;
    end if;
  end process;

  -- System Interface
  power_down_i     <= '0';
  loopback_i       <= "00" & slv_reg0(31);

  -- Aurora Module Instantiation
  aurora_module_i : aurora_201
  port map(
    -- LocalLink TX Interface
      TX_D             => tx_d_i,
      TX_REM           => tx_rem_i,
      TX_SRC_RDY_N     => tx_src_rdy_n_i,
      TX_SOF_N         => tx_sof_n_i,
      TX_EOF_N         => tx_eof_n_i,
      TX_DST_RDY_N     => tx_dst_rdy_n_i,

    -- LocalLink RX Interface
      RX_D             => rx_d_i,
      RX_REM           => rx_rem_i,
      RX_SRC_RDY_N     => rx_src_rdy_n_i,
      RX_SOF_N         => rx_sof_n_i,
      RX_EOF_N         => rx_eof_n_i,

    -- GTP Serial I/O
      RXP              => RXP_IN(0),
      RXN              => RXN_IN(0),
      TXP              => TXP_OUT(0),
      TXN              => TXN_OUT(0),

    -- GTP Reference Clock Interface
      GTPD1            => ref_clk,

    -- Error Detection Interface
      HARD_ERROR       => hard_error_i,
      SOFT_ERROR       => soft_error_i,
      FRAME_ERROR      => frame_error_i,

    -- Status
      CHANNEL_UP       => channel_up_i,
      LANE_UP          => lane_up_i,

    -- Clock Compensation Control Interface
      WARN_CC          => warn_cc_i,
      DO_CC            => do_cc_i,

    -- System Interface
      DCM_NOT_LOCKED   => dcm_not_locked_i,
      USER_CLK         => user_clk_aur,
      SYNC_CLK         => sync_clk_i,
      RESET            => reset_aurora,
      POWER_DOWN       => power_down_i,
      LOOPBACK         => loopback_i,
      PMA_INIT         => rst_gtp,
      TX_LOCK          => tx_lock_i,
      TX_OUT_CLK       => tx_out_clk_i
  );

  standard_cc_module_i : aurora_201_STANDARD_CC_MODULE
  port map (
    -- Clock Compensation Control Interface
      WARN_CC        => warn_cc_i,
      DO_CC          => do_cc_i,
    -- System Interface
      DCM_NOT_LOCKED => dcm_not_locked_i,
      USER_CLK       => user_clk_aur,
      CHANNEL_UP     => channel_up_i
  );

  -- Create synchronous reset in the USER_CLK_AUR domain
  gen_reset_aurora : process (user_clk_aur, rst_gtp)
  begin
    if rst_gtp = '1' then
      pre_reset_aurora <= (others => '1');
      reset_aurora <= '1';
    elsif user_clk_aur'event and user_clk_aur = '1' then
      if tx_lock_i = '1' then
        pre_reset_aurora(0)          <= '0';
        pre_reset_aurora(5 downto 1) <= pre_reset_aurora(4 downto 0);
        reset_aurora                 <= pre_reset_aurora(5);
      end if;
    end if;
  end process gen_reset_aurora;

  ------------------------------------------------------------------------
  -- Instantiate the EMAC Wrapper with LL FIFO 
  -- (v5_emac_v1_5_locallink.v)
  ------------------------------------------------------------------------
  v5_emac_ll : v5_emac_v1_5_locallink
  port map (
    -- EMAC0 Clocking
    -- 125MHz clock output from transceiver
      CLK125_OUT                => user_clk_out,
    -- 125MHz clock input from BUFG
      CLK125                    => user_clk_eth,
    -- Tri-speed clock output from EMAC0
      CLIENT_CLK_OUT_0          => client_clk_0_o,
    -- EMAC0 Tri-speed clock input from BUFG
      CLIENT_CLK_0              => client_clk_0,
    -- Local link Receiver Interface - EMAC0
      RX_LL_CLOCK_0             => user_clk_eth,
      RX_LL_RESET_0             => ll_reset_0_i,
      RX_LL_DATA_0              => rx_ll_data_0_i,
      RX_LL_SOF_N_0             => rx_ll_sof_n_0_i,
      RX_LL_EOF_N_0             => rx_ll_eof_n_0_i,
      RX_LL_SRC_RDY_N_0         => rx_ll_src_rdy_n_0_i,
      RX_LL_DST_RDY_N_0         => rx_ll_dst_rdy_n_0_i,
      RX_LL_FIFO_STATUS_0       => rx_ll_fifo_status_0_i,

    -- Unused Receiver signals - EMAC0
      EMAC0CLIENTRXDVLD         => open,
      EMAC0CLIENTRXFRAMEDROP    => open,
      EMAC0CLIENTRXSTATS        => open,
      EMAC0CLIENTRXSTATSVLD     => open,
      EMAC0CLIENTRXSTATSBYTEVLD => open,

    -- Local link Transmitter Interface - EMAC0
      TX_LL_CLOCK_0             => user_clk_eth,
      TX_LL_RESET_0             => ll_reset_0_i,
      TX_LL_DATA_0              => tx_ll_data_0_i,
      TX_LL_SOF_N_0             => tx_ll_sof_n_0_i,
      TX_LL_EOF_N_0             => tx_ll_eof_n_0_i,
      TX_LL_SRC_RDY_N_0         => tx_ll_src_rdy_n_0_i,
      TX_LL_DST_RDY_N_0         => tx_ll_dst_rdy_n_0_i,

    -- Unused Transmitter signals - EMAC0
      CLIENTEMAC0TXIFGDELAY     => "00000000",
      EMAC0CLIENTTXSTATS        => open,
      EMAC0CLIENTTXSTATSVLD     => open,
      EMAC0CLIENTTXSTATSBYTEVLD => open,

    -- MAC Control Interface - EMAC0
      CLIENTEMAC0PAUSEREQ       => '0',
      CLIENTEMAC0PAUSEVAL       => "0000000000000000",

    --EMAC-MGT link status
      EMAC0CLIENTSYNCACQSTATUS  => EMAC_READY,
    -- EMAC0 Interrupt
      EMAC0ANINTERRUPT          => open,

 
    -- Clock Signals - EMAC0
    -- SGMII Interface - EMAC0
      TXP_0                     => TXP_OUT(1),
      TXN_0                     => TXN_OUT(1),
      RXP_0                     => RXP_IN(1),
      RXN_0                     => RXN_IN(1),
      PHYAD_0                   => "00010",
      RESETDONE_0               => resetdone_0_i,

    -- unused transceiver
      TXN_1_UNUSED              => open,
      TXP_1_UNUSED              => open,
      RXN_1_UNUSED              => '1',
      RXP_1_UNUSED              => '0',

    -- SGMII RocketIO Reference Clock buffer inputs 
      CLK_DS                    => ref_clk,

    -- Asynchronous Reset
      RESET                     => rst_gtp
  );

  -- Create synchronous reset in the transmitter clock domain.
  gen_ll_reset_emac0 : process (user_clk_eth, rst_gtp)
  begin
    if rst_gtp = '1' then
      ll_pre_reset_0_i <= (others => '1');
      ll_reset_0_i     <= '1';
    elsif user_clk_eth'event and user_clk_eth = '1' then
      if resetdone_0_i = '1' then
        ll_pre_reset_0_i(0)          <= '0';
        ll_pre_reset_0_i(5 downto 1) <= ll_pre_reset_0_i(4 downto 0);
        ll_reset_0_i                 <= ll_pre_reset_0_i(5);
      end if;
    end if;
  end process gen_ll_reset_emac0;

  ----------------------------------------------------
  -- FIFO1 Instantiation and connections
  ----------------------------------------------------
  -- EMAC TX (8 bits) <- FIFO1 <- Aurora RX (16 bits)

  fifo1_i : fifo_32b_to_16b
    port map (
      din            => fifo1_din,
      rd_clk         => user_clk_eth,
      rd_en          => fifo1_rd_en,
      rst            => rst_fifos,
      wr_clk         => user_clk_aur,
      wr_en          => fifo1_wr_en,
      almost_full    => fifo1_almost_full,
      dout           => fifo1_dout,
      empty          => open,
      full           => open,
      valid          => fifo1_valid);

  -- Connections between EMAC TX and FIFO1
  tx_ll_data_0_i <= fifo1_dout(7 downto 0);
  tx_ll_sof_n_0_i <= not fifo1_dout(8);
  tx_ll_eof_n_0_i <= not fifo1_dout(9);
  tx_ll_src_rdy_n_0_i <= (not fifo1_valid) or fifo1_dout(10);
  fifo1_rd_en <= not tx_ll_dst_rdy_n_0_i;

  -- Connections between FIFO1 and Aurora
  fifo1_din(23 downto 16) <= rx_d_i(0 to 7);
  fifo1_din(7 downto 0) <= rx_d_i(8 to 15);
  fifo1_din(24) <= not rx_sof_n_i;
  fifo1_din(25) <= (not rx_eof_n_i) and (not rx_rem_i);
  fifo1_din(9) <= (not rx_eof_n_i) and rx_rem_i;
  fifo1_din(10) <= (not rx_eof_n_i) and (not rx_rem_i);
  fifo1_wr_en <= not rx_src_rdy_n_i;

  ----------------------------------------------------
  -- FIFO2 Instantiation and connections
  ----------------------------------------------------
  -- EMAC RX (8 bits) -> FIFO2 -> Aurora TX (16 bits)

  fifo2_i : fifo_16b_to_32b
    port map (
      din            => fifo2_din,
      rd_clk         => user_clk_aur,
      rd_en          => fifo2_rd_en,
      rst            => rst_fifos,
      wr_clk         => user_clk_eth,
      wr_en          => fifo2_wr_en,
      almost_full    => fifo2_almost_full,
      dout           => fifo2_dout,
      empty          => open,
      full           => fifo2_full,
      valid          => fifo2_valid);
	
  -- Connections between FIFO2 and EMAC RX
  fifo2_din(7 downto 0) <= rx_ll_data_0_i;
  fifo2_din(8) <= (not rx_ll_sof_n_0_i) and (not insert_blank);
  fifo2_din(9) <= (not rx_ll_eof_n_0_i) and (not insert_blank);
  fifo2_wr_en <= (not rx_ll_src_rdy_n_0_i) or insert_blank;
  rx_ll_dst_rdy_n_0_i <= fifo2_almost_full;
	
  -- Connections between Aurora TX and FIFO2
  tx_d_i(0 to 7) <= fifo2_dout(23 downto 16);
  tx_d_i(8 to 15) <= fifo2_dout(7 downto 0);
  tx_sof_n_i <= not fifo2_dout(24);
  tx_eof_n_i <= not (fifo2_dout(9) or fifo2_dout(25));
  tx_rem_i <= fifo2_dout(9);
  tx_src_rdy_n_i <= not fifo2_valid;
  fifo2_rd_en <= not tx_dst_rdy_n_i;

  -- Logic to generate "odd_bytes" signal that is asserted for
  -- every ODD byte of an Ethernet frame written into FIFO2.
  process (user_clk_eth, rst_fifos)
  begin
    if rst_fifos = '1' then
      odd_bytes <= '1';
    elsif user_clk_eth'event and user_clk_eth = '1' then
      if rx_ll_src_rdy_n_0_i = '0' and fifo2_almost_full = '0' then
        odd_bytes <= (not odd_bytes) or (not rx_ll_eof_n_0_i);
      end if;
    end if;
  end process;

  -- Logic to generate "insert_blank" signal to write an extra byte
  -- into FIFO2 when the frame contained an ODD number of bytes.
  process (user_clk_eth, rst_fifos)
  begin
    if rst_fifos = '1' then
      insert_blank <= '0';
    elsif user_clk_eth'event and user_clk_eth = '1' then
      insert_blank <= odd_bytes and (not rx_ll_eof_n_0_i) and (not rx_ll_src_rdy_n_0_i) and (not fifo2_almost_full);
    end if;
  end process;

  ------------------------------------------
  -- Example code to read/write user logic slave model s/w accessible registers
  -- 
  -- Note:
  -- The example code presented here is to show you one way of reading/writing
  -- software accessible registers implemented in the user logic slave model.
  -- Each bit of the Bus2IP_WrCE/Bus2IP_RdCE signals is configured to correspond
  -- to one software accessible register by the top level template. For example,
  -- if you have four 32 bit software accessible registers in the user logic,
  -- you are basically operating on the following memory mapped registers:
  -- 
  --    Bus2IP_WrCE/Bus2IP_RdCE   Memory Mapped Register
  --                     "1000"   C_BASEADDR + 0x0
  --                     "0100"   C_BASEADDR + 0x4
  --                     "0010"   C_BASEADDR + 0x8
  --                     "0001"   C_BASEADDR + 0xC
  -- 
  ------------------------------------------
  slv_reg_write_sel <= Bus2IP_WrCE(0 to 0);
  slv_reg_read_sel  <= Bus2IP_RdCE(0 to 0);
  slv_write_ack     <= Bus2IP_WrCE(0);
  slv_read_ack      <= Bus2IP_RdCE(0);

  -- implement slave model software accessible register(s)
  SLAVE_REG_WRITE_PROC : process( Bus2IP_Clk ) is
  begin

    if Bus2IP_Clk'event and Bus2IP_Clk = '1' then
      if Bus2IP_Reset = '1' then
        slv_reg0 <= (others => '0');
      else
        case slv_reg_write_sel is
          when "1" =>
            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
              if ( Bus2IP_BE(byte_index) = '1' ) then
                slv_reg0(byte_index*8 to byte_index*8+7) <= Bus2IP_Data(byte_index*8 to byte_index*8+7);
              end if;
            end loop;
          when others => null;
        end case;
      end if;
    end if;

  end process SLAVE_REG_WRITE_PROC;

  -- implement slave model software accessible register(s) read mux
  SLAVE_REG_READ_PROC : process( slv_reg_read_sel, slv_reg0 ) is
  begin

    case slv_reg_read_sel is
      when "1" => slv_ip2bus_data <= slv_reg0;
      when others => slv_ip2bus_data <= (others => '0');
    end case;

  end process SLAVE_REG_READ_PROC;

  ------------------------------------------
  -- Example code to drive IP to Bus signals
  ------------------------------------------
  IP2Bus_Data  <= slv_ip2bus_data when slv_read_ack = '1' else
                  (others => '0');

  IP2Bus_WrAck <= slv_write_ack;
  IP2Bus_RdAck <= slv_read_ack;
  IP2Bus_Error <= '0';

end IMP;
