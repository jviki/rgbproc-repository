-- rgb_fifo.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.sync_fifo_fg;

entity rgb_fifo is
generic (
	DEPTH : integer := 2 * 640 * 480
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
	OUT_REQ : in  std_logic
);
end entity;

architecture full of rgb_fifo is

	signal fifo_din   : std_logic_vector(25 downto 0);
	signal fifo_dout  : std_logic_vector(25 downto 0);
	signal fifo_we    : std_logic;
	signal fifo_re    : std_logic;
	signal fifo_full  : std_logic;
	signal fifo_empty : std_logic;

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

end architecture;

