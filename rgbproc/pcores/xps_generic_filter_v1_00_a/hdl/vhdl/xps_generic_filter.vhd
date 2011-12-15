-- xps_generic_filter.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.log2;

library rgb_commons_v1_00_a;
use rgb_commons_v1_00_a.line4_buff;
use rgb_commons_v1_00_a.rgb_win3x3;
use rgb_commons_v1_00_a.end_gen;

use work.generic_filter_pkg.all;

entity xps_generic_filter is
generic (
	BYPASS       : integer := 0;
	FRAME_WIDTH  : integer := 640;
	FRAME_HEIGHT : integer := 480;
	RATIO_OUT_IN : integer := 1;
	FILTER       : integer := FILTER_MEDIAN;
	M0x0         : integer := 4;
	M1x0         : integer := 3;
	M2x0         : integer := 4;
	M0x1         : integer := 3;
	M1x1         : integer := 2;
	M2x1         : integer := 3;
	M0x2         : integer := 4;
	M1x2         : integer := 3;
	M2x2         : integer := 4
);
port (
	CLK     : in  std_logic;
	RST	: in  std_logic;

	IN_CLK  : in  std_logic;
	IN_RST	: in  std_logic;

	IN_R    : in  std_logic_vector(7 downto 0);
	IN_G    : in  std_logic_vector(7 downto 0);
	IN_B    : in  std_logic_vector(7 downto 0);
	IN_EOL  : in  std_logic;
	IN_EOF  : in  std_logic;
	IN_VLD  : in  std_logic;
	IN_REQ  : out std_logic;

	OUT_CLK : in  std_logic;
	OUT_RST	: in  std_logic;

	OUT_R   : out std_logic_vector(7 downto 0);
	OUT_G   : out std_logic_vector(7 downto 0);
	OUT_B   : out std_logic_vector(7 downto 0);
	OUT_EOL : out std_logic;
	OUT_EOF : out std_logic;
	OUT_VLD : out std_logic;
	OUT_REQ : in  std_logic
);

end entity;

architecture wrapper of xps_generic_filter is

	constant BYPASS_EN : boolean := BYPASS = 1;

	signal clk0      : std_logic;
	signal clk1      : std_logic;
	signal rst0      : std_logic;
	signal rst1      : std_logic;

	signal line_r    : std_logic_vector(4 * 8 - 1 downto 0);
	signal line_g    : std_logic_vector(4 * 8 - 1 downto 0);
	signal line_b    : std_logic_vector(4 * 8 - 1 downto 0);
	signal line_mask : std_logic_vector(3 downto 0);
	signal line_mark : std_logic_vector(3 downto 0);
	signal line_addr : std_logic_vector(log2(FRAME_WIDTH) - 1 downto 0);

	signal win_r     : std_logic_vector(9 * 8 - 1 downto 0);
	signal win_g     : std_logic_vector(9 * 8 - 1 downto 0);
	signal win_b     : std_logic_vector(9 * 8 - 1 downto 0);
	signal win_vld   : std_logic;
	signal win_req   : std_logic;

	signal out_pxvld : std_logic;
	signal out_reqx  : std_logic;
	signal out_vldx  : std_logic;

begin

gen_shared_clk: if RATIO_OUT_IN = 1
generate

	clk0 <= CLK;
	clk1 <= CLK;
	rst0 <= RST;
	rst1 <= RST;

end generate;

gen_multiple_clk: if RATIO_OUT_IN > 1
generate

	clk0 <= IN_CLK;
	rst0 <= IN_RST;
	clk1 <= OUT_CLK;
	rst1 <= OUT_RST;

end generate;

	----------------------------------

	line4_buff_i : entity rgb_commons_v1_00_a.line4_buff
	generic map (
		LINE_WIDTH   => FRAME_WIDTH,
		RATIO_OUT_IN =>	RATIO_OUT_IN
	)
	port map (
		IN_CLK   => clk0,
		IN_RST   => rst0,
		IN_R     => IN_R,
		IN_G     => IN_G,
		IN_B     => IN_B,
		IN_EOL   => IN_EOL,
		IN_EOF   => IN_EOF,
		IN_VLD   => IN_VLD,
		IN_REQ   => IN_REQ,

		OUT_CLK  => clk1,
		OUT_RST  => rst1,
		OUT_R    => line_r,
		OUT_G    => line_g,
		OUT_B    => line_b,
		OUT_MASK => line_mask,
		OUT_MARK => line_mark,
		OUT_ADDR => line_addr
	);

	rgb_win3x3_i : entity rgb_commons_v1_00_a.rgb_win3x3
	generic map (
		LINE_WIDTH  => FRAME_WIDTH,
		LINES_COUNT => FRAME_HEIGHT
	)
	port map (
		CLK     => clk1,
		RST     => rst1,

		IN_R     => line_r,
		IN_G     => line_g,
		IN_B     => line_b,
		IN_MASK  => line_mask,
		IN_MARK  => line_mark,
		IN_ADDR  => line_addr,

		WIN_R    => win_r,
		WIN_G    => win_g,
		WIN_B    => win_b,
		WIN_VLD  => win_vld,
		WIN_REQ  => win_req
	);

	----------------------------------

	generic_filter_i : entity work.generic_filter
	generic map (
		BYPASS_EN => BYPASS_EN,
		FILTER    => FILTER,
		M0x0      => M0x0,
		M1x0      => M1x0,
		M2x0      => M2x0,
		M0x1      => M0x1,
		M1x1      => M1x1,
		M2x1      => M2x1,
		M0x2      => M0x2,
		M1x2      => M1x2,
		M2x2      => M2x2
	)
	port map (
		CLK     => clk1,
		RST     => rst1,

		WIN_R   => win_r,
		WIN_G   => win_g,
		WIN_B   => win_b,
		WIN_VLD => win_vld,
		WIN_REQ => win_req,

		OUT_R   => OUT_R,
		OUT_G   => OUT_G,
		OUT_B   => OUT_B,
		OUT_VLD => out_vldx,
		OUT_REQ => out_reqx,

		R_BYPASS    => open,
		R_BYPASS_IN => 'X',
		R_BYPASS_WE => '0'
	);

	end_gen_i : entity rgb_commons_v1_00_a.end_gen
	generic map (
		WIDTH  => FRAME_WIDTH,
		HEIGHT => FRAME_HEIGHT
	)
	port map (
		CLK     => clk1,
		RST     => rst1,
		PX_VLD  => out_pxvld,
		OUT_EOL => OUT_EOL,
		OUT_EOF	=> OUT_EOF
	);

	----------------------------------

	out_pxvld <= out_reqx and out_vldx;
	out_reqx  <= OUT_REQ;
	OUT_VLD   <= out_vldx;

end architecture;

