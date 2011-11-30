-- xps_vga_watch.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity xps_vga_watch is
generic (
	CS_XVEC_ENABLE : boolean := false
);
port (
	VGA_CLK : in  std_logic;
	VGA_R   : in  std_logic_vector(7 downto 0);
	VGA_G   : in  std_logic_vector(7 downto 0);
	VGA_B   : in  std_logic_vector(7 downto 0);
	VGA_HS  : in  std_logic;
	VGA_VS	: in  std_logic;
	VGA_SOGOUT     : in std_logic;
	VGA_ODD_EVEN_B : in std_logic;

	CS_CLK  : out std_logic;
	CS_VEC  : out std_logic_vector(31 downto 0);
	CS_XVEC : out std_logic_vector(31 + 4 + (3 * 16) downto 0)
);
end entity;

architecture wrapper of xps_vga_watch is
begin

	impl_i : entity worrk.vga_watch_cs
	generic map (
		CS_XVEC_ENABLE => CS_XVEC_ENABLE
	)
	port map (
		VGA_CLK => VGA_CLK,
		VGA_R   => VGA_R,
		VGA_G   => VGA_G,
		VGA_B   => VGA_B,
		VGA_HS  => VGA_HS,
		VGA_VS  => VGA_VS,
		VGA_SOGOUT => VGA_SOGOUT,
		VGA_ODD_EVEN_B => VGA_ODD_EVEN_B,

		CS_CLK  => CS_CLK,
		CS_VEC  => CS_VEC,
		CS_XVEC => CS_XVEC
	);

end architecture;

