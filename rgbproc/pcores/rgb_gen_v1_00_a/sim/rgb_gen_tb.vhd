-- rgb_gen_tb.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity rgb_gen_tb is
end entity;

architecture testbench of rgb_gen_tb is

	signal clk    : std_logic;
	signal rst    : std_logic;

	signal gen_r  : std_logic_vector(7 downto 0);
	signal gen_g  : std_logic_vector(7 downto 0);
	signal gen_b  : std_logic_vector(7 downto 0);
	signal gen_de : std_logic;
	signal gen_hs : std_logic;
	signal gen_ve : std_logic;

begin

	gen_i : entity work.rgb_gen
	port map (
		CLK => clk,
		RST => rst,

		R   => gen_r,
		G   => gen_g,
		B   => gen_b,
		DE  => gen_de,
		HS  => gen_hs,
		VS  => gen_vs
	);

	clkgen_i : entity work.clkgen
	port map (
		CLK => clk,
		RST => rst
	);

end architecture;
