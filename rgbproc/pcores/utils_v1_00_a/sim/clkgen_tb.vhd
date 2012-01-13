-- clkgen_tb.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity clkgen_tb is
end entity;

architecture testbench of clkgen_tb is

	signal clk_0   : std_logic;
	signal rst_0   : std_logic;

	signal clk_10  : std_logic;
	signal rst_10  : std_logic;

	signal clk_45  : std_logic;
	signal rst_45  : std_logic;

	signal clk_90  : std_logic;
	signal rst_90  : std_logic;

	signal clk_180 : std_logic;
	signal rst_180 : std_logic;

	signal clk_360 : std_logic;
	signal rst_360 : std_logic;

begin

	clkgen_0 : entity work.clkgen
	generic map (
		FREQ => 200.0,
		RST_CYCLES => 200,
		PHASE => 0
	)
	port map (
		CLK => clk_0,
		RST => rst_0
	);

	clkgen_10 : entity work.clkgen
	generic map (
		FREQ => 200.0,
		RST_CYCLES => 200,
		PHASE => 10
	)
	port map (
		CLK => clk_10,
		RST => rst_10
	);

	clkgen_45 : entity work.clkgen
	generic map (
		FREQ => 200.0,
		RST_CYCLES => 200,
		PHASE => 45
	)
	port map (
		CLK => clk_45,
		RST => rst_45
	);

	clkgen_90 : entity work.clkgen
	generic map (
		FREQ => 200.0,
		RST_CYCLES => 200,
		PHASE => 90
	)
	port map (
		CLK => clk_90,
		RST => rst_90
	);

	clkgen_180 : entity work.clkgen
	generic map (
		FREQ => 200.0,
		RST_CYCLES => 200,
		PHASE => 180
	)
	port map (
		CLK => clk_180,
		RST => rst_180
	);

	clkgen_360 : entity work.clkgen
	generic map (
		FREQ => 200.0,
		RST_CYCLES => 200,
		PHASE => 360
	)
	port map (
		CLK => clk_360,
		RST => rst_360
	);

end architecture;
