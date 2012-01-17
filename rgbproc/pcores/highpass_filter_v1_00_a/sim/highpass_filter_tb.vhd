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

	signal fields0_r  : std_logic_vector(23 downto 0);
	signal fields0_g  : std_logic_vector(23 downto 0);
	signal fields0_b  : std_logic_vector(23 downto 0);
	signal fields0_de : std_logic_vector(2 downto 0);
	signal fields0_hs : std_logic_vector(2 downto 0);
	signal fields0_vs : std_logic_vector(2 downto 0);

	signal fields1_r  : std_logic_vector(23 downto 0);
	signal fields1_g  : std_logic_vector(23 downto 0);
	signal fields1_b  : std_logic_vector(23 downto 0);
	signal fields1_de : std_logic_vector(2 downto 0);
	signal fields1_hs : std_logic_vector(2 downto 0);
	signal fields1_vs : std_logic_vector(2 downto 0);

	signal fields2_r  : std_logic_vector(23 downto 0);
	signal fields2_g  : std_logic_vector(23 downto 0);
	signal fields2_b  : std_logic_vector(23 downto 0);
	signal fields2_de : std_logic_vector(2 downto 0);
	signal fields2_hs : std_logic_vector(2 downto 0);
	signal fields2_vs : std_logic_vector(2 downto 0);

	signal line0_r    : std_logic_vector(7 downto 0);
	signal line0_g    : std_logic_vector(7 downto 0);
	signal line0_b    : std_logic_vector(7 downto 0);
	signal line0_de   : std_logic;
	signal line0_hs   : std_logic;
	signal line0_vs   : std_logic;

	signal line1_r    : std_logic_vector(7 downto 0);
	signal line1_g    : std_logic_vector(7 downto 0);
	signal line1_b    : std_logic_vector(7 downto 0);
	signal line1_de   : std_logic;
	signal line1_hs   : std_logic;
	signal line1_vs   : std_logic;

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

	line0 : entity work.rgb_line_buff
	generic map (
		WIDTH  => 640,
		FIELDS => 3
	)
	port map (
		CLK => clk,
		RST => rst,
		CE  => '1',

		IN_R   => gen_r,
		IN_G   => gen_g,
		IN_B   => gen_b,
		IN_DE  => gen_de,
		IN_HS  => gen_hs,
		IN_VS  => gen_vs,

		FIELD_R  => fields0_r,
		FIELD_G  => fields0_g,
		FIELD_B  => fields0_b,
		FIELD_DE => fields0_de,
		FIELD_HS => fields0_hs,
		FIELD_VS => fields0_vs,

		OUT_R  => line0_r,
		OUT_G  => line0_g,
		OUT_B  => line0_b,
		OUT_DE => line0_de,
		OUT_HS => line0_hs,
		OUT_VS => line0_vs
	);

	line1 : entity work.rgb_line_buff
	generic map (
		WIDTH  => 640,
		FIELDS => 3
	)
	port map (
		CLK => clk,
		RST => rst,
		CE  => '1',

		IN_R   => line0_r,
		IN_G   => line0_g,
		IN_B   => line0_b,
		IN_DE  => line0_de,
		IN_HS  => line0_hs,
		IN_VS  => line0_vs,

		FIELD_R  => fields1_r,
		FIELD_G  => fields1_g,
		FIELD_B  => fields1_b,
		FIELD_DE => fields1_de,
		FIELD_HS => fields1_hs,
		FIELD_VS => fields1_vs,

		OUT_R  => line1_r,
		OUT_G  => line1_g,
		OUT_B  => line1_b,
		OUT_DE => line1_de,
		OUT_HS => line1_hs,
		OUT_VS => line1_vs
	);

	line2 : entity work.rgb_line_buff
	generic map (
		WIDTH  => 640,
		FIELDS => 3
	)
	port map (
		CLK => clk,
		RST => rst,
		CE  => '1',

		IN_R   => line1_r,
		IN_G   => line1_g,
		IN_B   => line1_b,
		IN_DE  => line1_de,
		IN_HS  => line1_hs,
		IN_VS  => line1_vs,

		FIELD_R  => fields2_r,
		FIELD_G  => fields2_g,
		FIELD_B  => fields2_b,
		FIELD_DE => fields2_de,
		FIELD_HS => fields2_hs,
		FIELD_VS => fields2_vs
	);

	win_0 : entity work.rgb_win
	generic map (
		WIN_SIZE => 3
	)
	port map (
		CLK => clk,
		CE  => '1',

		ROW0_R  => fields0_r,
		ROW0_G  => fields0_g,
		ROW0_B  => fields0_b,
		ROW0_DE => fields0_de,
		ROW0_HS => fields0_hs,
		ROW0_VS => fields0_vs,

		ROW1_R  => fields1_r,
		ROW1_G  => fields1_g,
		ROW1_B  => fields1_b,
		ROW1_DE => fields1_de,
		ROW1_HS => fields1_hs,
		ROW1_VS => fields1_vs,

		ROW2_R  => fields2_r,
		ROW2_G  => fields2_g,
		ROW2_B  => fields2_b,
		ROW2_DE => fields2_de,
		ROW2_HS => fields2_hs,
		ROW2_VS => fields2_vs,

		WIN_R  => win_r,
		WIN_G  => win_g,
		WIN_B  => win_b,
		WIN_DE => win_de,
		WIN_HS => win_hs,
		WIN_VS => win_vs
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
