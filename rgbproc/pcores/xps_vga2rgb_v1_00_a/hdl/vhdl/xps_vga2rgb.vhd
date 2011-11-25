-- xps_vga2rgb.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity xps_vga2rgb is
port (
	VGA_CLK  : in  std_logic;
	VGA_R    : in  std_logic_vector(7 downto 0);
	VGA_G    : in  std_logic_vector(7 downto 0);
	VGA_B    : in  std_logic_vector(7 downto 0);
	VGA_HS   : in  std_logic;
	VGA_VS   : in  std_logic;

	RGB_CLK  : in  std_logic;
	RGB_RST  : in  std_logic;
	RGB_R    : out std_logic_vector(7 downto 0);
	RGB_G    : out std_logic_vector(7 downto 0);
	RGB_B    : out std_logic_vector(7 downto 0);
	RGB_EOL  : out std_logic;
	RGB_EOF  : out std_logic;

	RGB_VLD  : out std_logic;
	RGB_REQ  : in  std_logic
);
end entity;

architecture wrapper of xps_vga2rgb is
begin

	impl_i : entity work.vga2rgb
	port map (
		VGA_CLK => VGA_CLK,
		VGA_R   => VGA_R,
		VGA_G   => VGA_G,
		VGA_B   => VGA_B,
		VGA_HS  => VGA_HS,
		VGA_VS  => VGA_VS,

		RGB_CLK => RGB_CLK,
		RGB_RST => RGB_RST,
		RGB_R   => RGB_R,
		RGB_G   => RGB_G,
		RGB_B   => RGB_B,
		RGB_EOL => RGB_EOL,
		RGB_EOF => RGB_EOF,

		RGB_VLD => RGB_VLD,
		RGB_REQ => RGB_REQ
	);

end architecture;
