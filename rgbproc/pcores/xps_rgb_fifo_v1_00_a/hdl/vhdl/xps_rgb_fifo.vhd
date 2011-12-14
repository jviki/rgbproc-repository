-- xps_rgb_fifo.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity xps_rgb_fifo is
generic (
	DEPTH : integer := 2 * 640 * 480;
	DEBUG : integer := 0
);
port (
	CLK     : in  std_logic;
	RST     : in  std_logic;
	
	IN_R    : in  std_logic_vector(7 downto 0);
	IN_G    : in  std_logic_vector(7 downto 0);
	IN_B    : in  std_logic_vector(7 downto 0);
	IN_EOL  : in  std_logic;
	IN_EOF  : in  std_logic;
	IN_VLD  : in  std_logic;
	IN_REQ  : out std_logic;

	OUT_R   : out std_logic_vector(7 downto 0);
	OUT_G   : out std_logic_vector(7 downto 0);
	OUT_B   : out std_logic_vector(7 downto 0);
	OUT_EOL : out std_logic;
	OUT_EOF : out std_logic;
	OUT_VLD : out std_logic;
	OUT_REQ : in  std_logic;

	DBGOUT  : out std_logic_vector(63 downto 0)
);
end entity;

architecture wrapper of xps_rgb_fifo is

	constant DEBUG_EN : boolean := DEBUG = 1;

begin

	impl_i : entity work.rgb_fifo
	generic map (
		DEPTH => DEPTH,
		DEBUG => DEBUG_EN
	)
	port map (
		CLK     => CLK,
		RST     => RST,

		IN_R    => IN_R,
		IN_G    => IN_G,
		IN_B    => IN_B,
		IN_EOL  => IN_EOL,
		IN_EOF  => IN_EOF,
		IN_VLD  => IN_VLD,
		IN_REQ  => IN_REQ,

		OUT_R   => OUT_R,
		OUT_G   => OUT_G,
		OUT_B   => OUT_B,
		OUT_EOL => OUT_EOL,
		OUT_EOF => OUT_EOF,
		OUT_VLD => OUT_VLD,
		OUT_REQ => OUT_REQ,

		DBGOUT  => DBGOUT
	);

end architecture;

