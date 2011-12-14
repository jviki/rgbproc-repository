-- xps_vga2rgb.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity xps_vga2rgb is
generic (
	DEBUG    : integer := 0
);
port (
	VGA_CLK  : in  std_logic;
	VGA_R    : in  std_logic_vector(7 downto 0);
	VGA_G    : in  std_logic_vector(7 downto 0);
	VGA_B    : in  std_logic_vector(7 downto 0);
	VGA_HS   : in  std_logic;
	VGA_VS   : in  std_logic;
	VGA_CLAMP      : out std_logic;
	VGA_COAST      : out std_logic;
	VGA_ODD_EVEN_B : in  std_logic;
	VGA_SOGOUT     : in  std_logic;

	RGB_CLK  : in  std_logic;
	RGB_RST  : in  std_logic;
	RGB_R    : out std_logic_vector(7 downto 0);
	RGB_G    : out std_logic_vector(7 downto 0);
	RGB_B    : out std_logic_vector(7 downto 0);
	RGB_EOL  : out std_logic;
	RGB_EOF  : out std_logic;

	RGB_VLD  : out std_logic;
	RGB_REQ  : in  std_logic;

	DBGOUT   : out std_logic_vector(95 downto 0)
);
end entity;

architecture wrapper of xps_vga2rgb is

	constant DEBUG_EN : boolean := DEBUG = 1;

	signal reg_latch : std_logic_vector(25 downto 0);

begin

	VGA_CLAMP <= '0';
	VGA_COAST <= '0';

	---
	-- Register to break the critical path.
	---
	reg_latchp : process(VGA_CLK, VGA_R, VGA_G, VGA_B, VGA_HS, VGA_VS)
	begin
		if rising_edge(VGA_CLK) then
			reg_latch(0) <= VGA_HS;
			reg_latch(1) <= VGA_VS;

			reg_latch( 9 downto  2) <= VGA_R;
			reg_latch(17 downto 10) <= VGA_G;
			reg_latch(25 downto 18) <= VGA_B;
		end if;
	end process;

	impl_i : entity work.vga2rgb
	generic map (
		DEBUG   => DEBUG_EN
	)
	port map (
		VGA_CLK => VGA_CLK,
		VGA_R   => reg_latch( 9 downto  2),
		VGA_G   => reg_latch(17 downto 10),
		VGA_B   => reg_latch(25 downto 18),
		VGA_HS  => reg_latch(0),
		VGA_VS  => reg_latch(1),

		RGB_CLK => RGB_CLK,
		RGB_RST => RGB_RST,
		RGB_R   => RGB_R,
		RGB_G   => RGB_G,
		RGB_B   => RGB_B,
		RGB_EOL => RGB_EOL,
		RGB_EOF => RGB_EOF,

		RGB_VLD => RGB_VLD,
		RGB_REQ => RGB_REQ,

		DBGOUT  => DBGOUT
	);

end architecture;

