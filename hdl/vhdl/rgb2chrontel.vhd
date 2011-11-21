-- rgb2chrontel.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library rgb_commons_v1_00_a;
use rgb_commons_v1_00_a.rgb_asfifo;

entity rgb2chrontel is
generic (
	DEBUG       : boolean := false
);
port (
	RGB_CLK     : in  std_logic;
	RGB_RST     : in  std_logic;

	RGB_R       : in  std_logic_vector(7 downto 0);
	RGB_G       : in  std_logic_vector(7 downto 0);
	RGB_B       : in  std_logic_vector(7 downto 0);
	RGB_EOL     : in  std_logic;
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
	OUT_VS      : out std_logic;

	DBGOUT      : out std_logic_vector(31 downto 0)
);
end entity;

architecture full of rgb2chrontel is

	signal out_eol_valid : std_logic;
	signal out_eof_valid : std_logic;

	signal out_r         : std_logic_vector(7 downto 0);
	signal out_g         : std_logic_vector(7 downto 0);
	signal out_b         : std_logic_vector(7 downto 0);
	signal out_eol       : std_logic;
	signal out_eof       : std_logic;

	signal out_data0     : std_logic_vector(11 downto 0);
	signal out_data1     : std_logic_vector(11 downto 0);
	signal out_data_en   : std_logic;

	signal hsync         : std_logic;
	signal vsync         : std_logic;

	signal fifo_we       : std_logic;
	signal fifo_full     : std_logic;
	signal fifo_re       : std_logic;
	signal fifo_empty    : std_logic;

	type state_t is (s_idle, s_pass, s_eol, s_eof);
	signal state         : state_t;
	signal nstate        : state_t;

	signal hsync_dbgout  : std_logic_vector(5 downto 0);
	signal vsync_dbgout  : std_logic_vector(5 downto 0);

begin

	idf0_i : entity work.idf_encoding(idf0)
	port map (
		RED   => out_r,
		GREEN => out_g,
		BLUE  => out_b,
		D0    => out_data0,
		D1    => out_data1
	);

	ddr_i : entity work.data_out(ddr)
	port map (
		CLK   => OUT_CLK,
		RST   => OUT_RST,

		D0    => out_data0,
		D1    => out_data1,
		DE    => out_data_en,
		HS    => hsync,
		VS    => vsync,

		OUT_XCLK_P  => OUT_XCLK_P,
		OUT_XCLK_N  => OUT_XCLK_N,
		OUT_RESET_N => OUT_RESET_N,
		OUT_D       => OUT_D,
		OUT_DE      => OUT_DE,
		OUT_HS      => OUT_HS,
		OUT_VS      => OUT_VS
	);

	--------------------------

	asfifo_rgb : entity rgb_commons_v1_00_a.rgb_asfifo
	port map (
		ASYNC_RST     => RGB_RST,

		RGB_IN_CLK    => RGB_CLK,
		RGB_IN_R      => RGB_R,
		RGB_IN_G      => RGB_G,
		RGB_IN_B      => RGB_B,
		RGB_IN_EOL    => RGB_EOL,
		RGB_IN_EOF    => RGB_EOF,
		RGB_IN_WE     => fifo_we,
		RGB_IN_FULL   => fifo_full,

		RGB_OUT_CLK   => OUT_CLK,
		RGB_OUT_R     => out_r,
		RGB_OUT_G     => out_g,
		RGB_OUT_B     => out_b,
		RGB_OUT_EOL   => out_eol,
		RGB_OUT_EOF   => out_eof,
		RGB_OUT_RE    => fifo_re,
		RGB_OUT_EMPTY => fifo_empty
	);

	fifo_we <= not fifo_full and RGB_VLD;
	RGB_REQ <= fifo_we;

	--------------------------

	hsync_gen_i : entity work.sync_gen
	generic map (
		SYNC_LEN => 64,
		DEBUG    => DEBUG
	)
	port map (
		CLK    => OUT_CLK,
		RST    => OUT_RST,
		LAST   => out_eol_valid,
		SYNC_N => hsync,
		DBGOUT => hsync_dbgout
	);

	--------------------------

	vsync_gen_i : entity work.sync_gen
	generic map (
		SYNC_LEN => 640, -- XXX: is this right???
		DEBUG    => DEBUG
	)
	port map (
		CLK    => OUT_CLK,
		RST    => OUT_RST,
		LAST   => out_eof_valid,
		SYNC_N => vsync,
		DBGOUT => vsync_dbgout
	);

	--------------------------

	fsm_state : process(OUT_CLK, OUT_RST, nstate)
	begin
		if rising_edge(OUT_CLK) then
			if OUT_RST = '1' then
				state <= s_idle;
			else
				state <= nstate;
			end if;
		end if;
	end process;

	fsm_next : process(OUT_CLK, state, fifo_empty, fifo_re,
	                   out_eof, out_eol, hsync, vsync)
	begin
		nstate <= state;

		case state is
		when s_idle =>
			if fifo_empty = '0' then
				nstate <= s_pass;
			end if;

		when s_pass =>
			if fifo_re = '1' and out_eof = '1' then
				nstate <= s_eof;
			elsif fifo_re = '1' and out_eol = '1' then
				nstate <= s_eol;
			end if;

		when s_eol  =>
			if hsync = '1' then
				nstate <= s_idle;
			end if;
			
		when s_eof  =>
			if vsync = '1' then
				nstate <= s_idle;
			end if;

		end case;
	end process;

	fsm_output : process(OUT_CLK, state, fifo_empty, fifo_re,
	                     out_eol, out_eof)
	begin
		fifo_re       <= '0';
		out_eol_valid <= '0';
		out_eof_valid <= '0';
		out_data_en   <= '0';

		case state is
		when s_pass =>
			fifo_re       <= not fifo_empty;
			out_data_en   <= fifo_re;
			out_eol_valid <= fifo_re and out_eol;
			out_eof_valid <= fifo_re and out_eof;

		when others  =>
		end case;
	end process;

	--------------------------

gen_debug: if DEBUG = true
generate

	DBGOUT(0) <= OUT_CLK;
	DBGOUT(1) <= OUT_RST;

	DBGOUT( 7 downto 2) <= hsync_dbgout;
	DBGOUT(13 downto 8) <= vsync_dbgout;

	DBGOUT(14) <= fifo_re;
	DBGOUT(15) <= fifo_empty;

	DBGOUT(17 downto 16) <= "00" when state = s_idle else
	                        "01" when state = s_pass else
				"10" when state = s_eol  else
				"11" when state = s_eof  else
				"00";
	DBGOUT(19 downto 18) <= "00" when nstate = s_idle else
	                        "01" when nstate = s_pass else
				"10" when nstate = s_eol  else
				"11" when nstate = s_eof  else
				"00";

	DBGOUT(20) <= out_eol_valid;
	DBGOUT(21) <= out_eof_valid;

	DBGOUT(31 downto 22) <= (others => '1');

end generate;

end architecture;

