-- rgb_asfifo.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity rgb_asfifo is
port (
	ASYNC_RST     : in  std_logic;

	RGB_IN_CLK    : in  std_logic;
	RGB_IN_R      : in  std_logic_vector(7 downto 0);
	RGB_IN_G      : in  std_logic_vector(7 downto 0);
	RGB_IN_B      : in  std_logic_vector(7 downto 0);
	RGB_IN_EOL    : in  std_logic;
	RGB_IN_EOF    : in  std_logic;
	RGB_IN_WE     : in  std_logic;
	RGB_IN_FULL   : out std_logic;

	RGB_OUT_CLK   : in  std_logic;
	RGB_OUT_R     : out std_logic_vector(7 downto 0);
	RGB_OUT_G     : out std_logic_vector(7 downto 0);
	RGB_OUT_B     : out std_logic_vector(7 downto 0);
	RGB_OUT_EOL   : out std_logic;
	RGB_OUT_EOF   : out std_logic;
	RGB_OUT_RE    : in  std_logic;
	RGB_OUT_EMPTY : out std_logic
);
end entity;

architecture coregen_asfifo_rgb26 of rgb_asfifo is

	signal rgb_din  : std_logic_vector(25 downto 0);
	signal rgb_dout : std_logic_vector(25 downto 0);

	component asfifo_rgb26 IS
	port (
		rst    : in std_logic;
		wr_clk : in std_logic;
		rd_clk : in std_logic;
		din    : in std_logic_vector(25 downto 0);
		wr_en  : in std_logic;
		rd_en  : in std_logic;
		dout   : out std_logic_vector(25 downto 0);
		full   : out std_logic;
		empty  : out std_logic
	);
	end component;

begin

	impl : asfifo_rgb26
	port map (
		RST    => ASYNC_RST,

		WR_CLK => RGB_IN_CLK,
		DIN    => rgb_din,
		WR_EN  => RGB_IN_WE,
		FULL   => RGB_IN_FULL,
		
		RD_CLK => RGB_OUT_CLK,
		DOUT   => rgb_dout,
		RD_EN  => RGB_OUT_RE,
		EMPTY  => RGB_OUT_EMPTY
	);

	rgb_din(25 downto 18) <= RGB_IN_R;
	rgb_din(17 downto 10) <= RGB_IN_G;
	rgb_din( 9 downto  2) <= RGB_IN_B;
	rgb_din(1) <= RGB_IN_EOL;
	rgb_din(0) <= RGB_IN_EOF;

	RGB_OUT_R   <= rgb_dout(25 downto 18);
	RGB_OUT_G   <= rgb_dout(17 downto 10);
	RGB_OUT_B   <= rgb_dout( 9 downto  2);
	RGB_OUT_EOL <= rgb_dout(1);
	RGB_OUT_EOF <= rgb_dout(0);

end architecture;

