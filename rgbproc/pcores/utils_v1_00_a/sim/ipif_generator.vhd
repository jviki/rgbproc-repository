-- ipif_generator.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.math_real.all;

entity ipif_generator is
generic (
	DWIDTH : integer := 32;
	AWIDTH : integer := 32;
	ADDR_MIN : integer := 0;
	ADDR_MAX : integer := 128
);
port (
	CLK          : in  std_logic;
	RST          : in  std_logic;
	Bus2IP_Addr  : out std_logic_vector(AWIDTH - 1 downto 0);
	Bus2IP_Data  : out std_logic_vector(DWIDTH - 1 downto 0);
	Bus2IP_RNW   : out std_logic;
	Bus2IP_BE    : out std_logic_vector(DWIDTH / 8 - 1 downto 0);
	Bus2IP_CS    : out std_logic;

	IPIF_BUSY    : out std_logic;
	IPIF_READ    : out std_logic;
	IPIF_DONE    : in  std_logic
);
end entity;

architecture full of ipif_generator is

	-- should be greater then CLK_FACTOR * AFIFO_DEPTH (eg. 4 * 16)
	-- when using asynchronous IPIF otherwise can be set to any value...
	constant DELAY_MIN   : integer := 70;
	constant DELAY_WIDTH : integer := 8;

	---
	-- Creates a random address conforming to the constraints
	-- ADDR_MIN and ADDR_MAX and based on random number 'rnd'.
	---
	procedure gen_addr(rnd : in integer; addr : out std_logic_vector(Bus2IP_Addr'range)) is
		variable rnd_addr : integer;
	begin
		assert ADDR_MIN < ADDR_MAX
			report "Invalid ADDR_{MIN,MAX}, constructs a negative range"
			severity failure;

		if rnd >= ADDR_MIN and rnd <= ADDR_MAX then
			rnd_addr := rnd;
		else
			rnd_addr := rnd mod (ADDR_MAX - ADDR_MIN + 1) + ADDR_MIN;
		end if;

		-- be multiple of 4 as PLB used to be...
		rnd_addr := rnd_addr - (rnd_addr mod 4);

		assert rnd_addr >= ADDR_MIN and rnd_addr <= ADDR_MAX
			report "BUG: invalid address generated: " & integer'image(rnd_addr)
			severity failure;

--		report "Generated address: " & integer'image(rnd_addr);
		addr := conv_std_logic_vector(rnd_addr, addr'length);
	end procedure;

	---
	-- Random generators
	---

	shared variable aseed0 : integer := 844396720;
	shared variable aseed1 : integer := 821616997;

	impure function getrand return real is
		variable r : real;
	begin
		uniform(aseed0, aseed1, r);
		return r;
	end function;

	impure function getbool return boolean is
	begin
		return getrand < 0.5;
	end function;

	impure function getbit return std_logic is
	begin
		if getbool then
			return '1';
		else
			return '0';
		end if;
	end function;

	impure function getint return integer is
	begin
		return integer(getrand * real(integer'high));
	end function;

	impure function getdelay return integer is
		variable delay : integer;
	begin
		delay := getint;

		if delay < DELAY_MIN then
			delay := DELAY_MIN + delay;
		end if;

		if delay mod DELAY_WIDTH < DELAY_MIN  then
			return DELAY_MIN;
		end if;

		return delay;
	end function;

	---
	-- Signals
	---

	type state_t is (s_idle, s_generate, s_busy, s_delay);
	signal state  : state_t;
	signal nstate : state_t;

	signal cnt_timer    : std_logic_vector(DELAY_WIDTH - 1 downto 0);
	signal cnt_timer_in : std_logic_vector(DELAY_WIDTH - 1 downto 0);
	signal cnt_timer_ce : std_logic;
	signal cnt_timer_le : std_logic;
	signal cnt_timer_of : std_logic;

	signal wait_enough  : std_logic;

	signal ipif_addr : std_logic_vector(AWIDTH - 1 downto 0);
	signal ipif_data : std_logic_vector(DWIDTH - 1 downto 0);
	signal ipif_rnw  : std_logic;
	signal ipif_be   : std_logic_vector(DWIDTH / 8 - 1 downto 0);
	signal ipif_cs   : std_logic;

begin

	wait_enough <= cnt_timer_of;

	cnt_timerp : process(CLK, RST, cnt_timer_ce, cnt_timer_le, cnt_timer_in)
	begin
		if rising_edge(CLK) then
			if RST = '1' then
				cnt_timer <= (others => '0');
			elsif cnt_timer_le = '1' then
				cnt_timer <= cnt_timer_in;
			elsif cnt_timer_ce = '1' then
				if cnt_timer = (cnt_timer'range => '1') then
					cnt_timer_of <= '1';
				else
					cnt_timer_of <= '0';
				end if;

				cnt_timer <= cnt_timer + 1;
			end if;
		end if;
	end process;

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

	fsm_next : process(CLK, state, wait_enough, IPIF_DONE)
	begin
		nstate <= state;

		case state is
		when s_idle =>
			nstate <= s_delay;
	
		when s_delay =>
			if wait_enough = '1' then
				nstate <= s_generate;
			end if;

		when s_generate =>
			if IPIF_DONE = '1' then
				nstate <= s_idle;
			else
				nstate <= s_busy;
			end if;

		when s_busy =>
			if IPIF_DONE = '1' then
				nstate <= s_idle;
			end if;
		end case;
	end process;	

	fsm_output : process(CLK, state, IPIF_DONE)
		variable address : std_logic_vector(Bus2IP_Addr'range);
		variable data    : integer;
		variable be      : integer;
		variable rnw     : std_logic;
		variable generated : boolean;
	begin
		cnt_timer_ce <= '0';
		cnt_timer_le <= '0';

		case state is
		when s_idle =>
			cnt_timer_le <= '1';
			cnt_timer_in <= conv_std_logic_vector(getdelay, cnt_timer_in'length);
			IPIF_BUSY   <= '0';

			ipif_cs   <= '0';
			ipif_addr <= (others => 'X');
			ipif_data <= (others => 'X');
			ipif_be   <= (others => 'X');
			ipif_rnw  <= 'X';

			generated := false;

		when s_delay =>
			cnt_timer_ce <= '1';
			IPIF_BUSY   <= '0';

			ipif_cs   <= '0';
			ipif_addr <= (others => 'X');
			ipif_data <= (others => 'X');
			ipif_be   <= (others => 'X');
			ipif_rnw  <= 'X';

		when s_generate =>
			IPIF_BUSY   <= '1';

			if not generated then
				gen_addr(getint, address);
				data      := getint;
				be        := getint;
				rnw       := getbit;
			end if;

			ipif_addr <= address;
			ipif_data <= conv_std_logic_vector(data, Bus2IP_Data'length);
			ipif_rnw  <= rnw;
			ipif_be   <= conv_std_logic_vector(be, Bus2IP_BE'length);
			ipif_cs   <= '1';

			generated := true;

		when s_busy =>
			IPIF_BUSY <= '1';

			ipif_addr <= address;
			ipif_data <= conv_std_logic_vector(data, Bus2IP_Data'length);
			ipif_rnw  <= rnw;
			ipif_be   <= conv_std_logic_vector(be, Bus2IP_BE'length);
			ipif_cs   <= not IPIF_DONE;
		end case;
	end process;

	Bus2IP_Addr <= ipif_addr;
	Bus2IP_Data <= ipif_data;
	Bus2IP_RNW  <= ipif_rnw;
	Bus2IP_CS   <= ipif_cs;
	Bus2IP_BE   <= ipif_be;

	IPIF_READ <= ipif_rnw;

end architecture;
