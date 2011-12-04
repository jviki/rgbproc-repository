-- shift_3x3_filter.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library rgb_commons_v1_00_a;
use rgb_commons_v1_00_a.rgb_reg;

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.log2;

entity shift_3x3_filter is
generic (
	M0x0      : integer := 4;
	M1x0      : integer := 3;
	M2x0      : integer := 4;
	M0x1      : integer := 3;
	M1x1      : integer := 2;
	M2x1      : integer := 3;
	M0x2      : integer := 4;
	M1x2      : integer := 3;
	M2x2      : integer := 4;
	BYPASS_EN : boolean := true
);
port (
	CLK     : in  std_logic;
	RST	: in  std_logic;
	
	WIN_R   : in  std_logic_vector(9 * 8 - 1 downto 0);
	WIN_G   : in  std_logic_vector(9 * 8 - 1 downto 0);
	WIN_B   : in  std_logic_vector(9 * 8 - 1 downto 0);
	WIN_VLD : in  std_logic;
	WIN_REQ : out std_logic;

	OUT_R   : out std_logic_vector(7 downto 0);
	OUT_G   : out std_logic_vector(7 downto 0);
	OUT_B   : out std_logic_vector(7 downto 0);
	OUT_VLD : out std_logic;
	OUT_REQ : in  std_logic;

	BYPASS  : out std_logic_vector(23 downto 0)
);
end entity;

---
-- Implementation uses division by a power of 2 and adder tree
-- to sum the result.
---
architecture full of shift_3x3_filter is

	---
	-- Performs division of signal by a power of 2.
	---
	function divide_by2(signal c : in std_logic_vector(7 downto 0); m : integer)
		return std_logic_vector(7 downto 0) is
	begin
		assert m > 0 and m < 7
			report "Invalid exponent of expression 2^m: " & integer'image(m)
			severity failure;

		--     padding                   divided
		return (m - 1 downto 0 => '0') & c(7 downto m);
	end function;
	
	---------------------------------

	constant MATRIX_LENGTH : integer := 9;

	type matrix_t : array(0 to MATRIX_LENGTH - 1) of integer;

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

	rgb_handshake_i : entity work.rgb_handshake
	generic map (
		LINE_DEPTH => ADDER_LEVELS_COUNT
	)
	port map (
		CLK     => CLK,
		IN_REQ  => WIN_REQ,
		IN_VLD  => WIN_VLD,
		OUT_REQ => OUT_REQ,
		OUT_VLD => OUT_VLD,

		LINE_CE => sum_ce
	);
	
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
	adder_tree_r_i : entity adder_tree
	generic map (
		INPUT_COUNT => MATRIX_LENGTH
	)
	port map (
		CLK  => CLK,
		CE   => sum_ce,
		DIN  => div_r,
		DOUT => sum_r		
	);

	adder_tree_g_i : entity adder_tree
	generic map (
		INPUT_COUNT => MATRIX_LENGTH
	)
	port map (
		CLK  => CLK,
		CE   => sum_ce,
		DIN  => div_g,
		DOUT => sum_g		
	);

	adder_tree_b_i : entity adder_tree
	generic map (
		INPUT_COUNT => MATRIX_LENGTH
	)
	port map (
		CLK  => CLK,
		CE   => sum_ce,
		DIN  => div_b,
		DOUT => sum_b		
	);

	---------------------------------

	---
	-- Bypass
	---

gen_bypass: if BYPASS_EN = true
generate

	bypass_i : entity work.bypass_shreg
	generic map (
		LINE_DEPTH => ADDER_LEVELS_COUNT
	)
	port map (
		CLK => CLK,
		CE  => sum_ce,

		DI( 7 downto  0) => WIN_R(39 downto 32);
		DI(15 downto  8) => WIN_G(39 downto 32);
		DI(23 downto 16) => WIN_B(39 downto 32);
		DO  => BYPASS
	);
	
end generate;

end architecture;

