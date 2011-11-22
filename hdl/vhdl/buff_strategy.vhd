-- buff_strategy.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.log2;

entity buff_strategy is
generic (
	BUFF_CAP  : integer := 640 * 480 -- pixels
);
port (
	---
	-- Global clock domain
	---
	CLK       : in  std_logic;
	RST       : in  std_logic;

	---
	-- Control
	---
	IN_DONE   : in  std_logic;
	IN_RDY    : out std_logic;
	
	OUT_DONE  : in  std_logic;
	OUT_RDY   : out std_logic;

	MEM_DONE  : in  std_logic;
	MEM_RDY   : out std_logic;

	---
	-- FIFO in
	---
	IN_R      : in  std_logic_vector(7 downto 0);
	IN_G      : in  std_logic_vector(7 downto 0);
	IN_B      : in  std_logic_vector(7 downto 0);

	IN_WE     : in  std_logic;
	IN_FULL   : out std_logic;

	---
	-- FIFO out
	---
	OUT_R     : out std_logic_vector(7 downto 0);
	OUT_G     : out std_logic_vector(7 downto 0);
	OUT_B     : out std_logic_vector(7 downto 0);

	OUT_RE    : in  std_logic;
	OUT_EMPTY : out std_logic;

	---
	-- Random Access port 0
	---
	M0_A      : in  std_logic_vector(log2(BUFF_CAP) - 1 downto 0);
	M0_RO     : out std_logic_vector(7 downto 0);
	M0_GO     : out std_logic_vector(7 downto 0);
	M0_BO     : out std_logic_vector(7 downto 0);
	M0_WE     : in  std_logic;

	M0_RI     : in  std_logic_vector(7 downto 0);
	M0_GI     : in  std_logic_vector(7 downto 0);
	M0_BI     : in  std_logic_vector(7 downto 0);
	M0_RE     : in  std_logic;

	M0_DRDY   : out std_logic;
	M0_SIZE   : out std_logic_vector(log2(BUFF_CAP) - 1 downto 0);

	---
	-- Random Access port 1
	---
	M1_A      : in  std_logic_vector(log2(BUFF_CAP) - 1 downto 0);
	M1_RO     : out std_logic_vector(7 downto 0);
	M1_GO     : out std_logic_vector(7 downto 0);
	M1_BO     : out std_logic_vector(7 downto 0);
	M1_WE     : in  std_logic;

	M1_RI     : in  std_logic_vector(7 downto 0);
	M1_GI     : in  std_logic_vector(7 downto 0);
	M1_BI     : in  std_logic_vector(7 downto 0);
	M1_RE     : in  std_logic;

	M1_DRDY   : out std_logic;
	M1_SIZE   : out std_logic_vector(log2(BUFF_CAP) - 1 downto 0)
);
end entity;

architecture single of buff_strategy is

	signal in_d  : std_logic_vector(23 downto 0);
	signal out_d : std_logic_vector(23 downto 0);
	
	signal m0_di : std_logic_vector(23 downto 0);
	signal m0_do : std_logic_vector(23 downto 0);

	signal m1_di : std_logic_vector(23 downto 0);
	signal m1_do : std_logic_vector(23 downto 0);

begin

	buff0_i : entity work.buffer_if
	generic map (
		BUFF_CAP => BUFF_CAP
	)
	port map (
		CLK       => CLK,
		RST       => RST,

		IN_DONE   => IN_DONE,
		IN_RDY    => IN_RDY,
		OUT_DONE  => OUT_DONE,
		MEM_DONE  => MEM_DONE,
		MEM_RDY   => MEM_RDY,

		IN_D      => in_d,
		IN_WE     => IN_WE,
		IN_FULL   => IN_FULL,

		OUT_D     => out_d,
		OUT_RE    => OUT_RE,
		OUT_EMPTY => OUT_EMPTY,

		M0_A      => M0_A,
		M0_DO     => m0_do,
		M0_WE     => M0_WE,
		M0_DI     => m0_di,
		M0_RE     => M0_RE,
		M0_DRDY   => M0_DRDY,

		M1_A      => M1_A,
		M1_DO     => m1_do,
		M1_WE     => M1_WE,
		M1_DI     => m1_di,
		M1_RE     => M1_RE,
		M1_DRDY   => M1_DRDY
	);

	-----------------------------

	in_d( 7 downto  0) <= IN_R;
	in_d(15 downto  8) <= IN_G;
	in_d(23 downto 16) <= IN_B;

	OUT_R <= out_d( 7 downto  0);
	OUT_G <= out_d(15 downto  8);
	OUT_B <= out_d(23 downto 16);

	m0_di( 7 downto  0) <= M0_RI;
	m0_di(15 downto  0) <= M0_GI;
	m0_di(23 downto 16) <= M0_BI;

	M0_RO <= m0_do( 7 downto  0);
	M0_GO <= m0_do(15 downto  8);
	M0_BO <= m0_do(31 downto 16);

	m1_di( 7 downto  0) <= M1_RI;
	m1_di(15 downto  0) <= M1_GI;
	m1_di(23 downto 16) <= M1_BI;

	M1_RO <= m1_do( 7 downto  0);
	M1_GO <= m1_do(15 downto  8);
	M1_BO <= m1_do(31 downto 16);

end architecture;

