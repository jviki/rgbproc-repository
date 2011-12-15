-- generic_filter.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

use work.generic_filter_pkg.all;

entity generic_filter is
generic (
	M0x0      : integer := 4;
	M1x0      : integer := 3;
	M2x0      : integer := 4;
	M0x1      : integer := 3;
	M1x1      : integer := 2;
	M2x1      : integer := 3;
	M0x2      : integer := 4;
	M1x2      : integer := 3;
	M2x2      : integer := 4;
	FILTER    : integer := FILTER_MEDIAN;
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

	R_BYPASS    : out std_logic;
	R_BYPASS_IN : in  std_logic;
	R_BYPASS_WE : in std_logic
);
end entity;

architecture wrapper of generic_filter is

	signal reg_bypass_ctl    : std_logic;
	signal reg_bypass_ctl_in : std_logic;
	signal reg_bypass_ctl_we : std_logic;

	signal filter_r          : std_logic_vector(7 downto 0);
	signal filter_g          : std_logic_vector(7 downto 0);
	signal filter_b          : std_logic_vector(7 downto 0);

	signal bypass_r          : std_logic_vector(7 downto 0);
	signal bypass_g          : std_logic_vector(7 downto 0);
	signal bypass_b          : std_logic_vector(7 downto 0);

begin

gen_median_filter: if FILTER = FILTER_MEDIAN
generate

	filter_i : entity work.median_filter
	generic map (
		BYPASS_EN => BYPASS_EN
	)
	port map (
		CLK     => CLK,
		RST     => RST,

		WIN_R   => WIN_R,
		WIN_G   => WIN_G,
		WIN_B   => WIN_B,
		WIN_VLD => WIN_VLD,
		WIN_REQ => WIN_REQ,

		OUT_R   => filter_r,
		OUT_G   => filter_g,
		OUT_B   => filter_b,
		OUT_VLD => OUT_VLD,
		OUT_REQ => OUT_REQ,

		BYPASS( 7 downto  0) => bypass_r,
		BYPASS(15 downto  8) => bypass_g,
		BYPASS(23 downto 16) => bypass_b
	);

end generate;

gen_shift_filter: if FILTER_MEDIAN = FILTER_SHIFT
generate

	filter_i : entity work.shift_3x3_filter
	generic map (
		M0x0      => M0x0,
		M0x1      => M0x1,
		M0x2      => M0x2,
		M1x0      => M1x0,
		M1x1      => M1x1,
		M1x2      => M1x2,
		M2x0      => M2x0,
		M2x1      => M2x1,
		M2x2      => M2x2,
		BYPASS_EN => BYPASS_EN
	)
	port map (
		CLK     => CLK,
		RST     => RST,

		WIN_R   => WIN_R,
		WIN_G   => WIN_G,
		WIN_B   => WIN_B,
		WIN_VLD => WIN_VLD,
		WIN_REQ => WIN_REQ,

		OUT_R   => filter_r,
		OUT_G   => filter_g,
		OUT_B   => filter_b,
		OUT_VLD => OUT_VLD,
		OUT_REQ => OUT_REQ,

		BYPASS( 7 downto  0) => bypass_r,
		BYPASS(15 downto  8) => bypass_g,
		BYPASS(23 downto 16) => bypass_b
	);

end generate;

	-------------------------------

	OUT_R <= filter_r when reg_bypass_ctl = '0' else
	         bypass_r;
	OUT_G <= filter_g when reg_bypass_ctl = '0' else
	         bypass_g;
	OUT_B <= filter_b when reg_bypass_ctl = '0' else
	         bypass_b;

	-------------------------------

	R_BYPASS <= reg_bypass_ctl;
	reg_bypass_ctl_in <= R_BYPASS_IN;
	reg_bypass_ctl_we <= R_BYPASS_WE;

	-------------------------------

gen_no_bypass_ctrl: if BYPASS_EN = false
generate
	reg_bypass_ctl <= '0';
end generate;

	-------------------------------

gen_bypass_ctrl: if BYPASS_EN = true
generate

	reg_bypass_ctlp : process(CLK, reg_bypass_ctl_in, reg_bypass_ctl_we)
	begin
		if rising_edge(CLK) then
			if RST = '1' then
				reg_bypass_ctl <= '1';
			elsif reg_bypass_ctl_we = '1' then
				reg_bypass_ctl <= reg_bypass_ctl_in;
			end if;
		end if;
	end process;

end generate;

end architecture;

