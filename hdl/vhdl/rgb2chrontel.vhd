-- rgb2chrontel.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;

entity rgb2chrontel is
port (
	RGB_CLK     : in  std_logic;
	RGB_RST     : in  std_logic;

	RGB_R       : in  std_logic_vector(7 downto 0);
	RGB_G       : in  std_logic_vector(7 downto 0);
	RGB_B       : in  std_logic_vector(7 downto 0);
	RGB_SOL     : in  std_logic;
	RGB_EOL     : in  std_logic;
	RGB_SOF     : in  std_logic;
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
	OUT_VS      : out std_logic
);
end entity;

