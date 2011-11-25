-- rgb_fifo.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity rgb_fifo is
port (
	CLK           : in  std_logic;
	ASYNC_RST     : in  std_logic;

	RGB_IN_RED    : in  std_logic_vector(7 downto 0);
	RGB_IN_GREEN  : in  std_logic_vector(7 downto 0);
	RGB_IN_BLUE   : in  std_logic_vector(7 downto 0);
	RGB_IN_HSYNC  : in  std_logic;
	RGB_IN_VSYNC  : in  std_logic;
	RGB_IN_WE     : in  std_logic;
	RGB_IN_FULL   : out std_logic;

	RGB_OUT_RED   : out std_logic_vector(7 downto 0);
	RGB_OUT_GREEN : out std_logic_vector(7 downto 0);
	RGB_OUT_BLUE  : out std_logic_vector(7 downto 0);
	RGB_OUT_HSYNC : out std_logic;
	RGB_OUT_VSYNC : out std_logic;
	RGB_OUT_RE    : in  std_logic;
	RGB_OUT_EMPTY : out std_logic
);
end entity;

architecture coregen_fifo_rgb26 of rgb_fifo is

	signal rgb_din  : std_logic_vector(25 downto 0);
	signal rgb_dout : std_logic_vector(25 downto 0);

begin

	impl : entity work.fifo_rgb26
	port map (
		CLK    => CLK,
		RST    => ASYNC_RST,

		DIN    => rgb_din,
		WR_EN  => RGB_IN_WE,
		FULL   => RGB_IN_FULL,
		
		DOUT   => rgb_dout,
		RD_EN  => RGB_OUT_RE,
		EMPTY  => RGB_OUT_EMPTY
	);

	rgb_din(25 downto 18) <= RGB_IN_RED;
	rgb_din(17 downto 10) <= RGB_IN_GREEN;
	rgb_din( 9 downto  2) <= RGB_IN_BLUE;
	rgb_din(1) <= RGB_IN_HSYNC;
	rgb_din(0) <= RGB_IN_VSYNC;

	RGB_OUT_RED   <= rgb_dout(25 downto 18);
	RGB_OUT_GREEN <= rgb_dout(17 downto 10);
	RGB_OUT_BLUE  <= rgb_dout( 9 downto  2);
	RGB_OUT_HSYNC <= rgb_dout(1);
	RGB_OUT_VSYNC <= rgb_dout(0);

end architecture;

