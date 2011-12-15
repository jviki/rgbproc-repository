-- rgb2chrontel.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library rgb_commons_v1_00_a;
use rgb_commons_v1_00_a.rgb_asfifo;

---
-- The unit converts RGB bus data to output suitable
-- to be sent to CH7301C chip (and then to a screen).
--
-- Data on RGB bus must provide only valid frames
-- of correct size. If a malformed frame is passed
-- into this unit the behaviour is undefined.
--
-- When RGB_VLD is not asserted at the time when
-- the unit wants to write data to the screen
-- it starts to hold HS and VS pulses until
-- valid data are ready. Then the screen refresh cycle
-- starts again (to assure consistency) so the data are
-- not used immediately.
--
-- RGB input bus must be reliable in the sense that
-- if RGB_VLD is asserted once it must not be deasserted
-- until RGB_REQ is generated from this unit and it
-- must provide data until the end of frame.
-- (In fact the implementation should use some kind of
-- asynchronous FIFO so some buffering is provided
-- inside as well.)
---
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

	DBGOUT      : out std_logic_vector(39 downto 0)
);
end entity;

architecture full of rgb2chrontel is

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

	signal ctrl_sleep    : std_logic;
	signal ctrl_hs       : std_logic;
	signal ctrl_vs       : std_logic;
	signal ctrl_de       : std_logic;
	signal ctrl_last     : std_logic;

	type state_t is (s_idle, s_frame_data, s_fallback);
	signal state         : state_t;
	signal nstate        : state_t;

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

	frame_ctrl_i : entity work.frame_ctrl
	port map (
		CLK   => OUT_CLK,
		RST   => OUT_RST,
		SLEEP => ctrl_sleep,
		HS    => ctrl_hs,
		VS    => ctrl_vs,
		DE    => ctrl_de,
		LAST  => ctrl_last
	);

	hsync <= not ctrl_hs;
	vsync <= not ctrl_vs;

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

	fsm_next : process(OUT_CLK, state, ctrl_de, fifo_empty, ctrl_vs)
	begin
		nstate <= state;

		case state is
		when s_idle =>
			if ctrl_de = '1' and fifo_empty = '0' then
				nstate <= s_frame_data;
			elsif ctrl_de = '1' and fifo_empty = '1' then
				nstate <= s_fallback;
			end if;

		when s_frame_data =>
			if ctrl_vs = '1' then
				nstate <= s_idle;
			elsif fifo_re = '1' and out_eof = '1' and ctrl_last = '0' then
				nstate <= s_fallback;
			end if;

		when s_fallback =>
			if fifo_empty = '0' then
				nstate <= s_idle;
			end if;

		end case;
	end process;

	fsm_output : process(OUT_CLK, state, ctrl_de, fifo_empty)
	begin
		fifo_re     <= '0';
		ctrl_sleep  <= '0';
		out_data_en <= '0';

		case state is
		when s_idle =>
			fifo_re     <= ctrl_de and not fifo_empty;
			out_data_en <= ctrl_de and not fifo_empty;

		when s_frame_data =>
			-- now the data stream should be reliable
			-- until the end of frame
			fifo_re     <= ctrl_de and not fifo_empty;
			out_data_en <= ctrl_de and not fifo_empty;

		when s_fallback =>
			ctrl_sleep <= '1';

		end case;
	end process;

	--------------------------

gen_debug: if DEBUG = true
generate

	DBGOUT(0) <= OUT_RST;

	DBGOUT(12 downto 1) <= out_data0;

	DBGOUT(13) <= fifo_re;
	DBGOUT(14) <= fifo_empty;

	DBGOUT(16 downto 15) <= "00" when state = s_idle       else
	                        "01" when state = s_frame_data else
				"10" when state = s_fallback   else
				"11";
	DBGOUT(18 downto 17) <= "00" when nstate = s_idle       else
	                        "01" when nstate = s_frame_data else
				"10" when nstate = s_fallback   else
				"11";

	DBGOUT(19) <= hsync;
	DBGOUT(20) <= vsync;

	DBGOUT(32 downto 21) <= out_data1;
	DBGOUT(33) <= out_data_en;
	DBGOUT(34) <= ctrl_sleep;

	DBGOUT(35) <= out_eol and fifo_re;
	DBGOUT(36) <= out_eof and fifo_re;

	DBGOUT(37) <= ctrl_de;
	DBGOUT(39 downto 38) <= (others => '1');

end generate;

end architecture;

