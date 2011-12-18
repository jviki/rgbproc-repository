-- async_req.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity async_req is
port (
	CLK  : in  std_logic;
	RST  : in  std_logic;
	DRDY : in  std_logic;
	BUSY : out std_logic;
	REQ  : out std_logic;
	ACK  : in  std_logic
);
end entity;

architecture fsm of async_req is

	type state_t is (s_idle, s_request, s_ack);
	signal state  : state_t;
	signal nstate : state_t;

begin

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

	fsm_next : process(CLK, DRDY, ACK)
	begin
		nstate <= state;

		case state is
		when s_idle =>
			if DRDY = '1' then
				nstate <= s_request;
			end if;

		when s_request =>
			if ACK = '1' then
				nstate <= s_ack;
			end if;

		when s_ack =>
			if ACK = '0' then
				nstate <= s_idle;
			end if;
		end case;
	end process;

	fsm_output : process(CLK, state, DRDY, ACK)
	begin
		REQ <= '0';
		BUSY <= '0';

		case state is
		when s_idle =>
			REQ <= '0';
			BUSY <= DRDY;

		when s_request =>
			REQ <= '1';
			BUSY <= '1';

		when s_ack =>
			REQ <= '0';
			BUSY <= '1';

		end case;
	end process;

end architecture;
