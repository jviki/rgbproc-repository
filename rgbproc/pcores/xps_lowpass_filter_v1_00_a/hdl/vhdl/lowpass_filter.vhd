-- lowpass_filter.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library rgb_commons_v1_00_a;
use rgb_commons_v1_00_a.rgb_reg;

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.log2;

entity lowpass_filter is
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
	OUT_REQ : in  std_logic
);
end entity;

architecture full of lowpass_filter is

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

	type matrix_t : array(0 to 8) of integer;

	constant FILTER_MATRIX : matrix_t :=
	(
		4, 3, 4,
		3, 2, 3,
		4, 3, 4
	);

	---------------------------------
	
	constant ADDER_LEVELS_COUNT : integer := log2(9);
	
	---------------------------------

	signal div_r : std_logic_vector(9 * 8 - 1 downto 0);
	signal div_g : std_logic_vector(9 * 8 - 1 downto 0);
	signal div_b : std_logic_vector(9 * 8 - 1 downto 0);

	signal sum_r : std_logic_vector(7 downto 0);
	signal sum_g : std_logic_vector(7 downto 0);
	signal sum_b : std_logic_vector(7 downto 0);

	signal valid_vec : std_logic_vector(ADDER_LEVELS_COUNT - 1 downto 0);
	signal valid_px  : std_logic;

begin
	
	OUT_R <= sum_r;
	OUT_G <= sum_g;
	OUT_B <= sum_b;

	---------------------------------

	---
	-- Shift register for validity flags.
	-- Vector valid_vec(max) represents valid
	-- flag of data coming from adder_tree.
	---
	valid_vecp : process(CLK, valid_px)
	begin
		if rising_edge(CLK) then
			for i in valid_vec'range loop
				if i = 0 then
					valid_vec(0) <= valid_px;
				elsif i > 0 then
					valid_vec(i) <= valid_vec(i - 1);
				end if;
			end loop;
		end if;
	end process;

	---------------------------------

	---
	-- Division
	---
gen_filter_division: for i in 0 to 8 
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
		INPUT_COUNT => 9
	)
	port map (
		CLK  => CLK,
		DIN  => div_r,
		DOUT => sum_r		
	);

	adder_tree_g_i : entity adder_tree
	generic map (
		INPUT_COUNT => 9
	)
	port map (
		CLK  => CLK,
		DIN  => div_g,
		DOUT => sum_g		
	);

	adder_tree_b_i : entity adder_tree
	generic map (
		INPUT_COUNT => 9
	)
	port map (
		CLK  => CLK,
		DIN  => div_b,
		DOUT => sum_b		
	);

end architecture;

