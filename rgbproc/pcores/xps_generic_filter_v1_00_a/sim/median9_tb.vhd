-- median9_tb.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.math_real.uniform;

use std.textio.all;
use ieee.std_logic_textio.all;

entity median9_tb is
end entity;

architecture testbench of median9_tb is

	constant FREQ   : real := 100.0;
	constant PERIOD : time := 1 us / FREQ;

	signal clk      : std_logic;
	signal rst      : std_logic;

	signal data_vec : std_logic_vector(9 * 8 - 1 downto 0);
	signal data_ce  : std_logic;
	signal median   : std_logic_vector(7 downto 0);

	-- from ISE
	shared variable seed0 : integer := 844396720;
	shared variable seed1 : integer := 821616997;

	impure function getindex(min, max : integer) return integer is
		variable r : real;
		variable x : integer;
		variable k : integer := max - min + 1;
	begin
		uniform(seed0, seed1, r);
		x := integer(r * real(k));

		while x < min or x > max loop
			uniform(seed0, seed1, r);
			x := integer(r * real(k));
		end loop;

		return x;
	end function;

	procedure genvec(signal data_vec : out std_logic_vector(9 * 8 - 1 downto 0)) is
		type array_t is array(1 to 9) of integer;
		variable vec : array_t;
		variable tmp : integer;
		variable idx : integer;
	begin
		vec := (0, 1, 2, 3, 4, 5, 6, 7, 8);

		for i in 1 to 9 loop
			idx      := getindex(1, 9);
			tmp      := vec(i);
			vec(i)   := vec(idx);
			vec(idx) := tmp;
		end loop;

		for i in 1 to 9 loop
			data_vec(i * 8 - 1 downto (i - 1) * 8) <= conv_std_logic_vector(vec(i), 8);
		end loop;
	end procedure;

begin

	dut_i : entity work.median9
	port map (
		CLK => clk,
		CE  => '1',

		DI => data_vec,
		DO => median
	);

	---------------------------
	
	process
		constant COUNT : integer := 9 ** 9;
	begin
		data_ce <= '0';
		wait until rst = '0';
		wait until rising_edge(clk);

		for i in 1 to COUNT loop
			genvec(data_vec);
			data_ce <= '1';
			wait until rising_edge(clk);
		end loop;
	end process;

	process(clk, rst, data_ce, median)
		variable i : integer := 0;
	begin
		if rising_edge(clk) then
			if rst = '1' then
				i := 0;
			elsif data_ce = '1' then
				if i < 8 then
					i := i + 1;
				else
					assert median = 4
						report "Invalid median: " & integer'image(conv_integer(median))
						severity error;				
				end if;
			end if;
		end if;
	end process;
	
	---------------------------

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

