-- async_ipif.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>
-- Copyright (C) 2011, 2012 Jan Viktorin

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity async_ipif is
generic (
	AWIDTH : integer := 32; -- address width
	DWIDTH : integer := 32; -- data width
	NADDR  : integer := 1   -- count of address spaces
);
port (
	M_CLK          : in  std_logic;
	M_RST          : in  std_logic;
	M_IP2Bus_Data  : out std_logic_vector(DWIDTH - 1 downto 0);
	M_IP2Bus_WrAck : out std_logic;
	M_IP2Bus_RdAck : out std_logic;
	M_IP2Bus_Error : out std_logic;
	M_Bus2IP_Addr  : in  std_logic_vector(AWIDTH - 1 downto 0);
	M_Bus2IP_Data  : in  std_logic_vector(DWIDTH - 1 downto 0);
	M_Bus2IP_RNW   : in  std_logic;
	M_Bus2IP_BE    : in  std_logic_vector(DWIDTH / 8 - 1 downto 0);
	M_Bus2IP_CS    : in  std_logic_vector(NADDR - 1 downto 0);

	S_CLK          : in  std_logic;
	S_RST          : in  std_logic;
	S_IP2Bus_Data  : in  std_logic_vector(DWIDTH - 1 downto 0);
	S_IP2Bus_WrAck : in  std_logic;
	S_IP2Bus_RdAck : in  std_logic;
	S_IP2Bus_Error : in  std_logic;
	S_Bus2IP_Addr  : out std_logic_vector(AWIDTH - 1 downto 0);
	S_Bus2IP_Data  : out std_logic_vector(DWIDTH - 1 downto 0);
	S_Bus2IP_RNW   : out std_logic;
	S_Bus2IP_BE    : out std_logic_vector(DWIDTH / 8 - 1 downto 0);
	S_Bus2IP_CS    : out std_logic_vector(NADDR - 1 downto 0)
);
end entity;

architecture full of async_ipif is

	constant AFIFO_DEPTH : integer := 16;

	signal master_afifo_di    : std_logic_vector(69 downto 0);
	signal master_afifo_we    : std_logic;
	signal master_afifo_full  : std_logic;
	signal master_afifo_do    : std_logic_vector(69 downto 0);
	signal master_afifo_re    : std_logic;
	signal master_afifo_empty : std_logic;

	signal slave_afifo_di     : std_logic_vector(34 downto 0);
	signal slave_afifo_we     : std_logic;
	signal slave_afifo_full   : std_logic;
	signal slave_afifo_do     : std_logic_vector(34 downto 0);
	signal slave_afifo_re     : std_logic;
	signal slave_afifo_empty  : std_logic;

	signal slave_cs           : std_logic;
	signal slave_wrack        : std_logic;
	signal slave_rdack        : std_logic;
	signal was_slave_afifo_empty  : std_logic;
	signal was_master_afifo_empty : std_logic;

	signal or_reset           : std_logic;

	type state_t is (s_idle, s_wait_ack, s_wait_not_cs);
	signal state  : state_t;
	signal nstate : state_t;

begin

	or_reset <= S_RST or M_RST;

	slave_cs  <= master_afifo_do(69) and not was_master_afifo_empty;

	---------------------------------

	master_afifo_i : entity work.afifo
	generic map (
		DWIDTH => master_afifo_di'length,
		DEPTH  => AFIFO_DEPTH
	)
	port map (
		WCLK  => M_CLK,
		RCLK  => S_CLK,

		RESET => or_reset,
		
		WE    => master_afifo_we,
		FULL  => master_afifo_full,
		DI    => master_afifo_di,

		RE    => master_afifo_re,
		EMPTY => master_afifo_empty,
		DO    => master_afifo_do
	);

	------------

	master_afifo_di(31 downto  0) <= M_Bus2IP_Addr;
	master_afifo_di(63 downto 32) <= M_Bus2IP_Data;
	master_afifo_di(67 downto 64) <= M_Bus2IP_BE;
	master_afifo_di(68)           <= M_Bus2IP_RNW;
	master_afifo_di(69)           <= M_Bus2IP_CS(0);

	master_afifo_we               <= M_Bus2IP_CS(0) and not master_afifo_full;

	------------

	S_Bus2IP_Addr  <= master_afifo_do(31 downto  0);
	S_Bus2IP_Data  <= master_afifo_do(63 downto 32);
	S_Bus2IP_BE    <= master_afifo_do(67 downto 64);
	S_Bus2IP_RNW   <= master_afifo_do(68) and not was_master_afifo_empty;

	master_afifo_re  <= not master_afifo_empty;

	------------

	was_master_afifo_emptyp : process(S_CLK, master_afifo_empty)
	begin
		if rising_edge(S_CLK) then
			was_master_afifo_empty <= master_afifo_empty;
		end if;
	end process;

	---------------------------------

	slave_afifo_i : entity work.afifo
	generic map (
		DWIDTH => slave_afifo_di'length,
		DEPTH  => AFIFO_DEPTH
	)
	port map (
		WCLK  => S_CLK,
		RCLK  => M_CLK,

		RESET => or_reset,

		WE    => slave_afifo_we,
		FULL  => slave_afifo_full,
		DI    => slave_afifo_di,

		RE    => slave_afifo_re,
		EMPTY => slave_afifo_empty,
		DO    => slave_afifo_do
	);

	------------

	slave_afifo_di(31 downto 0) <= S_IP2Bus_Data;
	slave_afifo_di(32)          <= slave_wrack;
	slave_afifo_di(33)          <= slave_rdack;
	slave_afifo_di(34)          <= S_IP2Bus_Error;

	slave_afifo_we <= (S_IP2Bus_WrAck or S_IP2Bus_RdAck) and not slave_afifo_full;

	------------

	M_IP2Bus_Data  <= slave_afifo_do(31 downto 0);
	M_IP2Bus_WrAck <= slave_afifo_do(32) and not was_slave_afifo_empty;
	M_IP2Bus_RdAck <= slave_afifo_do(33) and not was_slave_afifo_empty;
	M_IP2Bus_Error <= slave_afifo_do(34) and not was_slave_afifo_empty;

	slave_afifo_re <= not slave_afifo_empty;

	------------

	was_slave_afifo_emptyp : process(M_CLK, slave_afifo_empty)
	begin
		if rising_edge(M_CLK) then
			was_slave_afifo_empty <= slave_afifo_empty;
		end if;
	end process;

	---------------------------------

	fsm_state : process(S_CLK, S_RST, nstate)
	begin
		if rising_edge(S_CLK) then
			if S_RST = '1' then
				state <= s_idle;
			else
				state <= nstate;
			end if;
		end if;
	end process;

	fsm_next : process(S_CLK, state, slave_cs, S_IP2Bus_WrAck, S_IP2Bus_RdAck)
	begin
		nstate <= state;

		case state is
		when s_idle =>
			if slave_cs = '1' and S_IP2Bus_WrAck = '0' and S_IP2Bus_RdAck = '0' then
				nstate <= s_wait_ack;
			elsif slave_cs = '1' and (S_IP2Bus_WrAck = '1' or S_IP2Bus_RdAck = '1') then
				nstate <= s_wait_not_cs;
			end if;

		when s_wait_ack =>
			if S_IP2Bus_WrAck = '1' or S_IP2Bus_RdAck = '1' then
				nstate <= s_wait_not_cs;
			end if;

		when s_wait_not_cs =>
			if slave_cs = '0' then
				nstate <= s_idle;
			end if;

		end case;
	end process;

	fsm_output : process(S_CLK, state, slave_cs, S_IP2Bus_WrAck, S_IP2Bus_RdAck)
	begin
		S_Bus2IP_CS(0) <= '0';
		slave_wrack    <= '0';
		slave_rdack    <= '0';

		case state is
		when s_idle =>
			S_Bus2IP_CS(0) <= slave_cs;
			slave_wrack    <= S_IP2Bus_WrAck;
			slave_rdack    <= S_IP2Bus_RdAck;

		when s_wait_ack =>
			S_Bus2IP_CS(0) <= slave_cs;
			slave_wrack    <= S_IP2Bus_WrAck;
			slave_rdack    <= S_IP2Bus_RdAck;

		when s_wait_not_cs =>
			S_Bus2IP_CS(0) <= '0';
			slave_wrack    <= '0';
			slave_rdack    <= '0';

		end case;
	end process;

end architecture;

