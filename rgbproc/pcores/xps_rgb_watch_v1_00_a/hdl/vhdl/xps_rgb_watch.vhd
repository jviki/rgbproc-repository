-- xps_rgb_watch.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity xps_rgb_watch is
port (
	RGB_CLK : in  std_logic;
	RGB_RST : in  std_logic;

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

	CS_CLK  : out std_logic;
	CS_VEC  : out std_logic_vector(47 downto 0)
);
end entity;

architecture wrapper of xps_rgb_watch is
begin
	
	impl_i : entity work.rgb_watch_cs
	port map (
		RGB_CLK => RGB_CLK,
		RGB_RST => RGB_RST,
		RGB_R   => IN_R,
		RGB_G   => IN_G,
		RGB_B   => IN_B,
		RGB_EOL => IN_EOL,
		RGB_EOF => IN_EOF,
		RGB_VLD => IN_VLD,
		RGB_REQ => OUT_REQ,

		CS_CLK  => CS_CLK,
		CS_VEC  => CS_VEC
	);

	OUT_R   <= IN_R;
	OUT_G   <= IN_G;
	OUT_B   <= IN_B;

	OUT_EOL <= IN_EOL;
	OUT_EOF <= IN_EOF;

	OUT_REQ	<= IN_REQ;
	IN_VLD  <= OUT_VLD;

end architecture;

