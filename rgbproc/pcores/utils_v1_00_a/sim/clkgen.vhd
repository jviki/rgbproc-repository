-- clkgen.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>
-- Copyright (C) 2011, 2012 Jan Viktorin

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity clkgen is
generic (
	BASE  : time := 1 us;  -- MHz
	FREQ  : real := 100.0;
	PHASE : integer := 0;  -- degrees
	RST_CYCLES : integer := 16
);
port (
	CLK  : out std_logic;
	RST  : out std_logic
);
end entity;

architecture full of clkgen is

	constant PERIOD      : time := BASE / FREQ;
	constant PHASE_DELAY : time := PERIOD * (real(PHASE) / 360.0);
	
	signal internal_clk  : std_logic;

begin

	CLK <= internal_clk;

	clk_gen : process
		variable lock : boolean := false;
	begin
		internal_clk <= '0';

		if not lock then
			wait for PHASE_DELAY;
			lock := true;
		else
			wait for PERIOD / 2;
			internal_clk <= '1';
			wait for PERIOD / 2;
		end if;
	end process;

	rst_gen : entity work.rstgen
	generic map (
		CYCLES => RST_CYCLES
	)
	port map (
		CLK => internal_clk,
		RST => RST
	);

end architecture;
