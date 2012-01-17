-- highpass_filter_tb.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity highpass_filter_tb is
end entity;

architecture testbench of highpass_filter_tb is

	signal clk : std_logic;
	signal rst : std_logic;

	signal vga_r  : std_logic_vector(7 downto 0);
	signal vga_g  : std_logic_vector(7 downto 0);
	signal vga_b  : std_logic_vector(7 downto 0);
	signal vga_hs : std_logic;
	signal vga_vs : std_logic;

	signal gen_r  : std_logic_vector(7 downto 0);
	signal gen_g  : std_logic_vector(7 downto 0);
	signal gen_b  : std_logic_vector(7 downto 0);
	signal gen_de : std_logic;
	signal gen_hs : std_logic;
	signal gen_vs : std_logic;

	signal out_r  : std_logic_vector(7 downto 0);
	signal out_g  : std_logic_vector(7 downto 0);
	signal out_b  : std_logic_vector(7 downto 0);
	signal out_de : std_logic;
	signal out_hs : std_logic;
	signal out_vs : std_logic;

begin

	rstgen_i : entity work.rstgen
	generic map (
		CYCLES => 16		
	)
	port map (
		CLK => clk,
		RST => rst
	);

	gen_i : entity work.vga_gen
	port map (
		CLK => clk,
		R   => vga_r,
		G   => vga_g,
		B   => vga_b,
		HS  => vga_hs,
		VS  => vga_vs		
	);

	rgb_in_i : entity work.rgb_in
	port map (
		VGA_CLK => clk,
		VGA_R   => vga_r,
		VGA_G   => vga_g,
		VGA_B   => vga_b,
		VGA_HS  => vga_hs,
		VGA_VS  => vga_vs,
		VGA_ODD_EVEN_B => 'X',
		VGA_SOGOUT     => 'X',

		RGB_R   => gen_r,
		RGB_G   => gen_g,
		RGB_B   => gen_b,
		RGB_DE  => gen_de,
		RGB_HS  => gen_hs,
		RGB_VS  => gen_vs
	);

	dut_i : entity work.highpass_filter
	port map (
		CLK => clk,
		CE  => '1',

		IN_R   => gen_r,
		IN_G   => gen_g,
		IN_B   => gen_b,
		IN_DE  => gen_de,
		IN_HS  => gen_hs,
		IN_VS  => gen_vs,

		OUT_R  => out_r,
		OUT_G  => out_g,
		OUT_B  => out_b,
		OUT_DE => out_de,
		OUT_HS => out_hs,
		OUT_VS => out_vs
	);

end architecture;
