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

architecture full of rgb2chrontel is

	signal out_eol_valid : std_logic;
	signal out_eof_valid : std_logic;
	signal out_vld       : std_logic;
	signal out_req       : std_logic;

begin

	hsync_gen_i : entity work.sync_gen
	generic map (
		SYNC_LEN => 64
	)
	port map (
		CLK    => OUT_CLK,
		RST    => OUT_RST,
		LAST   => out_eol_valid,
		SYNC_N => OUT_HS
	);

	vsync_gen_i : entity work.sync_gen
	generic map (
		SYNC_LEN => 480 -- XXX: is this right???
	)
	port map (
		CLK    => OUT_CLK,
		RST    => OUT_RST,
		LAST   => out_eof_valid,
		SYNC_N => OUT_VS
	);

	DE <= out_vld and out_req;

end architecture;

