-- plbv46_config_bus.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library plbv46_slave_single_v1_01_a;
use plbv46_slave_single_v1_01_a.plbv46_slave_single;

library proc_common_v3_00_a;
use proc_common_v3_00_a.async_fifo_fg;
use proc_common_v3_00_a.ipif_pkg.all;

entity plbv46_if is
generic (
	IP_ID                          : std_logic_vector(15 downto 0);
	IP_VERSION                     : std_logic_vector(15 downto 0);
	USE_FIFO_BRAM                  : integer              := 1; -- 1 = BRAM, 0 = Dist Memory
	C_BASEADDR                     : std_logic_vector     := X"FFFFFFFF";
	C_HIGHADDR                     : std_logic_vector     := X"00000000";
	C_SPLB_AWIDTH                  : integer              := 32;
	C_SPLB_DWIDTH                  : integer              := 128;
	C_SPLB_NUM_MASTERS             : integer              := 8;
	C_SPLB_MID_WIDTH               : integer              := 3;
	C_SPLB_P2P                     : integer              := 0;
	C_INCLUDE_DPHASE_TIMER         : integer              := 0;
	C_FAMILY                       : string               := "virtex5"
);
port (
	CFG_CLK           : in  std_logic;
	CFG_RST           : in  std_logic;
	CFG_WE            : out std_logic;
	CFG_RE            : out std_logic;
	CFG_ACK           : in  std_logic;
	CFG_DIN           : out std_logic_vector(31 downto 0);
	CFG_BE            : out std_logic_vector(3 downto 0);
	CFG_DOUT          : in  std_logic_vector(31 downto 0);
	CFG_ADDR          : out std_logic_vector(7 downto 0);

	SPLB_Clk          : in  std_logic;
	SPLB_Rst          : in  std_logic;
	PLB_ABus          : in  std_logic_vector(0 to 31);
	PLB_UABus         : in  std_logic_vector(0 to 31);
	PLB_PAValid       : in  std_logic;
	PLB_SAValid       : in  std_logic;
	PLB_rdPrim        : in  std_logic;
	PLB_wrPrim        : in  std_logic;
	PLB_masterID      : in  std_logic_vector(0 to C_SPLB_MID_WIDTH-1);
	PLB_abort         : in  std_logic;
	PLB_busLock       : in  std_logic;
	PLB_RNW           : in  std_logic;
	PLB_BE            : in  std_logic_vector(0 to C_SPLB_DWIDTH/8-1);
	PLB_MSize         : in  std_logic_vector(0 to 1);
	PLB_size          : in  std_logic_vector(0 to 3);
	PLB_type          : in  std_logic_vector(0 to 2);
	PLB_lockErr       : in  std_logic;
	PLB_wrDBus        : in  std_logic_vector(0 to C_SPLB_DWIDTH-1);
	PLB_wrBurst       : in  std_logic;
	PLB_rdBurst       : in  std_logic;
	PLB_wrPendReq     : in  std_logic;
	PLB_rdPendReq     : in  std_logic;
	PLB_wrPendPri     : in  std_logic_vector(0 to 1);
	PLB_rdPendPri     : in  std_logic_vector(0 to 1);
	PLB_reqPri        : in  std_logic_vector(0 to 1);
	PLB_TAttribute    : in  std_logic_vector(0 to 15);
	Sl_addrAck        : out std_logic;
	Sl_SSize          : out std_logic_vector(0 to 1);
	Sl_wait           : out std_logic;
	Sl_rearbitrate    : out std_logic;
	Sl_wrDAck         : out std_logic;
	Sl_wrComp         : out std_logic;
	Sl_wrBTerm        : out std_logic;
	Sl_rdDBus         : out std_logic_vector(0 to C_SPLB_DWIDTH-1);
	Sl_rdWdAddr       : out std_logic_vector(0 to 3);
	Sl_rdDAck         : out std_logic;
	Sl_rdComp         : out std_logic;
	Sl_rdBTerm        : out std_logic;
	Sl_MBusy          : out std_logic_vector(0 to C_SPLB_NUM_MASTERS-1);
	Sl_MWrErr         : out std_logic_vector(0 to C_SPLB_NUM_MASTERS-1);
	Sl_MRdErr         : out std_logic_vector(0 to C_SPLB_NUM_MASTERS-1);
	Sl_MIRQ           : out std_logic_vector(0 to C_SPLB_NUM_MASTERS-1)
);
end entity;

architecture with_plb_slave of plbv46_if is

	---
	-- PLBv46 Slave address space configuration
	---
	constant BASEADDR       : std_logic_vector := X"0000_0000" & C_BASEADDR;
	-- supported only 0x100 address space (address is 8-bit)
	constant RVER_BASEADDR  : std_logic_vector := X"0000_0000_0000_0000";
	constant RVER_HIGHADDR  : std_logic_vector := X"0000_0000_0000_0003";
	constant RNEG_BASEADDR  : std_logic_vector := X"0000_0000_0000_0004";
	constant RNEG_HIGHADDR  : std_logic_vector := X"0000_0000_0000_0007";
	constant USER_BASEADDR  : std_logic_vector := X"0000_0000_0000_0008";
	constant USER_HIGHADDR  : std_logic_vector := X"0000_0000_0000_00FF";

	constant RVER_CS_IDX    : integer := 0;
	constant RNEG_CS_IDX    : integer := 1;
	constant USER_CS_IDX    : integer := 2;

	constant ARD_ADDR_RANGE : SLV64_ARRAY_TYPE := (
		-- version address space
		BASEADDR or RVER_BASEADDR,
		BASEADDR or RVER_HIGHADDR,
		-- negation address space
		BASEADDR or RNEG_BASEADDR,
		BASEADDR or RNEG_HIGHADDR,
		-- CFG address space
		BASEADDR or USER_BASEADDR,
		BASEADDR or USER_BASEADDR
	);

	---
	-- Bus2IP/IP2Bus signals
	---
	signal plb_internal_clk   : std_logic;
	signal plb_internal_rst   : std_logic;
	signal plb_internal_addr  : std_logic_vector(0 to 31);
	signal plb_internal_din   : std_logic_vector(0 to 31);
	signal plb_internal_be    : std_logic_vector(0 to 3);
	signal plb_internal_dout  : std_logic_vector(0 to 31);
	signal plb_internal_rnw   : std_logic;
	signal plb_internal_error : std_logic;
	signal plb_internal_wrack : std_logic;
	signal plb_internal_rdack : std_logic;
	signal plb_internal_cs    : std_logic_vector(2 downto 0);

	---
	-- Crossing CLK domain FIFO for requests
	---
	signal fifo_in_we     : std_logic;
	signal fifo_in_full   : std_logic;
	signal fifo_in_re     : std_logic;
	signal fifo_in_empty  : std_logic;
	signal fifo_in_din    : std_logic_vector(68 downto 0);
	signal fifo_in_dout   : std_logic_vector(68 downto 0);

	---
	-- Request was written to in FIFO
	---
	signal reg_fifo_written     : std_logic;
	signal reg_fifo_written_set : std_logic;
	signal reg_fifo_written_clr : std_logic;

	---
	-- Crossing CLK domain FIFO for responses
	---
	signal fifo_out_we    : std_logic;
	signal fifo_out_full  : std_logic;
	signal fifo_out_re    : std_logic;
	signal fifo_out_empty : std_logic;
	signal fifo_out_din   : std_logic_vector(33 downto 0);
	signal fifo_out_dout  : std_logic_vector(33 downto 0);
	
	---
	-- Semantic for FIFO data signals in SPLB CLK domain
	---
	signal fifo_cfg_dout  : std_logic_vector(31 downto  0);
	signal fifo_cfg_ack   : std_logic;
	signal fifo_cfg_error : std_logic;

	---
	-- Testing registers
	---
	signal reg_negate     : std_logic_vector(31 downto 0);
	signal reg_negate_in  : std_logic_vector(31 downto 0);
	signal reg_negate_ce  : std_logic;
	signal reg_version    : std_logic_vector(31 downto 0);

begin

	---
	-- IP Version pseudo register
	---
	reg_version <= IP_ID & IP_VERSION;


	---
	-- Negating register address space, SPLB_Clk domain
	---
	reg_negatep : process(SPLB_Clk, SPLB_Rst, reg_negate_ce, reg_negate_in)
	begin
		if rising_edge(SPLB_Clk) then
			if SPLB_Rst = '1' then
				reg_negate <= (others => '1');
			elsif reg_negate_ce = '1' then
				reg_negate <= not reg_negate_in;
			end if;
		end if;
	end process;

	reg_negate_ce <= plb_internal_we when plb_cs(RNEG_CS_IDX) = '1' else '0';
	reg_negate_in <= plb_internal_din;


	-----------------------------------------------------------
	---
	-- Output address decoding
	---

	plb_internal_dout <= reg_negate  when plb_cs(RNEG_CS_IDX) = '1' else
	                     reg_version when plb_internal_cs(RVER_CS_IDX) = '1' else
		             fifo_cfg_dout;

	plb_internal_wrack <= not plb_rnw when plb_cs(RNEG_CS_IDX) = '1' else
	                      not plb_internal_rnw when plb_cs(RVER_CS_IDX) = '1' else
		              fifo_cfg_ack and not plb_internal_rnw;

	plb_internal_rdack <= plb_rnw when plb_cs(RNEG_CS_IDX) = '1' else
	                      plb_internal_rnw when plb_cs(RVER_CS_IDX) = '1' else
		              fifo_cfg_ack and plb_internal_rnw;

	plb_internal_error <= fifo_cfg_error when plb_cs(USER_CS_IDX) = '1' else
	                      '0';

	
	-----------------------------------------------------------
	---
	-- SPLB CLK domain
	---

	-- FIFO request
	fifo_in_din(31 downto  0) <= plb_internal_addr;
	fifo_in_din(63 downto 32) <= plb_internal_din;
	fifo_in_din(67 downto 64) <= plb_internal_be;
	fifo_in_din(68)           <= plb_internal_rnw;

	fifo_in_we <= plb_internal_cs(USER_CS_IDX) and not reg_fifo_written;
	-- TODO: handle fifo_in_full, but should never happen
	--       no more then 1 transaction over PLB would be
	--       possible, fifo can hold more then 1 transaction


	-- FIFO written register
	reg_fifo_writtenp : process(SPLB_Clk, SPLB_Rst, reg_fifo_written_set,
			            reg_fifo_written_clr)
	begin
		if rising_edge(SPLB_Clk) then
			if SPLB_Rst = '1' or reg_fifo_written_clr = '1' then
				reg_fifo_written <= '0';
			else reg_fifo_written_set = '1' then
				reg_fifo_written <= '1';
			end if;
		end if;
	end process;

	reg_fifo_written_set <= fifo_in_we;
	reg_fifo_written_clr <= fifo_cfg_ack;


	-- FIFO response
	fifo_cfg_dout  <= fifo_out_dout(31 downto 0);
	fifo_cfg_ack   <= fifo_out_dout(32);
	fifo_cfg_error <= fifo_out_dout(33);

	fifo_out_re <= not fifo_out_empty;


	-----------------------------------------------------------

	---
	-- CFG_CLK domain
	---

	-- FIFO request
	CFG_ADDR <= fifo_in_dout(31 downto  0);
	CFG_DIN  <= fifo_in_dout(63 downto 32);
	CFG_BE   <= fifo_in_dout(67 downto 64);
	CFG_WE   <= not fifo_in_dout(68);
	CFG_RE   <= fifo_in_dout(68);

	fifo_in_re <= not fifo_in_empty;

	
	-- FIFO response
	fifo_out_din(31 downto 0) <= CFG_DOUT;
	fifo_out_din(32) <= CFG_ACK;
	fifo_out_din(33) <= '0'; -- no error

	fifo_out_we <= CFG_ACK;
	-- TODO: handle fifo_out_full, read above same problem
	--       with fifo_in_full


	-----------------------------------------------------------

	---
	-- Async FIFOs (crossing clk domains)
	---

	-- CFG requests
	in_afifo_i : entity proc_common_v3_00_a.async_fifo_fg
	generic map (
		C_FAMILY           => "virtex5",
		C_DATA_WIDTH       => fifo_in_din'length,
		C_FIFO_DEPTH       => 8
		C_HAS_ALMOST_EMPTY => 0,
		C_HAS_ALMOST_FULL  => 0,
		C_HAS_RD_ACK       => 0,
		C_HAS_RD_COUNT     => 0,
		C_HAS_ERR          => 0,
		C_HAS_WR_ACK       => 0,
		C_HAS_WE_COUNT     => 0,
		C_HAS_WE_ERR       => 0,
		C_USE_BLOCKMEM     => USE_FIFO_BRAM
	)
	port map (
		Wr_clk  => plb_internal_clk,
		Wr_en   => fifo_in_we,
		Din     => fifo_in_din,
		Full    => fifo_in_full,

		Rd_clk  => CFG_CLK,
		Rd_en   => fifo_in_re,
		Dout    => fifo_in_dout,
		Empty   => fifo_in_empty
	);

	-- CFG responses
	out_afifo_i : entity proc_common_v3_00_a.async_fifo_fg
	generic map (
		C_FAMILY           => "virtex5",
		C_DATA_WIDTH       => fifo_out_din'length,
		C_FIFO_DEPTH       => 8
		C_HAS_ALMOST_EMPTY => 0,
		C_HAS_ALMOST_FULL  => 0,
		C_HAS_RD_ACK       => 0,
		C_HAS_RD_COUNT     => 0,
		C_HAS_ERR          => 0,
		C_HAS_WR_ACK       => 0,
		C_HAS_WE_COUNT     => 0,
		C_HAS_WE_ERR       => 0,
		C_USE_BLOCKMEM     => USE_FIFO_BRAM
	)
	port map (
		Wr_clk  => CFG_CLK,
		Wr_en   => fifo_out_we,
		Din     => fifo_out_din,
		Full    => fifo_out_full,

		Rd_clk  => plb_internal_clk,
		Rd_en   => fifo_out_re,
		Dout    => fifo_out_dout,
		Empty   => fifo_out_empty
	);


	-----------------------------------------------------------

	---
	-- PLBv46 Slave
	---
	plbv46_slave_i : entity plbv46_slave_single_v1_01_a.plbv46_slave_single
	generic map (
		C_FAMILY               => C_FAMILY,
		C_SPLB_AWIDTH          => C_SPLB_AWIDTH,
		C_SPLB_DWIDTH          => C_SPLB_DWIDTH,
		C_SPLB_NUM_MASTERS     => C_SPLB_NUM_MASTERS,
		C_SPLB_MID_WIDTH       => C_SPLB_MID_WIDTH,
		C_SPLB_P2P             => C_SPLB_P2P,
		C_INCLUDE_DPHASE_TIMER => C_INCLUDE_DPHASE_TIMER,
		C_SIPIF_DWIDTH         => 32,
		C_BUS2CORE_CLK_RATIO   => 1,
		C_ARD_ADDR_RANGE_ARRAY => ARD_ADDR_RANGE,
		C_ARD_NUM_CE_ARRAY     => 0 -- do not need this
	)
	port map (
		SPLB_Clk       => SPLB_Clk,
		SPLB_Rst       => SPLB_Rst,
		
		PLB_ABus       => PLB_ABus,
		PLB_UABus      => PLB_UABus,
		PLB_PAValid    => PLB_PAValid,
		PLB_SAValid    => PLB_SAValid,
		PLB_rdPrim     => PLB_rdPrim,
		PLB_wrPrim     => PLB_wrPrim,
		PLB_masterID   => PLB_masterID,
		PLB_abort      => PLB_abort,
		PLB_busLock    => PLB_busLock,
		PLB_RNW        => PLB_RNW,
		PLB_BE         => PLB_BE,
		PLB_MSize      => PLB_MSize,
		PLB_size       => PLB_size,
		PLB_type       => PLB_type,
		PLB_lockErr    => PLB_lockErr,
		PLB_wrDBus     => PLB_wrDBus,
		PLB_wrBurst    => PLB_wrBurst,
		PLB_rdBurst    => PLB_rdBurst,
		PLB_wrPendReq  => PLB_wrPendReq,
		PLB_rdPendReq  => PLB_rdPendReq,
		PLB_wrPendPri  => PLB_wrPendPri,
		PLB_rdPendPri  => PLB_rdPendPri,
		PLB_reqPri     => PLB_reqPri,
		PLB_TAttribute => PLB_TAttribute,

		Sl_addrAck     => Sl_addrAck,
		Sl_SSize       => Sl_SSize,
		Sl_wait        => Sl_wait,
		Sl_rearbitrate => Sl_rearbitrate,
		Sl_wrDAck      => Sl_wrDAck,
		Sl_wrComp      => Sl_wrComp,
		Sl_wrBTerm     => Sl_wrBTerm,
		Sl_rdDBus      => Sl_rdDBus,
		Sl_rdWdAddr    => Sl_rdWdAddr,
		Sl_rdDAck      => Sl_rdDAck,
		Sl_rdComp      => Sl_rdComp,
		Sl_rdBTerm     => Sl_rdBTerm,
		Sl_MBusy       => Sl_MBusy,
		Sl_MWrErr      => Sl_MWrErr,
		Sl_MRdErr      => Sl_MRdErr,
		Sl_MIRQ        => Sl_MIRQ,
		
		Bus2IP_Clk     => plb_internal_clk,
		Bus2IP_Reset   => plb_internal_rst,
		Bus2IP_Addr    => plb_internal_addr,
		Bus2IP_Data    => plb_internal_din,
		Bus2IP_RNW     => plb_internal_rnw,
		Bus2IP_BE      => plb_internal_be,
		Bus2IP_CS      => plb_internal_cs,
		Bus2IP_RdCE    => open,
		Bus2IP_WrCE    => open

		IP2Bus_Data    => plb_internal_dout,
		IP2Bus_WrAck   => plb_internal_wrack,
		IP2Bus_RdAck   => plb_internal_rdack,
		IP2Bus_Error   => plb_internal_error
	);


end architecture;

