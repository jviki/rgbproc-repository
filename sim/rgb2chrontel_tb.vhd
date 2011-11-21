-- rgb2chrontel_tb.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.log2;

entity rgb2chrontel_tb is
end entity;

architecture testbench of rgb2chrontel_tb is

	constant HPIXELS    : integer := 640;
	constant VLINES     : integer := 480;

	constant BASE_MHZ   : time := 1 us;

	constant RGB_FREQ   : real := 100.0;
	constant RGB_PERIOD : time := BASE_MHZ / RGB_FREQ;

	constant OUT_FREQ   : real := 25.0;
	constant OUT_PERIOD : time := BASE_MHZ / OUT_FREQ;
	
	signal rgb_clk  : std_logic;
	signal rgb_rst  : std_logic;
	signal out_clk  : std_logic;
	signal out_rst  : std_logic;

	signal rgb_r    : std_logic_vector(7 downto 0);
	signal rgb_g    : std_logic_vector(7 downto 0);
	signal rgb_b    : std_logic_vector(7 downto 0);

	signal rgb_counter_val : std_logic_vector(log2(HPIXELS * VLINES + 2) - 1 downto 0);
	signal rgb_counter_ce  : std_logic;

	signal rgb_eol  : std_logic;
	signal rgb_eof  : std_logic;
	signal rgb_vld  : std_logic;
	signal rgb_req  : std_logic;

	signal out_xclk_p : std_logic;
	signal out_xclk_n : std_logic;

	signal out_de   : std_logic;
	signal out_hs   : std_logic;
	signal out_vs   : std_logic;

	signal cnt_out_vs_ce  : std_logic := '0';
	signal cnt_out_vs_clr : std_logic := '1';
	signal cnt_out_vs     : integer   := 0;

	signal cnt_out_hs_ce  : std_logic := '0';
	signal cnt_out_hs_clr : std_logic := '1';
	signal cnt_out_hs     : integer   := 0;

begin

	dut_i : entity work.rgb2chrontel
	port map (
		RGB_CLK => rgb_clk,
		RGB_RST	=> rgb_rst,

		RGB_R   => rgb_r,
		RGB_G   => rgb_g,
		RGB_B   => rgb_b,
		RGB_EOL => rgb_eol,
		RGB_EOF => rgb_eof,
		RGB_VLD => rgb_vld,
		RGB_REQ => rgb_req,

		OUT_CLK => out_clk,
		OUT_RST => out_rst,

		OUT_D       => open,
		OUT_XCLK_P  => out_xclk_p,
		OUT_XCLK_N  => out_xclk_n,
		OUT_RESET_N => open,
		OUT_DE      => out_de,
		OUT_HS      => out_hs,
		OUT_VS      => out_vs
	);

	--------------------------------

	cnt_out_hsp : process(out_xclk_n, cnt_out_hs_ce, cnt_out_hs_clr)
	begin
		if rising_edge(out_xclk_n) then
			if cnt_out_hs_clr = '1' then
				cnt_out_hs <= 0;
			elsif cnt_out_hs_ce = '1' then
				cnt_out_hs <= cnt_out_hs + 1;
			end if;
		end if;
	end process;

	-- not clear what this assertion should check
	assert (cnt_out_hs = 0 and   cnt_out_hs_clr = '1')
	    or (cnt_out_hs >= 64 and cnt_out_hs_clr = '1')
	    or (cnt_out_hs <= 64 and cnt_out_hs_ce  = '1')
		report "Invalid out_hs timing: " & integer'image(cnt_out_hs)
		severity error;

	cnt_out_hs_ce  <= not out_hs;
	cnt_out_hs_clr <= out_hs;

	---------------

	cnt_out_vsp : process(out_xclk_n, cnt_out_vs_ce, cnt_out_vs_clr)
	begin
		if rising_edge(out_xclk_n) then
			if cnt_out_vs_clr = '1' then
				cnt_out_vs <= 0;
			elsif cnt_out_vs_ce = '1' then
				cnt_out_vs <= cnt_out_vs + 1;
			end if;
		end if;
	end process;

	-- not clear what this assertion should check
	assert (cnt_out_vs = 0    and cnt_out_vs_clr = '1')
	    or (cnt_out_vs >= 640 and cnt_out_vs_clr = '1')
	    or (cnt_out_vs <= 640 and cnt_out_vs_ce  = '1')
		report "Invalid out_vs timing: " & integer'image(cnt_out_vs)
		severity error;

	cnt_out_vs_ce  <= not out_vs;
	cnt_out_vs_clr <= out_vs;

	--------------------------------

	rgb_counter : process(rgb_clk, rgb_counter_ce, rgb_counter_val, rgb_r, rgb_g, rgb_b)
	begin
		if rising_edge(rgb_clk) then
			if rgb_rst = '1' then
				rgb_counter_val <= (0 => '1', others => '0');
				rgb_r <= X"00";
				rgb_g <= X"00";
				rgb_b <= X"00";
			elsif rgb_counter_ce = '1' then
				rgb_counter_val <= rgb_counter_val + 1;
				rgb_r <= rgb_r + 1;
				rgb_g <= rgb_g + 1;
				rgb_b <= rgb_b + 1;
			end if;
		end if;
	end process;

	rgb_counter_ce <= rgb_req and rgb_vld;
	rgb_vld <= '1';

	rgb_eol <= '1' when conv_integer(rgb_counter_val + 1) mod HPIXELS = 0    else '0';
	rgb_eof <= '1' when conv_integer(rgb_counter_val + 1) = HPIXELS * VLINES else '0';

	--------------------------------
	
	out_clkgen_i : process
	begin
		out_clk <= '1';
		wait for OUT_PERIOD / 2;
		out_clk <= '0';
		wait for OUT_PERIOD / 2;
	end process;

	out_rstgen_i : process
	begin
		out_rst <= '1';
		wait for 8 * OUT_PERIOD;
		out_rst <= '0';

		wait;
	end process;

	--------------------------------
	
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

