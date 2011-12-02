-- rgb_win3x3_tb.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

use std.textio.all;
use ieee.std_logic_textio.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.log2;

entity rgb_win3x3_tb is
end entity;

architecture testbench of rgb_win3x3_tb is

	constant LINE_WIDTH   : integer := 640;
	constant LINES_COUNT  : integer := 480;
	constant RATIO_OUT_IN : integer := 2;

	constant IN_FREQ    : real := 50.0;
	constant IN_PERIOD  : time := 1 us / IN_FREQ;

	constant OUT_FREQ   : real := IN_FREQ * real(RATIO_OUT_IN);
	constant OUT_PERIOD : time := 1 us / OUT_FREQ;

	signal in_clk       : std_logic;
	signal in_rst       : std_logic;

	signal out_clk      : std_logic;
	signal out_rst      : std_logic;

	signal in_r         : std_logic_vector(7 downto 0);
	signal in_g         : std_logic_vector(7 downto 0);
	signal in_b         : std_logic_vector(7 downto 0);
	signal in_vld       : std_logic;
	signal in_req       : std_logic;
	signal in_eol       : std_logic;

	signal win_vld      : std_logic;
	signal win_req      : std_logic;

	signal win_r        : std_logic_vector(71 downto 0);

	signal out_r        : std_logic_vector(31 downto 0);
	signal out_g        : std_logic_vector(31 downto 0);
	signal out_b        : std_logic_vector(31 downto 0);
	signal out_mark     : std_logic_vector(3 downto 0);
	signal out_mask     : std_logic_vector(3 downto 0);
	signal out_addr     : std_logic_vector(log2(LINE_WIDTH) - 1 downto 0);

	file input_file     : TEXT open READ_MODE  is "input_file.txt";
	file output_file    : TEXT open WRITE_MODE is "output_file.txt";

begin

	line_buff_i : entity work.line4_buff
	generic map (
		LINE_WIDTH   => LINE_WIDTH,
		RATIO_OUT_IN => RATIO_OUT_IN
	)
	port map (
		IN_CLK     => in_clk,
		IN_RST     => in_rst,

		IN_R       => in_r,
		IN_G       => in_g,
		IN_B       => in_b,
		IN_EOL     => in_eol,
		IN_EOF     => '0',
		IN_VLD     => in_vld,
		IN_REQ     => in_req,

		OUT_CLK    => out_clk,
		OUT_RST    => out_rst,
		OUT_R      => out_r,
		OUT_G      => out_g,
		OUT_B      => out_b,
		OUT_MASK   => out_mask,
		OUT_MARK   => out_mark,
		OUT_ADDR   => out_addr
	);

	---------------------------

	dut_i : entity work.rgb_win3x3
	generic map (
		LINE_WIDTH  => LINE_WIDTH,
		LINES_COUNT => LINES_COUNT		
	)
	port map (
		CLK     => out_clk,
		RST     => out_rst,
		IN_R    => out_r,
		IN_G    => out_g,
		IN_B    => out_b,
		IN_MASK => out_mask,
		IN_MARK => out_mark,
		IN_ADDR => out_addr,

		WIN_R   => win_r,
		WIN_G   => open,
		WIN_B   => open,
		WIN_VLD => win_vld,
		WIN_REQ => win_req
	);

	---------------------------

	gen_rgb_data : process(in_clk, in_req, in_vld)
		variable l : line;
		variable c : std_logic_vector(7 downto 0) := (others => 'X');
		variable v : integer;
		variable i : integer;
		variable first : boolean := false;

		procedure read_next is
		begin
			if not endfile(input_file) then
				readline(input_file, l);
				read(l, v);
				c := conv_std_logic_vector(v, c'length);
				in_r <= c;
				in_g <= c;
				in_b <= c;
			end if;
		end procedure;
	begin
		if rising_edge(in_clk) then
			if in_rst = '1' then
				i := 0;
				in_vld <= '0';
				in_eol <= '0';
			elsif in_req = '1' and in_vld = '1' then
				read_next;
				i := i + 1;

				if i mod LINE_WIDTH = LINE_WIDTH - 1 then
					in_eol <= '1';
				end if;
			else
				in_eol <= '0';
			end if;

			if endfile(input_file) then
				in_vld <= '0';
			elsif in_rst = '0' then
				if not first then
					read_next;
					first := true;
				end if;
				in_vld <= '1';
			end if;
		end if;
	end process;

	---------------------------

	win_req <= win_vld;

	data_to_file : process(out_clk, out_rst, win_vld, win_req, win_r)
		variable l  : line;
		variable px : std_logic_vector(7 downto 0);
		variable i  : integer := 0;
	begin
		if rising_edge(out_clk) then
			if win_vld = '1' and win_req = '1' and out_rst = '0' then
				px := win_r(39 downto 32);

				--hwrite(l, px);
				write(l, conv_integer(px));
				writeline(output_file, l);

				i := i + 1;
				--if i = LINE_WIDTH then
					--write(l, string'("-- end frame"));
					--writeline(output_file, l);
				--end if;
			end if;
		end if;
	end process;

	---------------------------

	out_clkgen_i : process
	begin
		out_clk <= '0';
		wait for OUT_PERIOD / 2;
		out_clk <= '1';
		wait for OUT_PERIOD / 2;
	end process;

	out_rstgen_i : process
	begin
		out_rst <= '1';
		wait for 32 * OUT_PERIOD;
		out_rst <= '0';
		wait;
	end process;

	in_clkgen_i : process
	begin
		in_clk <= '0';
		wait for IN_PERIOD / 2;
		in_clk <= '1';
		wait for IN_PERIOD / 2;
	end process;

	in_rstgen_i : process
	begin
		in_rst <= '1';
		wait for 32 * IN_PERIOD;
		in_rst <= '0';
		wait;
	end process;

end architecture;

