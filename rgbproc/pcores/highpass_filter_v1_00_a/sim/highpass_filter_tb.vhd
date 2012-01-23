-- highpass_filter_tb.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>
-- Copyright (C) 2011, 2012 Jan Viktorin

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity highpass_filter_tb is
end entity;

architecture testbench of highpass_filter_tb is

	signal clk : std_logic;
	signal rst : std_logic;

	signal win_r  : std_logic_vector(71 downto 0);
	signal win_g  : std_logic_vector(71 downto 0);
	signal win_b  : std_logic_vector(71 downto 0);
	signal win_de : std_logic_vector(8 downto 0);
	signal win_hs : std_logic_vector(8 downto 0);
	signal win_vs : std_logic_vector(8 downto 0);

	signal out_r  : std_logic_vector(7 downto 0);
	signal out_g  : std_logic_vector(7 downto 0);
	signal out_b  : std_logic_vector(7 downto 0);
	signal out_de : std_logic;
	signal out_hs : std_logic;
	signal out_vs : std_logic;

begin

	clkgen_i : entity work.clkgen
	port map (
		CLK => clk,
		RST => rst
	);

	gen_i : entity work.vga_matrix_gen
	port map (
		CLK => clk,
		RST => rst,
		R   => win_r,
		G   => win_g,
		B   => win_b,
		HS  => win_hs,
		VS  => win_vs,
		DE  => win_de
	);

	dut_i : entity work.highpass_filter
	port map (
		CLK => clk,
		CE  => '1',

		WIN_R   => win_r,
		WIN_G   => win_g,
		WIN_B   => win_b,
		WIN_DE  => win_de,
		WIN_HS  => win_hs,
		WIN_VS  => win_vs,

		OUT_R  => out_r,
		OUT_G  => out_g,
		OUT_B  => out_b,
		OUT_DE => out_de,
		OUT_HS => out_hs,
		OUT_VS => out_vs
	);

	rgb_mon_i : entity work.file_pixel_mon
	port map (
		CLK => clk,
		RST => rst,

		R   => out_r,
		G   => out_g,
		B   => out_b,
		DE  => out_de,
		HS  => out_hs,
		VS  => out_vs
	);

end architecture;
