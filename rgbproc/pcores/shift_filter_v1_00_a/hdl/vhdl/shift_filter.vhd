-- shift_filter.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>
-- Copyright (C) 2011, 2012 Jan Viktorin

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.log2;

library utils_v1_00_a;
use utils_v1_00_a.ctl_bypass;
use utils_v1_00_a.adder_tree;

---
-- Performs (dividing) shift-and-sum operation on RGB window.
-- The shifts can be specified by generics. Can be used to
-- implement eg. simple low-pass filters.
--
-- Default configuration:
--  4 3 4         1/16 1/8 1/16
--  3 2 3  thus:   1/8 1/4  1/8
--  4 3 4         1/16 1/8 1/16
---
entity shift_filter is
generic (
	M0x0      : integer := 4;
	M1x0      : integer := 3;
	M2x0      : integer := 4;
	M0x1      : integer := 3;
	M1x1      : integer := 2;
	M2x1      : integer := 3;
	M0x2      : integer := 4;
	M1x2      : integer := 3;
	M2x2      : integer := 4
);
port (
	CLK     : in  std_logic;
	CE 	: in  std_logic;
	
	WIN_R   : in  std_logic_vector(9 * 8 - 1 downto 0);
	WIN_G   : in  std_logic_vector(9 * 8 - 1 downto 0);
	WIN_B   : in  std_logic_vector(9 * 8 - 1 downto 0);
	WIN_DE  : in  std_logic_vector(8 downto 0);
	WIN_HS  : in  std_logic_vector(8 downto 0);
	WIN_VS  : in  std_logic_vector(8 downto 0);

	OUT_R   : out std_logic_vector(7 downto 0);
	OUT_G   : out std_logic_vector(7 downto 0);
	OUT_B   : out std_logic_vector(7 downto 0);
	OUT_DE  : out std_logic;
	OUT_HS  : out std_logic;
	OUT_VS  : out std_logic
);
end entity;

---
-- Implementation uses division by a power of 2 and adder tree
-- to sum the result.
---
architecture full of shift_filter is

	subtype divided_t is std_logic_vector(7 downto 0);

	---
	-- Performs division of signal by a power of 2.
	---
	function divide_by2(signal c : in std_logic_vector(7 downto 0); m : integer)
		return divided_t is
	begin
		assert m > 0 and m < 7
			report "Invalid exponent of expression 2^m: " & integer'image(m)
			severity failure;

		--     padding                   divided
		return (m - 1 downto 0 => '0') & c(7 downto m);
	end function;
	
	---------------------------------

	constant MATRIX_LENGTH : integer := 9;

	type matrix_t is array(0 to MATRIX_LENGTH - 1) of integer;

	constant FILTER_MATRIX : matrix_t :=
	(
	 	M0x0, M1x0, M2x0,
		M0x1, M1x1, M2x1,
		M0x2, M1x2, M2x2
	);

	---------------------------------
	
	constant ADDER_LEVELS_COUNT : integer := log2(MATRIX_LENGTH);
	
	---------------------------------

	signal div_r : std_logic_vector(MATRIX_LENGTH * 8 - 1 downto 0);
	signal div_g : std_logic_vector(MATRIX_LENGTH * 8 - 1 downto 0);
	signal div_b : std_logic_vector(MATRIX_LENGTH * 8 - 1 downto 0);

	signal sum_r : std_logic_vector(7 downto 0);
	signal sum_g : std_logic_vector(7 downto 0);
	signal sum_b : std_logic_vector(7 downto 0);

	signal sum_ce    : std_logic;

begin
	
	OUT_R <= sum_r;
	OUT_G <= sum_g;
	OUT_B <= sum_b;
	
	---------------------------------

	---
	-- Division
	---
gen_filter_division: for i in 0 to MATRIX_LENGTH - 1 
generate

	div_r((i + 1) * 8 - 1 downto i * 8) <= divide_by2(WIN_R((i + 1) * 8 - 1 downto i * 8), FILTER_MATRIX(i));
	div_g((i + 1) * 8 - 1 downto i * 8) <= divide_by2(WIN_G((i + 1) * 8 - 1 downto i * 8), FILTER_MATRIX(i));
	div_b((i + 1) * 8 - 1 downto i * 8) <= divide_by2(WIN_B((i + 1) * 8 - 1 downto i * 8), FILTER_MATRIX(i));

end generate;

	---------------------------------

	---
	-- Sum of the results
	---
	adder_tree_r_i : entity utils_v1_00_a.adder_tree
	generic map (
		INPUT_COUNT => MATRIX_LENGTH
	)
	port map (
		CLK  => CLK,
		CE   => CE,
		DIN  => div_r,
		DOUT => sum_r		
	);

	adder_tree_g_i : entity utils_v1_00_a.adder_tree
	generic map (
		INPUT_COUNT => MATRIX_LENGTH
	)
	port map (
		CLK  => CLK,
		CE   => CE,
		DIN  => div_g,
		DOUT => sum_g		
	);

	adder_tree_b_i : entity utils_v1_00_a.adder_tree
	generic map (
		INPUT_COUNT => MATRIX_LENGTH
	)
	port map (
		CLK  => CLK,
		CE   => CE,
		DIN  => div_b,
		DOUT => sum_b		
	);

	---------------------------------

	ctl_bypass_i : entity utils_v1_00_a.ctl_bypass
	generic map (
		DWIDTH => 3,
		DEPTH  => ADDER_LEVELS_COUNT
	)
	port map (
		CLK    => CLK,
		CE     => CE,
		DI(0)  => WIN_DE(4),
		DI(1)  => WIN_HS(4),
		DI(2)  => WIN_VS(4),
		DO(0)  => OUT_DE,
		DO(1)  => OUT_HS,
		DO(2)  => OUT_VS
	);
	
end architecture;

