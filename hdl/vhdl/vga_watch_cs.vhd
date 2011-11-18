-- vga_watch_cs.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity vga_watch_cs is
port (
	VGA_CLK : in  std_logic;
	VGA_R   : in  std_logic_vector(7 downto 0);
	VGA_G   : in  std_logic_vector(7 downto 0);
	VGA_B   : in  std_logic_vector(7 downto 0);
	VGA_HS  : in  std_logic;
	VGA_VS	: in  std_logic;

	CS_CLK  : out std_logic;
	CS_VEC  : out std_logic_vector(31 downto 0)
);
end entity;

architecture full of vga_watch_cs is
begin

	CS_CLK <= VGA_CLK;

	CS_VEC(0) <= '1';

	CS_VEC(1) <= VGA_HS;
	CS_VEC(2) <= VGA_VS;

	CS_VEC(10 downto  3) <= VGA_R;
	CS_VEC(18 downto 11) <= VGA_G;
	CS_VEC(26 downto 19) <= VGA_B;

	CS_VEC(31 downto 27) <= (others => '1');

end architecture;

