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

	constant HBP        : integer := 48;
	constant HFP        : integer := 16;
	constant HPULSE     : integer := 96;

	constant HPIXELS    : integer := 640; -- pixels per line
	constant VLINES     : integer := 480; -- lines per frame

	constant VBP        : integer := 33; -- 33 lines
	constant VFP        : integer := 10; -- 10 lines
	constant VPULSE     : integer :=  2; --  2 lines

	constant HACTIVE    : integer := HPIXELS;
	constant VACTIVE    : integer := VLINES;

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
		RGB_EOL => open,
		RGB_EOF => open,

		RGB_VLD => rgb_vld,
		RGB_REQ => rgb_req
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

	sync_gen_i : process
		variable row : integer;

	procedure one_hsync is
		variable pix : integer;
	begin
		vga_hs <= '1';
		for pix in 1 to HBP loop
			wait until rising_edge(vga_clk);	
		end loop;

		vga_hactive <= '1';
		for pix in 1 to HACTIVE loop
			wait until rising_edge(vga_clk);	
		end loop;

		vga_hactive <= '0';
		for pix in 1 to HFP loop
			wait until rising_edge(vga_clk);	
		end loop;

		vga_hs <= '0';
		for pix in 1 to HPULSE loop
			wait until rising_edge(vga_clk);
		end loop;

		vga_hs <= '1';
	end procedure;
	begin
		vga_vs      <= '1';
		vga_vactive <= '0';
		vga_hs      <= '1';
		vga_hactive <= '0';

		if vga_rst = '1' then
			report "VSYNC Reset";
			wait until vga_rst = '0';
			wait for 6 * VGA_PERIOD;
			wait until rising_edge(vga_clk);
		end if;

		report "VBP";
		vga_vs <= '1';
		for row in 1 to VBP loop
			one_hsync;
			report "VBP after " & integer'image(row);
		end loop;

		report "VACTIVE";
		vga_vactive <= '1';
		for row in 1 to VACTIVE loop
			one_hsync;

			if row mod 48 = 0 then
				report "VACTIVE after " & integer'image(row);
			end if;
		end loop;

		report "VFP";
		vga_vactive <= '0';
		for row in 1 to VFP loop
			one_hsync;
			report "VFP after " & integer'image(row);
		end loop;

		report "VPULSE";
		vga_vs <= '0';
		for row in 1 to VPULSE loop
			one_hsync;
		end loop;

		vga_vs <= '1';
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

