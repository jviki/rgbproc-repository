-- highpass_filter.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.log2;

library utils_v1_00_a;
use utils_v1_00_a.ctl_bypass;
use utils_v1_00_a.adder_tree;

entity highpass_filter is
port (
	CLK     : in  std_logic;
	CE 	: in  std_logic;
	
	WIN_R   : in  std_logic_vector(9 * 8 - 1 downto 0);
	WIN_G   : in  std_logic_vector(9 * 8 - 1 downto 0);
	WIN_B   : in  std_logic_vector(9 * 8 - 1 downto 0);
	WIN_DE  : in  std_logic;
	WIN_HS  : in  std_logic;
	WIN_VS  : in  std_logic;

	OUT_R   : out std_logic_vector(7 downto 0);
	OUT_G   : out std_logic_vector(7 downto 0);
	OUT_B   : out std_logic_vector(7 downto 0);
	OUT_DE  : out std_logic;
	OUT_HS  : out std_logic;
	OUT_VS  : out std_logic
);
end entity;

architecture impl_n1_2_n1 of highpass_filter is

	constant VECTOR_LENGTH      : integer := 3;
	constant ADDER_LEVELS_COUNT : integer := log2(VECTOR_LENGTH);

	---------------------------------

	subtype mapped_t is std_logic_vector(7 downto 0);

	---
	-- Maps the input 10 bit signed number to output 8 bit unsigned number.
	-- Mapping of x:
	--  x > 0: y := x / 4
	--  x < 0: y := abs(x) / 4
	--  x = 0: y := 127
	--
	-- The value x = 0 should be mapped to 127.5. It is floored down to 127.
	---
	function map_to_range8(a : in std_logic_vector(9 downto 0)) return mapped_t is
		variable val : integer;
		variable res : std_logic_vector(9 downto 0);
		variable y   : std_logic_vector(7 downto 0);
	begin
		val := conv_integer(signed(a));

		if val > 0 then
			res := conv_std_logic_vector(val, 10);
		elsif val < 0 then
			res := conv_std_logic_vector(-val, 10);
		else
			return conv_std_logic_vector(127, 8);
		end if;

		y := res(9 downto 2);
		return y;
	end function;

	---------------------------------

	signal mul_r  : std_logic_vector(VECTOR_LENGTH * 10 - 1 downto 0);
	signal mul_g  : std_logic_vector(VECTOR_LENGTH * 10 - 1 downto 0);
	signal mul_b  : std_logic_vector(VECTOR_LENGTH * 10 - 1 downto 0);

	signal sum_r  : std_logic_vector(9 downto 0);
	signal sum_g  : std_logic_vector(9 downto 0);
	signal sum_b  : std_logic_vector(9 downto 0);

	signal sum_ce : std_logic;

begin

	mul_r( 9 downto  0) <= not("00" & WIN_R(15 downto  8)) + 1;
	mul_g( 9 downto  0) <= not("00" & WIN_G(15 downto  8)) + 1;
	mul_b( 9 downto  0) <= not("00" & WIN_B(15 downto  8)) + 1;

	mul_r(19 downto 10) <= "0" & WIN_R(39 downto 32) & "0";
	mul_g(19 downto 10) <= "0" & WIN_G(39 downto 32) & "0";
	mul_b(19 downto 10) <= "0" & WIN_B(39 downto 32) & "0";

	mul_r(29 downto 20) <= not("00" & WIN_R(63 downto 56)) + 1;
	mul_g(29 downto 20) <= not("00" & WIN_G(63 downto 56)) + 1;
	mul_b(29 downto 20) <= not("00" & WIN_B(63 downto 56)) + 1;

	---------------------------------

	---
	-- Sum of the results
	---
	adder_tree_r_i : entity utils_v1_00_a.adder_tree
	generic map (
		INPUT_COUNT => VECTOR_LENGTH,
		DATA_WIDTH  => 10
	)
	port map (
		CLK  => CLK,
		CE   => CE,
		DIN  => mul_r,
		DOUT => sum_r
	);

	adder_tree_g_i : entity utils_v1_00_a.adder_tree
	generic map (
		INPUT_COUNT => VECTOR_LENGTH,
		DATA_WIDTH  => 10
	)
	port map (
		CLK  => CLK,
		CE   => CE,
		DIN  => mul_g,
		DOUT => sum_g		
	);

	adder_tree_b_i : entity utils_v1_00_a.adder_tree
	generic map (
		INPUT_COUNT => VECTOR_LENGTH,
		DATA_WIDTH  => 10
	)
	port map (
		CLK  => CLK,
		CE   => CE,
		DIN  => mul_b,
		DOUT => sum_b		
	);

	---------------------------------

	OUT_R <= map_to_range8(sum_r);
	OUT_G <= map_to_range8(sum_g);
	OUT_B <= map_to_range8(sum_b);

	---------------------------------

	ctl_bypass_i : entity utils_v1_00_a.ctl_bypass
	generic map (
		DWIDTH : integer := 3;
		DEPTH  : integer := ADDER_LEVELS_COUNT
	)
	port map (
		CLK => CLK,
		CE  => CE,
		DI(0) => WIN_DE,
		DI(1) => WIN_HS,
		DI(2) => WIN_VS,
		DO(0) => OUT_DE,
		DO(1) => OUT_HS,
		DO(2) => OUT_VS
	);

end architecture;

