-- vga2rgb_tb.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity vga2rgb_tb is
end entity;

architecture testbench of vga2rgb_tb is

	-- for constants see any VGA spec
	-- from: Circuit Design and Simulation with VHDL, V. A. Pedroni [p. 428--429]

	constant BASE_MHZ   : time := 1 us;

	constant VGA_FREQ   : real := 25.175; -- pixel rate at 640x480, 60Hz
	constant VGA_PERIOD : time := BASE_MHZ / VGA_FREQ;

	constant RGB_FREQ   : real := 100.0;
	constant RGB_PERIOD : time := BASE_MHZ / RGB_FREQ;

	constant HPIXELS    : integer := 640; -- pixels per line
	constant VLINES     : integer := 480; -- lines per frame

	constant HPULSE     : time := 96 * VGA_PERIOD;
	constant VPULSE     : time :=  2 * HPIXELS * VGA_PERIOD; --  2 lines

	constant HBP        : time := 48 * VGA_PERIOD;
	constant HFP        : time := 16 * VGA_PERIOD;
	constant VBP        : time := 33 * HPIXELS * VGA_PERIOD; -- 33 lines
	constant VFP        : time := 10 * HPIXELS * VGA_PERIOD; -- 10 lines

	constant HACTIVE    : time := HPIXELS * VGA_PERIOD;
	constant VACTIVE    : time := HPIXELS * VLINES  * VGA_PERIOD;

	---------------------------------------------

	signal vga_clk     : std_logic;
	signal vga_rst     : std_logic;

	signal rgb_clk     : std_logic;
	signal rgb_rst     : std_logic;

	signal vga_r       : std_logic_vector(7 downto 0);
	signal vga_g       : std_logic_vector(7 downto 0);
	signal vga_b       : std_logic_vector(7 downto 0);

	signal vga_hs      : std_logic;
	signal vga_vs      : std_logic;

	signal vga_hactive : std_logic;
	signal vga_vactive : std_logic;
	signal vga_dena    : std_logic;

	signal rgb_vld     : std_logic;
	signal rgb_req     : std_logic;

begin

	dut_i : entity work.vga2rgb
	port map (
		VGA_CLK => vga_clk,
		VGA_R   => vga_r,
		VGA_G   => vga_g,
		VGA_B   => vga_b,
		VGA_HS  => vga_hs,
		VGA_VS  => vga_vs,

		RGB_CLK => rgb_clk,
		RGB_RST => rgb_rst,
		RGB_R   => open,
		RGB_G   => open,
		RGB_B   => open,
		RGB_HS  => open,
		RGB_VS  => open,

		RGB_VLD => rgb_vld,
		RGB_REQ => rgb_req,
		RGB_DROP => open
	);

	rgb_req <= rgb_vld;

	-----------------------------

	process(vga_clk, vga_rst, vga_dena, vga_r, vga_g, vga_b)
	begin
		if rising_edge(vga_clk) then
			if vga_rst = '1' or vga_dena = '0' then
				vga_r <= (others => '0');
				vga_g <= (others => '0');
				vga_b <= (others => '0');
			elsif vga_dena = '1' then
				vga_r <= vga_r + 1;
				vga_g <= vga_g + 1;
				vga_b <= vga_b + 1;
			end if;
		end if;
	end process;

	vga_dena <= vga_hactive and vga_vactive;

	-----------------------------

	vsync_gen_i : process
	begin
		vga_vs      <= '1';
		vga_vactive <= '0';

		if vga_rst = '1' then
			vga_vs      <= '1';
			vga_vactive <= '0';
			wait until vga_rst = '0';
			wait for 6 * VGA_PERIOD; -- no data at the beginning
		end if;

		vga_vs <= '1';
		wait for VBP;

		vga_vactive <= '1';
		wait for VACTIVE;

		vga_vactive <= '0';
		wait for VFP;

		vga_vs <= '0';
		wait for VPULSE;

		vga_vs <= '1';
	end process;

	hsync_gen_i : process
	begin
		vga_hs      <= '1';
		vga_hactive <= '0';

		if vga_rst = '1' then
			vga_hs      <= '1';
			vga_hactive <= '0';
			wait until vga_rst = '0';
			wait for 6 * VGA_PERIOD; -- no data at the beginning
		end if;

		vga_hs <= '1';
		wait for HBP;

		vga_hactive <= '1';
		wait for HACTIVE;

		vga_hactive <= '0';
		wait for HFP;

		vga_hs <= '0';
		wait for HPULSE;

		vga_hs <= '1';
	end process;

	-----------------------------

	vga_clkgen_i : process
	begin
		vga_clk <= '1';
		wait for VGA_PERIOD / 2;
		vga_clk <= '0';
		wait for VGA_PERIOD / 2;
	end process;

	vga_rstgen_i : process
	begin
		vga_rst <= '1';
		wait for 64 * VGA_PERIOD;
		vga_rst <= '0';

		wait;
	end process;

	-----------------------------

	rgb_clkgen_i : process
	begin
		rgb_clk <= '1';
		wait for RGB_PERIOD / 2;
		rgb_clk <= '0';
		wait for RGB_PERIOD / 2;
	end process;

	rgb_rstgen_i : process
	begin
		rgb_rst <= '1';
		wait for 64 * RGB_PERIOD;
		rgb_rst <= '0';

		wait;
	end process;

end architecture;

