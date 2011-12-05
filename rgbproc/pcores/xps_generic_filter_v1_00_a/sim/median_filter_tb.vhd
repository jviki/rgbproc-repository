-- median_filter_tb.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

use std.textio.all;
use ieee.std_logic_textio.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.log2;

library rgb_commons_v1_00_a;
use rgb_commons_v1_00_a.line4_buff;
use rgb_commons_v1_00_a.rgb_win3x3;

entity median_filter_tb is
end entity;

architecture testbench of median_filter_tb is

	component filter_3x3 is
	generic (
		BYPASS_EN : boolean := true
	);
	port (
		CLK     : in  std_logic;
		RST	: in  std_logic;

		WIN_R   : in  std_logic_vector(9 * 8 - 1 downto 0);
		WIN_G   : in  std_logic_vector(9 * 8 - 1 downto 0);
		WIN_B   : in  std_logic_vector(9 * 8 - 1 downto 0);
		WIN_VLD : in  std_logic;
		WIN_REQ : out std_logic;

		OUT_R   : out std_logic_vector(7 downto 0);
		OUT_G   : out std_logic_vector(7 downto 0);
		OUT_B   : out std_logic_vector(7 downto 0);
		OUT_VLD : out std_logic;
		OUT_REQ : in  std_logic;

		BYPASS  : out std_logic_vector(23 downto 0)
	);
	end component;

--	for dut_i : filter_3x3
--		use entity work.shift_3x3_filter;
	for dut_i : filter_3x3
		use entity work.median_filter;

	constant LINE_WIDTH   : integer := 640;
	constant LINES_COUNT  : integer := 480;
	constant RATIO_OUT_IN : integer := 2;

	constant FREQ       : real := 100.0;
	constant PERIOD     : time := 1 us / FREQ;

	signal clk          : std_logic;
	signal rst          : std_logic;

	signal in_r         : std_logic_vector(7 downto 0);
	signal in_g         : std_logic_vector(7 downto 0);
	signal in_b         : std_logic_vector(7 downto 0);
	signal in_vld       : std_logic;
	signal in_req       : std_logic;
	signal in_eol       : std_logic;

	signal buf_r         : std_logic_vector(31 downto 0);
	signal buf_g         : std_logic_vector(31 downto 0);
	signal buf_b         : std_logic_vector(31 downto 0);
	signal buf_mark     : std_logic_vector(3 downto 0);
	signal buf_mask     : std_logic_vector(3 downto 0);
	signal buf_addr     : std_logic_vector(log2(LINE_WIDTH) - 1 downto 0);

	signal win_r        : std_logic_vector(71 downto 0);
	signal win_g        : std_logic_vector(71 downto 0);
	signal win_b        : std_logic_vector(71 downto 0);
	signal win_vld      : std_logic;
	signal win_req      : std_logic;

	signal out_r        : std_logic_vector(7 downto 0);
	signal out_g        : std_logic_vector(7 downto 0);
	signal out_b        : std_logic_vector(7 downto 0);
	signal out_vld      : std_logic;
	signal out_req      : std_logic;

	file input_file     : TEXT open READ_MODE  is "input_file.txt";
	file output_file    : TEXT open WRITE_MODE is "output_file.txt";

begin

	line_buff_i : entity rgb_commons_v1_00_a.line4_buff
	generic map (
		LINE_WIDTH   => LINE_WIDTH,
		RATIO_OUT_IN => RATIO_OUT_IN
	)
	port map (
		IN_CLK     => clk,
		IN_RST     => rst,

		IN_R       => in_r,
		IN_G       => in_g,
		IN_B       => in_b,
		IN_EOL     => in_eol,
		IN_EOF     => '0',
		IN_VLD     => in_vld,
		IN_REQ     => in_req,

		OUT_CLK    => clk,
		OUT_RST    => rst,
		OUT_R      => buf_r,
		OUT_G      => buf_g,
		OUT_B      => buf_b,
		OUT_MASK   => buf_mask,
		OUT_MARK   => buf_mark,
		OUT_ADDR   => buf_addr
	);

	---------------------------

	win_i : entity rgb_commons_v1_00_a.rgb_win3x3
	generic map (
		LINE_WIDTH  => LINE_WIDTH,
		LINES_COUNT => LINES_COUNT		
	)
	port map (
		CLK     => clk,
		RST     => rst,
		IN_R    => buf_r,
		IN_G    => buf_g,
		IN_B    => buf_b,
		IN_MASK => buf_mask,
		IN_MARK => buf_mark,
		IN_ADDR => buf_addr,

		WIN_R   => win_r,
		WIN_G   => win_g,
		WIN_B   => win_b,
		WIN_VLD => win_vld,
		WIN_REQ => win_req
	);

	dut_i : filter_3x3
	generic map (
		BYPASS_EN => true
	)
	port map (
		CLK     => clk,
		RST     => rst,

		WIN_R   => win_r,
		WIN_G   => win_g,
		WIN_B   => win_b,
		WIN_VLD => win_vld,
		WIN_REQ => win_req,

		OUT_R   => out_r,
		OUT_G   => out_g,
		OUT_B   => out_b,
		OUT_VLD => out_vld,
		OUT_REQ => out_req,

		BYPASS  => open
	);

	---------------------------

	gen_rgb_data : process
		variable l : line;
		variable r : integer;
		variable g : integer;
		variable b : integer;
		variable i : integer;

		procedure read_next is
		begin
			if not endfile(input_file) then
				readline(input_file, l);
				read(l, r);
				read(l, g);
				read(l, b);

				in_r <= conv_std_logic_vector(r, in_r'length);
				in_g <= conv_std_logic_vector(g, in_g'length);
				in_b <= conv_std_logic_vector(b, in_b'length);
			end if;
		end procedure;
	begin
		in_vld <= '0';
		in_eol <= '0';

		wait until rst = '0';
		wait until rising_edge(clk);

		i := 0;

		while not endfile(input_file) loop
			read_next;

			if (i + 1) mod LINE_WIDTH = 0 then
				report "End of Line";
				in_eol <= '1';
			end if;

			in_vld <= '1';
			wait until rising_edge(clk);

			while in_req = '0' loop
				wait until rising_edge(clk);
			end loop;

			in_vld <= '0';
			in_eol <= '0';
			i := i + 1;
		end loop;

		in_vld <= '0';
		report "End of File";
		wait until rising_edge(clk);

		wait;
	end process;

	---------------------------

	out_req <= out_vld;

	data_to_file : process(clk, rst, out_vld, out_req, out_r, out_g, out_b)
		variable l  : line;
		variable i  : integer := 0;
	begin
		if rising_edge(clk) then
			if out_vld = '1' and out_req = '1' and rst = '0' then
				--hwrite(l, px);
				write(l, conv_integer(out_r));
				write(l, string'(" "));
				write(l, conv_integer(out_g));
				write(l, string'(" "));
				write(l, conv_integer(out_b));
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

	clkgen_i : process
	begin
		clk <= '0';
		wait for PERIOD / 2;
		clk <= '1';
		wait for PERIOD / 2;
	end process;

	rstgen_i : process
	begin
		rst <= '1';
		wait for 32 * PERIOD;
		rst <= '0';
		wait;
	end process;

end architecture;

