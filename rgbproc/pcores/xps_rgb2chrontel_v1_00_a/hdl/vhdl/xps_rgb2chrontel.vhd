-- xps_rgb2chrontel.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity xps_rgb2chrontel is
generic (
	DEBUG       : integer := 0
);
port (
	RGB_CLK     : in  std_logic;
	RGB_RST     : in  std_logic;

	RGB_R       : in  std_logic_vector(7 downto 0);
	RGB_G       : in  std_logic_vector(7 downto 0);
	RGB_B       : in  std_logic_vector(7 downto 0);
	RGB_EOL     : in  std_logic;
	RGB_EOF     : in  std_logic;
	RGB_VLD     : in  std_logic;
	RGB_REQ     : out std_logic;

	OUT_CLK     : in  std_logic;
	OUT_RST     : in  std_logic;

	OUT_D       : out std_logic_vector(11 downto 0);
	OUT_XCLK_P  : out std_logic;
	OUT_XCLK_N  : out std_logic;
	OUT_RESET_N : out std_logic;
	OUT_DE      : out std_logic;
	OUT_HS      : out std_logic;
	OUT_VS      : out std_logic;

	DBGOUT      : out std_logic_vector(31 downto 0)
);
end entity;

architecture wrapper of xps_rgb2chrontel is

	constant DEBUG_ENABLE : boolean := DEBUG = 1;

begin

	inst_i : entity work.rgb2chrontel
	generic map (
		DEBUG   => DEBUG_ENABLE
	)
	port map (
		RGB_CLK => RGB_CLK,
		RGB_RST => RGB_RST,

		RGB_R   => RGB_R,
		RGB_G   => RGB_G,
		RGB_B   => RGB_B,
		RGB_EOL => RGB_EOL,
		RGB_EOF => RGB_EOF,
		RGB_VLD => RGB_VLD,
		RGB_REQ => RGB_REQ,

		OUT_CLK => OUT_CLK,
		OUT_RST => OUT_RST,

		OUT_D   => OUT_D,
		OUT_DE  => OUT_DE,
		OUT_HS  => OUT_HS,
		OUT_VS  => OUT_VS,
		OUT_XCLK_P  => OUT_XCLK_P,
		OUT_XCLK_N  => OUT_XCLK_N,
		OUT_RESET_N => OUT_RESET_N,

		DBGOUT  => DBGOUT
	);

end architecture;

