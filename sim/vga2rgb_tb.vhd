-- vga2rgb_tb.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity vga2rgb_tb is
end entity;

architecture testbench of vga2rgb_tb is

	constant BASE_MHZ   : time := 1 us;

	constant RGB_FREQ   : real := 100.0;
	constant RGB_PERIOD : time := BASE_MHZ / RGB_FREQ;

	---------------------------------------------

	signal vga_clk     : std_logic;

	signal rgb_clk     : std_logic;
	signal rgb_rst     : std_logic;

	signal vga_r       : std_logic_vector(7 downto 0);
	signal vga_g       : std_logic_vector(7 downto 0);
	signal vga_b       : std_logic_vector(7 downto 0);

	signal vga_hs      : std_logic;
	signal vga_vs      : std_logic;

	signal rgb_vld     : std_logic;
	signal rgb_req     : std_logic;
	signal rgb_eol     : std_logic;
	signal rgb_eof     : std_logic;

	signal cnt_rgb_req     : integer   := 0;
	signal cnt_rgb_req_ce  : std_logic := '0';
	signal cnt_rgb_req_clr : std_logic := '1';

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
		RGB_EOL => rgb_eol,
		RGB_EOF => rgb_eof,

		RGB_VLD => rgb_vld,
		RGB_REQ => rgb_req
	);

	rgb_req <= rgb_vld;

	assert (rising_edge(rgb_clk) 
	   and ((rgb_req = '1' and rgb_vld = '1') or rgb_req = '0'))
	    or not rising_edge(rgb_clk)
		report "Requesting invalid data"
		severity error;
		
	-----------------------------

	cnt_rgb_reqp : process(rgb_clk, rgb_req, rgb_eol)
	begin
		if rising_edge(rgb_clk) then
			if cnt_rgb_req_clr = '1' then
				cnt_rgb_req <= 0;
			elsif cnt_rgb_req_ce = '1' then
				cnt_rgb_req <= cnt_rgb_req + 1;
			end if;
		end if;
	end process;

	cnt_rgb_req_ce  <= rgb_req;
	cnt_rgb_req_clr <= rgb_eol;

	process(rgb_clk)
	begin
		if rising_edge(rgb_clk) then
			if cnt_rgb_req_clr = '1' then
				-- detecting invalid data count
				assert cnt_rgb_req = 639 or cnt_rgb_req = 0
					report "Invalid count of data has been received: "
					     & integer'image(cnt_rgb_req'last_value) & ".." & integer'image(cnt_rgb_req)
					severity error;
			end if;
		end if;
	end process;

	-----------------------------

	vga_gen_i : entity work.vga_gen(simple)
	port map (
		R  => vga_r,
		G  => vga_g,
		B  => vga_b,
		HS  => vga_hs,
		VS  => vga_vs,
		CLK  => vga_clk
	);

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

