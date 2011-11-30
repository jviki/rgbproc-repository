-- clk_is_up_tb.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.math_real.uniform;

entity clk_is_up_tb is
end entity;

architecture testbench of clk_is_up_tb is

	constant FREQ     : real := 100.0;
	constant PERIOD   : time := 1 us / FREQ;

	constant SLOW_FREQ   : real := 26.0;
	constant SLOW_PERIOD : time := 1 us / SLOW_FREQ;

	signal clk        : std_logic;
	signal rst        : std_logic;

	signal clkslow    : std_logic;

	-- from ISE
	shared variable aseed0 : integer := 844396720;
	shared variable aseed1 : integer := 821616997;

	impure function getrand return boolean is
		variable r : real;
	begin
		uniform(aseed0, aseed1, r);
		return r < 0.5;
	end function;

	shared variable bseed0 : integer := 844396720;
	shared variable bseed1 : integer := 821616997;

	impure function getdelay return time is
		variable r : real;
	begin
		uniform(bseed0, bseed1, r);
		return (64.0 * r) * PERIOD;
	end function;

begin

	dut_i : entity work.clk_is_up
	generic map (
		MAX_DELAY => 128
	)
	port map (
		CLK  => clk,
		RST  => rst,
		IN_CLK => clkslow,
		OUT_UP => open
	);

	-------------------------

	clkslowgen_i : process
		constant never : boolean := false;
	begin
		if getrand or never then
			clkslow <= '0';
			wait for SLOW_PERIOD / 2;

			clkslow <= '1';
			wait for SLOW_PERIOD / 2;
		else
			clkslow <= '0';
			wait for getdelay;

			clkslow <= '1';
			wait for SLOW_PERIOD / 2;
		end if;
	end process;

	clkgen_i : process
	begin
		clk <= '0';
		wait for PERIOD / 2;
		clk <= '1';
		wait for PERIOD / 2;
	end process;

	rstgen_i : process
	begin
		rst <= '1';
		wait for 32 * PERIOD;
		rst <= '0';
		wait;
	end process;

end architecture;

