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
	RGB_R   : in  std_logic_vector(7 downto 0);
	RGB_G   : in  std_logic_vector(7 downto 0);
	RGB_B   : in  std_logic_vector(7 downto 0);
	RGB_EOL : in  std_logic;
	RGB_EOF : in  std_logic;
	RGB_VLD : in  std_logic;
	RGB_REQ : in  std_logic;

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
		RGB_R   => RGB_R,
		RGB_G   => RGB_G,
		RGB_B   => RGB_B,
		RGB_EOL => RGB_EOL,
		RGB_EOF => RGB_EOF,
		RGB_VLD => RGB_VLD,
		RGB_REQ => RGB_REQ,

		CS_CLK  => CS_CLK,
		CS_VEC  => CS_VEC
	);

end architecture;

