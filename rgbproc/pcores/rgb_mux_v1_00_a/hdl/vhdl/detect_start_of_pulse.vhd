-- detect_start_of_pulse.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity detect_start_of_pulse is
port (
	CLK    : in  std_logic;
	RST    : in  std_logic;
	SYNC   : in  std_logic;
	SOP    : out std_logic
);
end entity;

architecture fsm of detect_start_of_pulse is

	type state_t is (s_init, s_pulse, s_not_pulse);
	signal state  : state_t;
	signal nstate : state_t;

begin

	fsm_state : process(CLK, RST, nstate)
	begin
		if rising_edge(CLK) then
			if RST = '1' then
				state <= s_init;
			else
				state <= nstate;
			end if;
		end if;
	end process;

	fsm_next : process(CLK, state, SYNC)
	begin
		nstate <= state;

		case state is
		when s_init =>
			if SYNC = '1' then
				nstate <= s_not_pulse;
			elsif SYNC = '0' then
				nstate <= s_pulse;
			end if;

		when s_not_pulse =>
			if SYNC = '0' then
				nstate <= s_pulse;
			end if;

		when s_pulse =>
			if SYNC = '1' then
				nstate <= s_not_pulse;
			end if;
		end case;
	end process;

	fsm_output : process(CLK, state, SYNC)
	begin
		SOP <= '0';

		case state is
		when s_pulse =>
			SOP <= '0';

		when s_not_pulse =>
			SOP <= not SYNC;
		end case;
	end process;

end architecture;
