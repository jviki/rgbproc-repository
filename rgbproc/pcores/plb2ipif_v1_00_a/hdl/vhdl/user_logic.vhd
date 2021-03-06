------------------------------------------------------------------------------
-- user_logic.vhd - entity/architecture pair
------------------------------------------------------------------------------
--
-- ***************************************************************************
-- ** Copyright (c) 1995-2011 Xilinx, Inc.  All rights reserved.            **
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
-- Date:              Thu Jan  5 11:21:12 2012 (by Create and Import Peripheral Wizard)
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

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;

-- DO NOT EDIT ABOVE THIS LINE --------------------

--USER libraries added here
library utils_v1_00_a;
use utils_v1_00_a.async_ipif;

------------------------------------------------------------------------------
-- Entity section
------------------------------------------------------------------------------
-- Definition of Generics:
--   C_SLV_AWIDTH                 -- Slave interface address bus width
--   C_SLV_DWIDTH                 -- Slave interface data bus width
--   C_NUM_MEM                    -- Number of memory spaces
--
-- Definition of Ports:
--   Bus2IP_Clk                   -- Bus to IP clock
--   Bus2IP_Reset                 -- Bus to IP reset
--   Bus2IP_Addr                  -- Bus to IP address bus
--   Bus2IP_CS                    -- Bus to IP chip select for user logic memory selection
--   Bus2IP_RNW                   -- Bus to IP read/not write
--   Bus2IP_Data                  -- Bus to IP data bus
--   Bus2IP_BE                    -- Bus to IP byte enables
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
    DUAL_CLOCK                     : integer              := 1;
    CS_ENABLE                      : integer              := 0;
    BASEADDR                       : std_logic_vector     := X"00000000";
    -- ADD USER GENERICS ABOVE THIS LINE ---------------

    -- DO NOT EDIT BELOW THIS LINE ---------------------
    -- Bus protocol parameters, do not add to or delete
    C_SLV_AWIDTH                   : integer              := 32;
    C_SLV_DWIDTH                   : integer              := 32;
    C_NUM_MEM                      : integer              := 1
    -- DO NOT EDIT ABOVE THIS LINE ---------------------
  );
  port
  (
    -- ADD USER PORTS BELOW THIS LINE ------------------
    --USER ports added here
	S_Bus2IP_Clk                     : in  std_logic;
	S_Bus2IP_Reset                   : in  std_logic;
	S_Bus2IP_Addr                    : out std_logic_vector(0 to C_SLV_AWIDTH-1);
	S_Bus2IP_CS                      : out std_logic_vector(0 to C_NUM_MEM-1);
	S_Bus2IP_RNW                     : out std_logic;
	S_Bus2IP_Data                    : out std_logic_vector(0 to C_SLV_DWIDTH-1);
	S_Bus2IP_BE                      : out std_logic_vector(0 to C_SLV_DWIDTH/8-1);
	S_IP2Bus_Data                    : in  std_logic_vector(0 to C_SLV_DWIDTH-1);
	S_IP2Bus_RdAck                   : in  std_logic;
	S_IP2Bus_WrAck                   : in  std_logic;
	S_IP2Bus_Error                   : in  std_logic;

	CS_M_CLK                         : out std_logic;
	CS_M_VEC                         : out std_logic_vector(105 downto 0);
	CS_S_CLK                         : out std_logic;
	CS_S_VEC                         : out std_logic_vector(105 downto 0);
    -- ADD USER PORTS ABOVE THIS LINE ------------------

    -- DO NOT EDIT BELOW THIS LINE ---------------------
    -- Bus protocol ports, do not add to or delete
    Bus2IP_Clk                     : in  std_logic;
    Bus2IP_Reset                   : in  std_logic;
    Bus2IP_Addr                    : in  std_logic_vector(0 to C_SLV_AWIDTH-1);
    Bus2IP_CS                      : in  std_logic_vector(0 to C_NUM_MEM-1);
    Bus2IP_RNW                     : in  std_logic;
    Bus2IP_Data                    : in  std_logic_vector(0 to C_SLV_DWIDTH-1);
    Bus2IP_BE                      : in  std_logic_vector(0 to C_SLV_DWIDTH/8-1);
    IP2Bus_Data                    : out std_logic_vector(0 to C_SLV_DWIDTH-1);
    IP2Bus_RdAck                   : out std_logic;
    IP2Bus_WrAck                   : out std_logic;
    IP2Bus_Error                   : out std_logic
    -- DO NOT EDIT ABOVE THIS LINE ---------------------
  );

  attribute MAX_FANOUT : string;
  attribute SIGIS : string;

  attribute SIGIS of Bus2IP_Clk    : signal is "CLK";
  attribute SIGIS of Bus2IP_Reset  : signal is "RST";

end entity user_logic;

------------------------------------------------------------------------------
-- Architecture section
------------------------------------------------------------------------------

architecture IMP of user_logic is

	signal plb_Bus2IP_Clk   : std_logic;
	signal plb_Bus2IP_Reset : std_logic;
	signal plb_Bus2IP_Addr  : std_logic_vector(C_SLV_AWIDTH - 1 downto 0);
	signal plb_Bus2IP_Data  : std_logic_vector(C_SLV_DWIDTH - 1 downto 0);
	signal plb_Bus2IP_RNW   : std_logic;
	signal plb_Bus2IP_BE    : std_logic_vector(C_SLV_DWIDTH / 8 - 1 downto 0);
	signal plb_Bus2IP_CS    : std_logic_vector(C_NUM_MEM - 1 downto 0);
	signal plb_IP2Bus_Data  : std_logic_vector(C_SLV_DWIDTH - 1 downto 0);
	signal plb_IP2Bus_WrAck : std_logic;
	signal plb_IP2Bus_RdAck : std_logic;
	signal plb_IP2Bus_Error : std_logic;

	signal cfg_Bus2IP_Clk   : std_logic;
	signal cfg_Bus2IP_Reset : std_logic;
	signal cfg_Bus2IP_Addr  : std_logic_vector(C_SLV_AWIDTH - 1 downto 0);
	signal cfg_Bus2IP_Data  : std_logic_vector(C_SLV_DWIDTH - 1 downto 0);
	signal cfg_Bus2IP_RNW   : std_logic;
	signal cfg_Bus2IP_BE    : std_logic_vector(C_SLV_DWIDTH / 8 - 1 downto 0);
	signal cfg_Bus2IP_CS    : std_logic_vector(C_NUM_MEM - 1 downto 0);
	signal cfg_IP2Bus_Data  : std_logic_vector(C_SLV_DWIDTH - 1 downto 0);
	signal cfg_IP2Bus_WrAck : std_logic;
	signal cfg_IP2Bus_RdAck : std_logic;
	signal cfg_IP2Bus_Error : std_logic;

begin

	plb_Bus2IP_Clk   <= Bus2IP_Clk;
	plb_Bus2IP_Reset <= Bus2IP_Reset;
	plb_Bus2IP_Addr  <= Bus2IP_Addr - BASEADDR;
	plb_Bus2IP_Data  <= Bus2IP_Data;
	plb_Bus2IP_RNW   <= Bus2IP_RNW;
	plb_Bus2IP_BE    <= Bus2IP_BE;
	plb_Bus2IP_CS    <= Bus2IP_CS;
	IP2Bus_Data      <= plb_IP2Bus_Data;
	IP2Bus_WrAck     <= plb_IP2Bus_WrAck;
	IP2Bus_RdAck     <= plb_IP2Bus_RdAck;
	IP2Bus_Error     <= plb_IP2Bus_Error;

	cfg_Bus2IP_Clk   <= S_Bus2IP_Clk;
	cfg_Bus2IP_Reset <= S_Bus2IP_Reset;
	S_Bus2IP_Addr    <= cfg_Bus2IP_Addr;
	S_Bus2IP_Data    <= cfg_Bus2IP_Data;
	S_Bus2IP_RNW     <= cfg_Bus2IP_RNW;
	S_Bus2IP_BE      <= cfg_Bus2IP_BE;
	S_Bus2IP_CS      <= cfg_Bus2IP_CS;
	cfg_IP2Bus_Data  <= S_IP2Bus_Data;
	cfg_IP2Bus_WrAck <= S_IP2Bus_WrAck;
	cfg_IP2Bus_RdAck <= S_IP2Bus_RdAck;
	cfg_IP2Bus_Error <= S_IP2Bus_Error;

	-------------------------------------

gen_dual_clock: if DUAL_CLOCK /= 0
generate

	ipif_i : entity utils_v1_00_a.async_ipif
	generic map (
		AWIDTH => C_SLV_AWIDTH,
		DWIDTH => C_SLV_DWIDTH,
		NADDR  => C_NUM_MEM
	)
	port map (
		M_CLK          => plb_Bus2IP_Clk,
		M_RST          => plb_Bus2IP_Reset,
		M_IP2Bus_Data  => plb_IP2Bus_Data,
		M_IP2Bus_WrAck => plb_IP2Bus_WrAck,
		M_IP2Bus_RdAck => plb_IP2Bus_RdAck,
		M_IP2Bus_Error => plb_IP2Bus_Error,
		M_Bus2IP_Addr  => plb_Bus2IP_Addr,
		M_Bus2IP_Data  => plb_Bus2IP_Data,
		M_Bus2IP_RNW   => plb_Bus2IP_RNW,
		M_Bus2IP_BE    => plb_Bus2IP_BE,
		M_Bus2IP_CS    => plb_Bus2IP_CS,

		S_CLK          => cfg_Bus2IP_Clk,
		S_RST          => cfg_Bus2IP_Reset,
		S_IP2Bus_Data  => cfg_IP2Bus_Data,
		S_IP2Bus_WrAck => cfg_IP2Bus_WrAck,
		S_IP2Bus_RdAck => cfg_IP2Bus_RdAck,
		S_IP2Bus_Error => cfg_IP2Bus_Error,
		S_Bus2IP_Addr  => cfg_Bus2IP_Addr,
		S_Bus2IP_Data  => cfg_Bus2IP_Data,
		S_Bus2IP_RNW   => cfg_Bus2IP_RNW,
		S_Bus2IP_BE    => cfg_Bus2IP_BE,
		S_Bus2IP_CS    => cfg_Bus2IP_CS
	);

end generate;

gen_not_dual_clock: if DUAL_CLOCK = 0
generate

	plb_IP2Bus_Data  <= cfg_IP2Bus_Data;
	plb_IP2Bus_WrAck <= cfg_IP2Bus_WrAck;
	plb_IP2Bus_RdAck <= cfg_IP2Bus_RdAck;
	plb_IP2Bus_Error <= cfg_IP2Bus_Error;
	cfg_Bus2IP_Addr  <= plb_Bus2IP_Addr;
	cfg_Bus2IP_Data  <= plb_Bus2IP_Data;
	cfg_Bus2IP_RNW   <= plb_Bus2IP_RNW;
	cfg_Bus2IP_BE    <= plb_Bus2IP_BE;
	cfg_Bus2IP_CS    <= plb_Bus2IP_CS;

end generate;

gen_chipscope: if CS_ENABLE /= 0
generate

	CS_M_CLK      <= plb_Bus2IP_Clk;

	gen_slave_clock: if DUAL_CLOCK = 1
	generate
		CS_S_CLK      <= cfg_Bus2IP_Clk;
	end generate;
	gen_master_clock: if DUAL_CLOCK = 0
	generate
		CS_S_CLK      <= plb_Bus2IP_Clk;
	end generate;

	CS_M_VEC(31 downto  0) <= plb_Bus2IP_Addr;
	CS_M_VEC(63 downto 32) <= plb_IP2Bus_Data;
	CS_M_VEC(95 downto 64) <= plb_Bus2IP_Data;
	CS_M_VEC(99 downto 96) <= plb_Bus2IP_BE;
	CS_M_VEC(100) <= plb_Bus2IP_Reset;
	CS_M_VEC(101) <= plb_Bus2IP_CS(0);
	CS_M_VEC(102) <= plb_Bus2IP_RNW;
	CS_M_VEC(103) <= plb_IP2Bus_WrAck;
	CS_M_VEC(104) <= plb_IP2Bus_RdAck;
	CS_M_VEC(105) <= plb_IP2Bus_Error;

	CS_S_VEC(31 downto  0) <= cfg_Bus2IP_Addr;
	CS_S_VEC(63 downto 32) <= cfg_IP2Bus_Data;
	CS_S_VEC(95 downto 64) <= cfg_Bus2IP_Data;
	CS_S_VEC(99 downto 96) <= cfg_Bus2IP_BE;
	CS_S_VEC(100) <= cfg_Bus2IP_Reset;
	CS_S_VEC(101) <= cfg_Bus2IP_CS(0);
	CS_S_VEC(102) <= cfg_Bus2IP_RNW;
	CS_S_VEC(103) <= cfg_IP2Bus_WrAck;
	CS_S_VEC(104) <= cfg_IP2Bus_RdAck;
	CS_S_VEC(105) <= cfg_IP2Bus_Error;

end generate;

end IMP;
