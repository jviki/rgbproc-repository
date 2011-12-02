-- rgb_win3x3.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.log2;

entity rgb_win3x3 is
generic (
	LINE_WIDTH   : integer := 640;
	LINES_COUNT  : integer := 480
);
port (
	CLK     : in  std_logic;
	RST     : in  std_logic;
	IN_R    : in  std_logic_vector(4 * 8 - 1 downto 0);
	IN_G    : in  std_logic_vector(4 * 8 - 1 downto 0);
	IN_B    : in  std_logic_vector(4 * 8 - 1 downto 0);
	IN_MASK : in  std_logic_vector(3 downto 0);
	IN_MARK : out std_logic_vector(3 downto 0);
	IN_ADDR : out std_logic_vector(log2(LINE_WIDTH) - 1 downto 0);
	
	WIN_R   : out std_logic_vector(9 * 8 - 1 downto 0);
	WIN_G   : out std_logic_vector(9 * 8 - 1 downto 0);
	WIN_B   : out std_logic_vector(9 * 8 - 1 downto 0);
	WIN_VLD : out std_logic;
	WIN_REQ : in  std_logic
);
end entity;

architecture fsm of rgb_win3x3 is

	subtype cnt_line_t is std_logic_vector(log2(LINES_COUNT) - 1 downto 0);
	type row_map_t is (r_line0, r_line1, r_line2, r_line3, r_dup);

	---
	-- Tests whether the mask contains enough '1' bits for processing
	-- current line.
	-- For the first line only bits 0 and 1 are necessary.
	-- For the last line at least two bits must be valid but they
	-- number will be computed in the function.
	-- For the other lines three bits must be valid at various
	-- positions.
	--
	-- How to count the bit positions.
	-- (1) IN_MASK moves this way:
	--     0000  loading line 0
	--     0001  loaded line 0, loading line 1
	--     0011  loading line 2
	--     0111  loading line 3
	--     1111  full
	-- (2) Lines are dropped when appropriate:
	--     0011  loading line 2
	--     0111  loading line 3, dropping line 0
	--     1110  loading line 4, dropping line 1
	--     1101  ...
	-- (3) Because using 4 lines buffer, the most interesting is
	--     modulo 4 of line number.
	-- (4) Last line only uses two lines that were already loaded.
	---
	function test_mask_for(signal mask : in std_logic_vector(3 downto 0);
	                       signal cnt_line : in cnt_line_t) return  boolean is
	begin
		---
		-- Only first line
		---
		if cnt_line = 0 then
			return mask(1 downto 0) = "11";
		end if;

		---
		-- Only last line
		---
		if cnt_line = LINES_COUNT - 1 then
			if (LINES_COUNT - 1) mod 4 = 1 then
				return (mask(1) and mask(0)) = '1';

			elsif (LINES_COUNT - 1) mod 4 = 2 then
				return (mask(2) and mask(1)) = '1';

			elsif (LINES_COUNT - 1) mod 4 = 3 then
				return (mask(3) and mask(2)) = '1';

			elsif (LINES_COUNT - 1) mod 4 = 0 then
				return (mask(0) and mask(3)) = '1';
			end if;
		end if;

		---
		-- All other non-border lines
		---
		-- every first line
		if conv_integer(cnt_line) mod 4 = 1 then
			return (mask(2) and mask(1) and mask(0)) = '1';

		-- every second line
		elsif conv_integer(cnt_line) mod 4 = 2 then
			return (mask(3) and mask(2) and mask(1)) = '1';

		-- every third line
		elsif conv_integer(cnt_line) mod 4 = 3 then
			return (mask(3) and mask(2) and mask(0)) = '1';

		-- every fourth line
		else -- conv_integer(cnt_line) mod 4 = 0
			return (mask(3) and mask(1) and mask(0)) = '1';

		end if;

	end function;

	---
	-- Returns a, b, c or d based  on modulo 4.
	---
	function line_by_modulo(signal cnt_line : cnt_line_t; a, b, c, d : row_map_t)
		return row_map_t is
	begin
		if conv_integer(cnt_line) mod 4 = 1 then
			return a;
		elsif conv_integer(cnt_line) mod 4 = 2 then
			return b;
		elsif conv_integer(cnt_line) mod 4 = 3 then
			return c;
		else -- conv_integer(cnt_line) mod 4 = 0 then
			return d;
		end if;
	end function;

	---
	-- Determines which buffer line to use to load the r'th row
	-- using counter cnt_line.
	-- Returns r_line0, r_line1, r_line2 or r_line3.
	--
	-- For the first line (cnt_line = 0) two rows are always used: r_line0, r_line1.
	-- For the last line two rows (that are already loaded) are always used.
	-- For the rest three distinct lines are used.
	--
	-- Computation is based on the facts mentioned in doc for function
	-- test_mask_for.
	---
	function get_line_for(r : integer; signal cnt_line : in cnt_line_t)
		return row_map_t is
	begin
		assert r >= 0 and r <= 2
			report "Invalid row map request: r = " & integer'image(r)
			severity failure;

		---
		-- Only the first line
		---
		if cnt_line = 0 then
			if r = 0 then
				return r_line0;
			elsif r = 1 then
				return r_line0;
			else
				return r_line1;
			end if;
		end if;

		---
		-- Only the last line
		---
		if cnt_line = LINES_COUNT - 1 then
			if r = 0 then
				return line_by_modulo(cnt_line, r_line0, r_line1, r_line2, r_line3);
			else -- r = 1 or r = 2
				return line_by_modulo(cnt_line, r_line1, r_line2, r_line3, r_line0);
			end if;
		end if;

		---
		-- All other lines
		---
		if r = 0 then
			return line_by_modulo(cnt_line, r_line0, r_line1, r_line2, r_line3);
		elsif r = 1 then
			return line_by_modulo(cnt_line, r_line1, r_line2, r_line3, r_line0);
		else -- r = 2
			return line_by_modulo(cnt_line, r_line2, r_line3, r_line0, r_line1);
		end if;
	end function;

	---
	-- Checks thether the next line is last...
	---
	function next_line_is_last(signal cnt_line : in cnt_line_t) return boolean is
	begin
		return cnt_line = LINES_COUNT - 2;
	end function;

	---
	-- Which bit in IN_MARK to set to clear that line buffer.
	---
	procedure mark_a_line(signal cnt_line : in cnt_line_t; signal mark : out std_logic_vector(3 downto 0)) is
	begin
		if cnt_line /= 0 then
			mark(conv_integer(cnt_line) mod 4) <= '1';
		end if;
	end procedure;

	----------------------------

	signal in_we       : std_logic;
	signal in_we_delay : std_logic;

	signal cnt_win_vld     : std_logic_vector(1 downto 0);
	signal cnt_win_vld_inc : std_logic;
	signal cnt_win_vld_dec : std_logic;
	signal cnt_win_vld_clr : std_logic;

	signal win_valid   : std_logic;

	signal row0_sel    : row_map_t;
	signal row1_sel    : row_map_t;
	signal row2_sel    : row_map_t;

	signal row0_sel_delay : row_map_t;
	signal row1_sel_delay : row_map_t;
	signal row2_sel_delay : row_map_t;

	signal row0_in_r   : std_logic_vector(7 downto 0);
	signal row0_in_g   : std_logic_vector(7 downto 0);
	signal row0_in_b   : std_logic_vector(7 downto 0);

	signal row1_in_r   : std_logic_vector(7 downto 0);
	signal row1_in_g   : std_logic_vector(7 downto 0);
	signal row1_in_b   : std_logic_vector(7 downto 0);

	signal row2_in_r   : std_logic_vector(7 downto 0);
	signal row2_in_g   : std_logic_vector(7 downto 0);
	signal row2_in_b   : std_logic_vector(7 downto 0);

	signal row0_last_r : std_logic_vector(7 downto 0);
	signal row0_last_g : std_logic_vector(7 downto 0);
	signal row0_last_b : std_logic_vector(7 downto 0);

	signal row1_last_r : std_logic_vector(7 downto 0);
	signal row1_last_g : std_logic_vector(7 downto 0);
	signal row1_last_b : std_logic_vector(7 downto 0);

	signal row2_last_r : std_logic_vector(7 downto 0);
	signal row2_last_g : std_logic_vector(7 downto 0);
	signal row2_last_b : std_logic_vector(7 downto 0);

	signal row0_r      : std_logic_vector(23 downto 0);
	signal row0_g      : std_logic_vector(23 downto 0);
	signal row0_b      : std_logic_vector(23 downto 0);
  
	signal row1_r      : std_logic_vector(23 downto 0);
	signal row1_g      : std_logic_vector(23 downto 0);
	signal row1_b      : std_logic_vector(23 downto 0);

	signal row2_r      : std_logic_vector(23 downto 0);
	signal row2_g      : std_logic_vector(23 downto 0);
	signal row2_b      : std_logic_vector(23 downto 0);

	----------------------------

	type state_t is (s_idle,
		s_first_line0, s_first_line1, s_first_line2, s_first_line, s_first_line_end, s_first_line_end0,
		s_any_line0,   s_any_line1,   s_any_line2,   s_any_line,   s_any_line_end,   s_any_line_end0,
		s_last_line0,  s_last_line1,  s_last_line2,  s_last_line,  s_last_line_end,  s_last_line_end0,
		s_any_line_wait, s_last_line_wait);

	signal state  : state_t;
	signal nstate : state_t;

	----------------------------

	signal cnt_line          : cnt_line_t;
	signal cnt_line_ce       : std_logic;
	signal cnt_line_clr      : std_logic;

	signal cnt_addr          : std_logic_vector(log2(LINE_WIDTH) - 1 downto 0);
	signal cnt_addr_ce       : std_logic;
	signal cnt_addr_clr      : std_logic;
	signal cnt_addr_overflow : std_logic;

begin

	cnt_linep : process(CLK, cnt_line_ce, cnt_line_clr)
	begin
		if rising_edge(CLK) then
			if cnt_line_clr = '1' then
				cnt_line <= (others => '0');
			elsif cnt_line_ce = '1' then
				cnt_line <= cnt_line + 1;
			end if;
		end if;
	end process;

	cnt_addrp : process(CLK, cnt_addr_ce, cnt_addr_clr)
	begin
		if rising_edge(CLK) then
			if cnt_addr_clr = '1' then
				cnt_addr <= (others => '0');
				cnt_addr_overflow <= '0';
			elsif cnt_addr_ce = '1' then
				if cnt_addr = LINE_WIDTH - 1 then
					cnt_addr_overflow <= '1';
				end if;

				cnt_addr <= cnt_addr + 1;
			end if;
		end if;
	end process;

	cnt_win_vldp : process(CLK, cnt_win_vld_inc, cnt_win_vld_dec, cnt_win_vld_clr)
	begin
		if rising_edge(CLK) then
			if cnt_win_vld_clr = '1' then
				cnt_win_vld <= (others => '0');
			elsif cnt_win_vld_inc = '1' and cnt_win_vld_dec = '0' then
				if cnt_win_vld /= (cnt_win_vld'range => '1') then
					cnt_win_vld <= cnt_win_vld + 1;
				end if;
			elsif cnt_win_vld_inc = '0' and cnt_win_vld_dec = '1' then
				if cnt_win_vld /= 0 then
					cnt_win_vld <= cnt_win_vld - 1;
				end if;
			end if;
		end if;
	end process;

	----------------------------

	fsm_state : process(CLK, RST, nstate)
	begin
		if rising_edge(CLK) then
			if RST = '1' then
				state <= s_idle;
			else
				state <= nstate;
			end if;
		end if;
	end process;

	---
	-- Some states can probably be merged but this can
	-- be better for debugging (it is clear whether there
	-- is first line, last line or other).
	---
	fsm_next : process(CLK, state, IN_MASK, cnt_line, cnt_addr_overflow, WIN_REQ)
	begin
		nstate <= state;

		case state is
		when s_idle =>
			if test_mask_for(IN_MASK, cnt_line) then
				nstate <= s_first_line0;
			end if;

		when s_first_line0 =>
			nstate <= s_first_line1;
		when s_first_line1 =>
			nstate <= s_first_line2;
		when s_first_line2 =>
			nstate <= s_first_line;

		when s_first_line =>
			if cnt_addr_overflow = '1' then
				nstate <= s_first_line_end0;
			end if;

		when s_first_line_end0 =>
			if WIN_REQ = '1' then
				nstate <= s_first_line_end;
			end if;

		when s_first_line_end =>
			if WIN_REQ = '1' then
				nstate <= s_any_line_wait;
			end if;

		--------------------------------
	
		when s_any_line_wait =>
			if test_mask_for(IN_MASK, cnt_line) then
				nstate <= s_any_line0;
			end if;

		when s_any_line0 =>
			nstate <= s_any_line1;
		when s_any_line1 =>
			nstate <= s_any_line2;
		when s_any_line2 =>
			nstate <= s_any_line;

		when s_any_line =>
			if cnt_addr_overflow = '1' then
				nstate <= s_any_line_end0;
			end if;

		when s_any_line_end0 =>
			if WIN_REQ = '1' then
				nstate <= s_any_line_end;
			end if;

		when s_any_line_end =>
			if WIN_REQ = '1' then
				if next_line_is_last(cnt_line) then
					nstate <= s_last_line_wait;
				else
					nstate <= s_any_line_wait;
				end if;
			end if;

		--------------------------------

		when s_last_line_wait =>
			-- This testing is not necessary, because
			-- the appropriate lines are already loaded.
			-- (reusing last two lines)
			if test_mask_for(IN_MASK, cnt_line) then
				nstate <= s_last_line0;
			end if;

		when s_last_line0 =>
			nstate <= s_last_line1;
		when s_last_line1 =>
			nstate <= s_last_line2;
		when s_last_line2 =>
			nstate <= s_last_line;

		when s_last_line  =>
			if cnt_addr_overflow = '1' then
				nstate <= s_last_line_end0;
			end if;

		when s_last_line_end0 =>
			if WIN_REQ = '1' then
				nstate <= s_last_line_end;
			end if;

		when s_last_line_end =>
			if WIN_REQ = '1' then
				nstate <= s_idle;
			end if;

		end case;
	end process;

	fsm_output : process(CLK, state, cnt_line, cnt_addr, cnt_addr_overflow, WIN_REQ)
	begin
		IN_ADDR <= (others => '0');
		IN_MARK <= (others => '0');
		in_we   <= '0';
		cnt_addr_ce  <= '0';
		cnt_addr_clr <= '0';
		cnt_line_ce  <= '0';
		cnt_line_clr <= '0';

		case state is
		when s_idle =>
			cnt_addr_clr <= '1';
			cnt_line_clr <= '1';

		-- preload first column to window
		when s_first_line0 | s_any_line0 | s_last_line0 =>
			IN_ADDR  <= cnt_addr; -- cleared to zero
			row0_sel <= get_line_for(0, cnt_line);
			row1_sel <= get_line_for(1, cnt_line);
			row2_sel <= get_line_for(2, cnt_line);

			cnt_addr_ce <= '1';
			in_we       <= '1';

		-- duplicate first column in window
		when s_first_line1 | s_any_line1 | s_last_line1 =>
			row0_sel <= r_dup;
			row1_sel <= r_dup;
			row2_sel <= r_dup;

			cnt_addr_ce <= '0'; -- duplicating, not reading
			in_we       <= '1';

		-- preload second column to window
		when s_first_line2 | s_any_line2 | s_last_line2 =>
			IN_ADDR  <= cnt_addr;
			row0_sel <= get_line_for(0, cnt_line);
			row1_sel <= get_line_for(1, cnt_line);
			row2_sel <= get_line_for(2, cnt_line);

			cnt_addr_ce <= '1';
			in_we       <= '1';

		-- all the columns inside line except first (col)
		when s_first_line | s_any_line | s_last_line =>
			IN_ADDR  <= cnt_addr; -- address for next column

			if cnt_addr_overflow = '1' then -- last column
				row0_sel <= r_dup;
				row1_sel <= r_dup;
				row2_sel <= r_dup;

				in_we        <= WIN_REQ;
				mark_a_line(cnt_line, IN_MARK);
			else
				row0_sel <= get_line_for(0, cnt_line);
				row1_sel <= get_line_for(1, cnt_line);
				row2_sel <= get_line_for(2, cnt_line);

				cnt_addr_ce <= WIN_REQ;
				in_we       <= WIN_REQ;
			end if;

		when s_first_line_end0 | s_any_line_end0 | s_last_line_end0 =>
			in_we <= WIN_REQ;

		-- offering last window of the this line
		when s_first_line_end | s_any_line_end | s_last_line_end =>
			cnt_addr_clr <= '1';
			cnt_line_ce  <= WIN_REQ;
			mark_a_line(cnt_line, IN_MARK);

		-- only waiting for filling next line
		when s_any_line_wait | s_last_line_wait =>
			null;

		end case;
	end process;

	----------------------------

	row0_in_r <= IN_R( 7 downto  0) when row0_sel_delay = r_line0 else
	             IN_R(15 downto  8) when row0_sel_delay = r_line1 else
	             IN_R(23 downto 16) when row0_sel_delay = r_line2 else
	             IN_R(31 downto 24) when row0_sel_delay = r_line3 else
	             row0_last_r        when row0_sel_delay = r_dup   else
		     (others => 'X');

	row0_in_g <= IN_G( 7 downto  0) when row0_sel_delay = r_line0 else
	             IN_G(15 downto  8) when row0_sel_delay = r_line1 else
	             IN_G(23 downto 16) when row0_sel_delay = r_line2 else
	             IN_G(31 downto 24) when row0_sel_delay = r_line3 else
	             row0_last_g        when row0_sel_delay = r_dup   else
		     (others => 'X');

	row0_in_b <= IN_B( 7 downto  0) when row0_sel_delay = r_line0 else
	             IN_B(15 downto  8) when row0_sel_delay = r_line1 else
	             IN_B(23 downto 16) when row0_sel_delay = r_line2 else
	             IN_B(31 downto 24) when row0_sel_delay = r_line3 else
	             row0_last_b        when row0_sel_delay = r_dup   else
		     (others => 'X');

	------------------

	row1_in_r <= IN_R( 7 downto  0) when row1_sel_delay = r_line0 else
	             IN_R(15 downto  8) when row1_sel_delay = r_line1 else
	             IN_R(23 downto 16) when row1_sel_delay = r_line2 else
	             IN_R(31 downto 24) when row1_sel_delay = r_line3 else
	             row1_last_r        when row1_sel_delay = r_dup   else
		     (others => 'X');

	row1_in_g <= IN_G( 7 downto  0) when row1_sel_delay = r_line0 else
	             IN_G(15 downto  8) when row1_sel_delay = r_line1 else
	             IN_G(23 downto 16) when row1_sel_delay = r_line2 else
	             IN_G(31 downto 24) when row1_sel_delay = r_line3 else
	             row1_last_g        when row1_sel_delay = r_dup   else
		     (others => 'X');

	row1_in_b <= IN_B( 7 downto  0) when row1_sel_delay = r_line0 else
	             IN_B(15 downto  8) when row1_sel_delay = r_line1 else
	             IN_B(23 downto 16) when row1_sel_delay = r_line2 else
	             IN_B(31 downto 24) when row1_sel_delay = r_line3 else
	             row1_last_b        when row1_sel_delay = r_dup   else
		     (others => 'X');

	------------------

	row2_in_r <= IN_R( 7 downto  0) when row2_sel_delay = r_line0 else
	             IN_R(15 downto  8) when row2_sel_delay = r_line1 else
	             IN_R(23 downto 16) when row2_sel_delay = r_line2 else
	             IN_R(31 downto 24) when row2_sel_delay = r_line3 else
	             row2_last_r        when row2_sel_delay = r_dup   else
		     (others => 'X');

	row2_in_g <= IN_G( 7 downto  0) when row2_sel_delay = r_line0 else
	             IN_G(15 downto  8) when row2_sel_delay = r_line1 else
	             IN_G(23 downto 16) when row2_sel_delay = r_line2 else
	             IN_G(31 downto 24) when row2_sel_delay = r_line3 else
	             row2_last_g        when row2_sel_delay = r_dup   else
		     (others => 'X');

	row2_in_b <= IN_B( 7 downto  0) when row2_sel_delay = r_line0 else
	             IN_B(15 downto  8) when row2_sel_delay = r_line1 else
	             IN_B(23 downto 16) when row2_sel_delay = r_line2 else
	             IN_B(31 downto 24) when row2_sel_delay = r_line3 else
	             row2_last_b        when row2_sel_delay = r_dup   else
		     (others => 'X');

	----------------------------

	WIN_R(23 downto  0) <= row0_r;
	WIN_G(23 downto  0) <= row0_g;
	WIN_B(23 downto  0) <= row0_b;

	WIN_R(47 downto 24) <= row1_r;
	WIN_G(47 downto 24) <= row1_g;
	WIN_B(47 downto 24) <= row1_b;

	WIN_R(71 downto 48) <= row2_r;
	WIN_G(71 downto 48) <= row2_g;
	WIN_B(71 downto 48) <= row2_b;

	----------------------------
	
	in_we_delayp : process(CLK, in_we, row0_sel, row1_sel, row2_sel)
	begin
		if rising_edge(CLK) then
			in_we_delay    <= in_we;
			row0_sel_delay <= row0_sel;
			row1_sel_delay <= row1_sel;
			row2_sel_delay <= row2_sel;
		end if;
	end process;

	cnt_win_vld_inc <= in_we_delay;
	cnt_win_vld_dec <= WIN_REQ and win_valid;
	cnt_win_vld_clr <= RST or cnt_line_ce;

	win_valid       <= '1' when cnt_win_vld = "11" else '0';
	WIN_VLD         <= win_valid;
	
	----------------------------

	row0_i : entity work.rgb_row3
	port map (
		CLK    => CLK,
		RST    => RST,
		IN_R   => row0_in_r,
		IN_G   => row0_in_g,
		IN_B   => row0_in_b,
		IN_WE  => in_we_delay,

		LAST_R => row0_last_r,
		LAST_G => row0_last_g,
		LAST_B => row0_last_b,

		OUT_R  => row0_r,
		OUT_G  => row0_g,
		OUT_B  => row0_b
	);
	
	row1_i : entity work.rgb_row3
	port map (
		CLK    => CLK,
		RST    => RST,
		IN_R   => row1_in_r,
		IN_G   => row1_in_g,
		IN_B   => row1_in_b,
		IN_WE  => in_we_delay,

		LAST_R => row1_last_r,
		LAST_G => row1_last_g,
		LAST_B => row1_last_b,

		OUT_R  => row1_r,
		OUT_G  => row1_g,
		OUT_B  => row1_b
	);
	
	row2_i : entity work.rgb_row3
	port map (
		CLK    => CLK,
		RST    => RST,
		IN_R   => row2_in_r,
		IN_G   => row2_in_g,
		IN_B   => row2_in_b,
		IN_WE  => in_we_delay,

		LAST_R => row2_last_r,
		LAST_G => row2_last_g,
		LAST_B => row2_last_b,

		OUT_R  => row2_r,
		OUT_G  => row2_g,
		OUT_B  => row2_b
	);
	
end architecture;

