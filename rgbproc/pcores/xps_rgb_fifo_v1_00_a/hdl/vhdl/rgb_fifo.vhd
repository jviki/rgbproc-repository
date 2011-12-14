-- rgb_fifo.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library unisim;
use unisim.vcomponents.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.sync_fifo_fg;
use proc_common_v3_00_a.proc_common_pkg.log2;

entity rgb_fifo is
generic (
	DEPTH : integer := 2 * 640 * 480;
	DEBUG : boolean := false
);
port (
	CLK     : in  std_logic;
	RST     : in  std_logic;
	
	IN_R    : in  std_logic_vector(7 downto 0);
	IN_G    : in  std_logic_vector(7 downto 0);
	IN_B    : in  std_logic_vector(7 downto 0);
	IN_EOL  : in  std_logic;
	IN_EOF  : in  std_logic;
	IN_VLD  : in  std_logic;
	IN_REQ  : out std_logic;

	OUT_R   : out std_logic_vector(7 downto 0);
	OUT_G   : out std_logic_vector(7 downto 0);
	OUT_B   : out std_logic_vector(7 downto 0);
	OUT_EOL : out std_logic;
	OUT_EOF : out std_logic;
	OUT_VLD : out std_logic;
	OUT_REQ : in  std_logic;

	DBGOUT  : out std_logic_vector(63 downto 0)
);
end entity;

architecture full of rgb_fifo is

	component fifo_50_640
	port (
		clk: in std_logic;
		rst: in std_logic;
		din: in std_logic_vector(25 downto 0);
		wr_en: in std_logic;
		rd_en: in std_logic;
		dout: out std_logic_vector(25 downto 0);
		full: out std_logic;
		empty: out std_logic
	);
	end component;

	signal fifo_din   : std_logic_vector(25 downto 0);
	signal fifo_dout  : std_logic_vector(25 downto 0);
	signal fifo_we    : std_logic;
	signal fifo_re    : std_logic;
	signal fifo_full  : std_logic;
	signal fifo_empty : std_logic;

	signal cnt_pixels     : std_logic_vector(31 downto 0);
	signal cnt_pixels_clr : std_logic;
	signal cnt_pixels_up  : std_logic;
	signal cnt_pixels_down: std_logic;

	signal cnt_lines      : std_logic_vector(15 downto 0);
	signal cnt_lines_clr  : std_logic;
	signal cnt_lines_up   : std_logic;
	signal cnt_lines_down : std_logic;

begin

	fifo_din( 7 downto  0) <= IN_R;
	fifo_din(15 downto  8) <= IN_G;
	fifo_din(23 downto 16) <= IN_B;
	fifo_din(24) <= IN_EOL;
	fifo_din(25) <= IN_EOF;

	OUT_R <= fifo_dout( 7 downto  0);
	OUT_G <= fifo_dout(15 downto  8);
	OUT_B <= fifo_dout(23 downto 16);
	OUT_EOL <= fifo_dout(24);
	OUT_EOF <= fifo_dout(25);

	fifo_we <= IN_VLD and not fifo_full;
	IN_REQ  <= fifo_we;

	OUT_VLD <= not fifo_empty;
	fifo_re <= OUT_REQ and not fifo_empty;

	-------------------------------------

	assert DEPTH = 32768
		report "Currently only DEPTH = 32768 can be implemented"
		severity failure;

	-------------------------------------

gen_on_32768: if DEPTH = 32768
generate

	fifo_i : fifo_50_640
	port map (
		CLK   => CLK,
		RST   => RST,

		DIN   => fifo_din,
		WR_EN => fifo_we,
		DOUT  => fifo_dout,
		RD_EN => fifo_re,
		FULL  => fifo_full,
		EMPTY => fifo_empty
	);

end generate;

---
-- Leads to very long synthesis and simulation...
-- It should work some way but I did not discovered
-- how.
---
gen_never: if false
generate

	fifo_i : entity proc_common_v3_00_a.sync_fifo_fg
	generic map (
		C_FAMILY           => "virtex5",
		C_DCOUNT_WIDTH     => 0,
		C_MEMORY_TYPE      => 0,
		C_PRELOAD_REGS     => 1,
		C_PRELOAD_LATENCY  => 0,
		C_PORTS_DIFFER     => 0,
		C_READ_DATA_WIDTH  => 26,
		C_READ_DEPTH       => DEPTH,
		C_WRITE_DATA_WIDTH => 26,
		C_WRITE_DEPTH      => DEPTH
	)
	port map (
		Clk   => CLK,
		Sinit => RST, 
		Din   => fifo_din,
		Wr_en => fifo_we,
		Rd_en => fifo_re,
		Dout  => fifo_dout,
		Full  => fifo_full,
		Empty => fifo_empty
	);

end generate;

	-------------------------------------

gen_dbgout: if DEBUG = true
generate

	DBGOUT(0) <= cnt_lines_clr;
	DBGOUT(1) <= cnt_lines_up;
	DBGOUT(2) <= cnt_lines_down;
	DBGOUT(18 downto  3) <= cnt_lines;

	DBGOUT(19) <= cnt_pixels_clr;
	DBGOUT(20) <= cnt_pixels_up;
	DBGOUT(21) <= cnt_pixels_down;
	DBGOUT(53 downto 22) <= cnt_pixels;

	DBGOUT(54) <= fifo_empty;
	DBGOUT(55) <= fifo_full;

	DBGOUT(63 downto 56) <= (others => '0');

	-------------------

	cnt_linesp : process(CLK, cnt_lines_clr, cnt_lines_up, cnt_lines_down)
	begin
		if rising_edge(CLK) then
			if cnt_lines_clr = '1' then
				cnt_lines <= (others => '0');
			elsif cnt_lines_up = '1' and cnt_lines_down = '0' then
				cnt_lines <= cnt_lines + 1;
			elsif cnt_lines_up = '0' and cnt_lines_down = '1' then
				cnt_lines <= cnt_lines - 1;
			end if;
		end if;
	end process;

	cnt_pixelsp : process(CLK, cnt_pixels_clr, cnt_pixels_up, cnt_pixels_down)
	begin
		if rising_edge(CLK) then
			if cnt_pixels_clr = '1' then
				cnt_pixels <= (others => '0');
			elsif cnt_pixels_up = '1' and cnt_pixels_down = '0' then
				cnt_pixels <= cnt_pixels + 1;
			elsif cnt_pixels_up = '0' and cnt_pixels_down = '1' then
				cnt_pixels <= cnt_pixels - 1;
			end if;
		end if;
	end process;

	-------------------

	cnt_lines_clr   <= RST;
	cnt_lines_up    <= fifo_we and  IN_EOL;
	cnt_lines_down  <= fifo_re and fifo_dout(24); -- OUT_EOL

	cnt_pixels_clr  <= RST;
	cnt_pixels_up   <= fifo_we;
	cnt_pixels_down <= fifo_re;

end generate;

end architecture;

