-- line4_buff.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.log2;

---
-- Buffer of 4 RGB lines.
-- See line_buff.
---
entity line4_buff is
generic (
	LINE_WIDTH   : integer := 640;
	RATIO_OUT_IN : integer := 2
);
port (
	IN_CLK    : in  std_logic;
	IN_RST    : in  std_logic;
	IN_R      : in  std_logic_vector(7 downto 0);
	IN_G      : in  std_logic_vector(7 downto 0);
	IN_B      : in  std_logic_vector(7 downto 0);
	IN_EOL    : in  std_logic;
	IN_EOF    : in  std_logic;
	IN_VLD    : in  std_logic;
	IN_REQ    : out std_logic;
	
	OUT_CLK   : in  std_logic;
	OUT_RST   : in  std_logic;
	OUT_R     : out std_logic_vector(4 * 8 - 1 downto 0);
	OUT_G     : out std_logic_vector(4 * 8 - 1 downto 0);
	OUT_B     : out std_logic_vector(4 * 8 - 1 downto 0);
	-- bit map of valid lines on output
	OUT_MASK  : out std_logic_vector(3 downto 0);
	-- bit map to mark line to be empty
	OUT_MARK  : in  std_logic_vector(3 downto 0);
	-- data are valid at the next CLK after OUT_ADDR is set
	OUT_ADDR  : in  std_logic_vector(log2(LINE_WIDTH) - 1 downto 0)
);
end entity;

---
-- Holds a number of line buffers and routes ports to these
-- buffers using the following algorithm.
--
-- (1) All lines are empty => all in_full flags are LOW.
--     In that case nothing can be read from any line.
-- (2) Data comes => IN_VLD is asserted. Current line (i) is being
--     written until in_full(i) is asserted.
-- (3) Current line is full, it can be now read by OUT interface.
--     Signal in_full(i) increments the cnt_write_line counter to
--     write the next line.
-- (4) Next line is being written as described in (2) and (3) until
--     there is at least one line (j) with in_full(j) not asserted.
-- (5) If all lines are full then cnt_write_line is not being
--     incremented and nothing is written into any buffer.
-- (6) When writing the output interface can start to read any
--     buffer that is marked as full (in fact all such lines are read
--     in parallel). Until the writer marks a line to be empty it
--     can read the line at any address.
---
architecture composite_of_lines of line4_buff is

	constant LINE_COUNT       : integer := 4;

	signal cnt_write_line_ce  : std_logic;
	signal cnt_write_line_clr : std_logic;
	signal cnt_write_line     : std_logic_vector(1 downto 0);

	signal gen_in_req         : std_logic;

	signal in_we              : std_logic_vector(LINE_COUNT - 1 downto 0);
	signal in_full            : std_logic_vector(LINE_COUNT - 1 downto 0);
	signal mark_full          : std_logic_vector(LINE_COUNT - 1 downto 0);

	signal curr_full          : std_logic;
	signal last_curr_full     : std_logic;

begin

	curr_full <= in_full(conv_integer(cnt_write_line));

	last_curr_fullp : process(IN_CLK, curr_full)
	begin
		if rising_edge(IN_CLK) then
			last_curr_full <= curr_full;
		end if;
	end process;
	
	-------------------------------------------------

	gen_in_req <= IN_VLD and not curr_full;
	IN_REQ     <= gen_in_req;

	---
	-- Decoding which line to write
	---
	in_wep : process(IN_CLK, cnt_write_line, gen_in_req)
	begin
		for i in 0 to LINE_COUNT - 1 loop
			if i = cnt_write_line then
				in_we(i) <= gen_in_req;
			else
				in_we(i) <= '0';
			end if;
		end loop;
	end process;

	---
	-- Decoding which line to mark as full
	---
	mark_fullp : process(IN_CLK, IN_EOL, gen_in_req)
	begin
		for i in 0 to LINE_COUNT - 1 loop
			if i = cnt_write_line then
				mark_full(i) <= IN_EOL and gen_in_req;
			else
				mark_full(i) <= '0';
			end if;
		end loop;
	end process;

	-------------------------------------------------
	
	---
	-- Current line to be written
	---
	cnt_write_linep : process(IN_CLK, cnt_write_line_ce, cnt_write_line_clr)
	begin
		if rising_edge(IN_CLK) then
			if cnt_write_line_clr = '1' or IN_RST = '1' then
				cnt_write_line <= (others => '0');
			elsif cnt_write_line_ce = '1' then
				cnt_write_line <= cnt_write_line + 1;
			end if;
		end if;
	end process;

	---
	-- When all the frame was written start from the
	-- first line again.
	---
	cnt_write_line_clr <= IN_EOF and gen_in_req;
	---
	-- Simplier then defining whole FSM.
	-- IN_FULL is set at the end of line but can still be
	-- asserted when moving to new line (not already processed).
	-- To recognize the condition "at end of line" and "at begin of line"
	-- check last_curr_full value.
	---
	cnt_write_line_ce  <= not last_curr_full and curr_full;

	-------------------------------------------------

gen_line_buff_i : for i in 0 to LINE_COUNT - 1
generate
	
	line_buff_i : entity work.line_buff
	generic map (
		LINE_WIDTH   => LINE_WIDTH,
		RATIO_OUT_IN => RATIO_OUT_IN
	)
	port map (
		IN_CLK     => IN_CLK,
		IN_RST     => IN_RST,

		IN_R       => IN_R,
		IN_G       => IN_G,
		IN_B       => IN_B,
		IN_WE      => in_we(i),
		IN_FULL    => in_full(i),
		MARK_FULL  => mark_full(i),
		
		OUT_CLK    => OUT_CLK,
		OUT_RST    => OUT_RST,
		OUT_R      => OUT_R(i * 8 - 1 downto (i - 1) * 8),
		OUT_G      => OUT_G(i * 8 - 1 downto (i - 1) * 8),
		OUT_B      => OUT_B(i * 8 - 1 downto (i - 1) * 8),
		OUT_ADDR   => OUT_ADDR,
		OUT_FULL   => OUT_MASK(i),
		MARK_EMPTY => OUT_MARK(i)
	);

end generate;

end architecture;

