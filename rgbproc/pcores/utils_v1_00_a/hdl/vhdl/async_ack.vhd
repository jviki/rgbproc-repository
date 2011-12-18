-- async_ack.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity async_ack is
port (
	CLK  : in  std_logic;
	RST  : in  std_logic;
	REQ  : in  std_logic;
	ACK  : out std_logic;
	DRDY : out std_logic;
	RE   : in  std_logic
);
end entity;

architecture full of async_ack is

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

	fsm_next : process(CLK, state, REQ, RE)
	begin
		case state is
		when s_idle =>
			if REQ = '1' then
				nstate <= s_request;
			end if;

		when s_request =>
			if RE = '1' then
				nstate <= s_ack;
			end if;

		when s_ack =>
			if REQ = '0' then
				nstate <= s_idle;
			end if;
		end case;
	end process;

	fsm_output : process(CLK, state, RE)
	begin
		DRDY <= '0';
		ACK  <= '0';

		case state is
		when s_idle =>
			DRDY <= '0';
			ACK  <= '0';

		when s_request =>
			DRDY <= not RE;
			ACK  <= '0';

		when s_ack =>
			DRDY <= '0';
			ACK  <= '1';
			
		end case;
	end process;

end architecture;

