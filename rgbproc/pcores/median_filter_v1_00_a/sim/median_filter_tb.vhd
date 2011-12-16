-- median_filter_tb.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.math_real.uniform;

use std.textio.all;

entity median_filter_tb is
end entity;

architecture testbench of median_filter_tb is

	constant BASE_MHZ : time := 1 us;
	constant FREQ     : real := 25.0;
	constant PERIOD   : time := BASE_MHZ / FREQ;

	signal clk     : std_logic;
	signal rst     : std_logic;

	signal win_r   : std_logic_vector(71 downto 0);
	signal win_g   : std_logic_vector(71 downto 0);
	signal win_b   : std_logic_vector(71 downto 0);

	signal win_de  : std_logic_vector(8 downto 0);
	signal win_hs  : std_logic_vector(8 downto 0);
	signal win_vs  : std_logic_vector(8 downto 0);
	
	signal out_r   : std_logic_vector(7 downto 0);
	signal out_g   : std_logic_vector(7 downto 0);
	signal out_b   : std_logic_vector(7 downto 0);
	
	signal out_de  : std_logic;
	signal out_hs  : std_logic;
	signal out_vs  : std_logic;

	signal filter_ce : std_logic;

	--------------

	-- from ISE
	shared variable aseed0 : integer := 844396720;
	shared variable aseed1 : integer := 821616997;

	impure function getrand return real is
		variable r : real;
	begin
		uniform(aseed0, aseed1, r);
		return r;
	end function;

	subtype win_t is std_logic_vector(71 downto 0);

	impure function gen_win_color return win_t is
		variable r   : real;
		variable o   : win_t;
	begin
		for i in win_t'range loop
			r := getrand;

			if r < 0.5 then
				o(i) := '0';
			else
				o(i) := '1';
			end if;			
		end loop;

		return o;
	end function;
	
	subtype ctl_t is std_logic_vector(8 downto 0);
	
	impure function gen_win_ctl return ctl_t is
		variable r   : real;
		variable max : integer := 2 ** ctl_t'length;
	begin
		r := getrand;
		return conv_std_logic_vector(integer(r * real(max)), ctl_t'length);
	end function;

	--------------

	file file_input  : TEXT open WRITE_MODE  is "file_input.txt";
	file file_output : TEXT open WRITE_MODE  is "file_output.txt";

	procedure write_input(r, g, b : in std_logic_vector(7 downto 0); de, hs, vs : in std_logic) is
		variable l : line;
	begin
		write(l, conv_integer(r));
		write(l, string'(" "));
		write(l, conv_integer(g));
		write(l, string'(" "));
		write(l, conv_integer(b));
		write(l, string'(" "));
		write(l, conv_integer(de));
		write(l, string'(" "));
		write(l, conv_integer(hs));
		write(l, string'(" "));
		write(l, conv_integer(vs));
		writeline(file_input, l);
	end procedure;

	procedure write_output(r, g, b : in std_logic_vector(7 downto 0); de, hs, vs : in std_logic) is
		variable l : line;
	begin
		write(l, conv_integer(r));
		write(l, string'(" "));
		write(l, conv_integer(g));
		write(l, string'(" "));
		write(l, conv_integer(b));
		write(l, string'(" "));
		write(l, conv_integer(de));
		write(l, string'(" "));
		write(l, conv_integer(hs));
		write(l, string'(" "));
		write(l, conv_integer(vs));
		writeline(file_output, l);
	end procedure;

	subtype color_t is std_logic_vector(7 downto 0);
	type input9_t   is array(0 to 8) of color_t;

	function compute_median9(input : in input9_t) return color_t is
		variable tmp  : color_t;
		variable sort : input9_t;
	begin
		sort := input;
		
		for k in 0 to 4 loop
			for i in 0 to 7 loop
				if sort(i) > sort(i + 1) then
					tmp         := sort(i);
					sort(i)     := sort(i + 1);
					sort(i + 1) := tmp;
				end if;
			end loop;
		end loop;

		return input(4);
	end function;

	function compute_median9(input : std_logic_vector(71 downto 0)) return color_t is
		variable arr : input9_t;
	begin
		for i in 0 to 8 loop
			arr(i) := input((i + 1) * 8 - 1 downto i * 8);
		end loop;

		return compute_median9(arr);
	end function;

begin

	median_filter_i : entity work.median_filter
	generic map (
		MATRIX_SIZE => 3
	)
	port map (
		CLK    => clk,
		CE     => filter_ce,

		WIN_R  => win_r,
		WIN_G  => win_g,
		WIN_B  => win_b,
		WIN_DE => win_de,
		WIN_HS => win_hs,
		WIN_VS => win_vs,

		OUT_R  => out_r,
		OUT_G  => out_g,
		OUT_B  => out_b,
		OUT_DE => out_de,
		OUT_HS => out_hs,
		OUT_VS => out_vs
	);

	----------------------

	gen_win: process
	begin
		win_r  <= (others => '0');
		win_g  <= (others => '0');
		win_b  <= (others => '0');
		win_de <= (others => '0');
		win_hs <= (others => '0');
		win_vs <= (others => '0');
		filter_ce <= '0';

		wait until rst = '0';
		wait until rising_edge(clk);

		for i in 1 to 512 loop
			win_r  <= gen_win_color;
			win_g  <= gen_win_color;
			win_b  <= gen_win_color;
			win_de <= gen_win_ctl;
			win_hs <= gen_win_ctl;
			win_vs <= gen_win_ctl;
			filter_ce <= '1';

			wait until rising_edge(clk);
			write_input(compute_median9(win_r), compute_median9(win_g), compute_median9(win_b),
			            win_de(4), win_hs(4), win_vs(4));
		end loop;

		wait;
	end process;

	get_data : process(clk, filter_ce)
	begin
		if rising_edge(clk) then
			if filter_ce = '1' then
				write_output(out_r, out_g, out_b, out_de, out_hs, out_vs);
			end if;
		end if;
	end process;

	----------------------

	clkgenp : process
	begin
		clk <= '1';
		wait for PERIOD / 2;
		clk <= '0';
		wait for PERIOD / 2;
	end process;

	rstgenp : process
	begin
		rst <= '1';
		wait for 4 * PERIOD;
		wait until rising_edge(clk);
		rst <= '0';
		wait;
	end process;

end architecture;
