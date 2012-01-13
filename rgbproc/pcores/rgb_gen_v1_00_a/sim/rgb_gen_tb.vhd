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
	signal gen_vs : std_logic;

	signal horiz  : integer;
	signal vert   : integer;

	signal x_hs   : std_logic;
	signal x_vs   : std_logic;
	signal x_de   : std_logic;

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

	horizp : process(CLK, RST, gen_hs, gen_vs)
		variable init : boolean := false;
	begin
		if rising_edge(CLK) then
			if RST = '1' or (gen_vs = '0' and not init) then
				horiz <= 0;
			elsif gen_vs = '1' and not init then
				init := true;
				horiz <= (horiz + 1) mod 800;
			else
				horiz <= (horiz + 1) mod 800;
			end if;
		end if;
	end process;

	vertp : process(CLK, RST, horiz)
	begin
		if rising_edge(CLK) then
			if RST = '1' then
				vert <= 0;
			elsif horiz = 799 then
				vert <= (vert + 1) mod 525;
			end if;
		end if;
	end process;

	x_hs <= '0' when horiz < 96 else '1';
	x_vs <= '0' when vert  >= 33 + 480 + 10 else '1';
	x_de <= '1' when horiz >= 96 + 48 and horiz < 96 + 48 + 640
	             and vert  >= 33 and vert  < 33 + 480 else '0';

	checkp : process(CLK, RST, gen_hs, x_hs, gen_vs, x_vs, gen_de, x_de)
		variable init : boolean := false;
	begin
		if rising_edge(CLK) then
			if RST = '1' then
				init := false;
			elsif gen_hs = '1' and gen_vs = '1' then
				init := true;
			end if;

			if RST = '0' and init then
				assert gen_hs = x_hs
					report "Invalid horizontal synchronization"
					severity failure;

				assert gen_vs = x_vs
					report "Invalid vertical synchronization"
					severity failure;

				assert gen_de = x_de
					report "Invalid data enable"
					severity failure;
			end if;
		end if;
	end process;

end architecture;
