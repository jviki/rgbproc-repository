-- rgb_mux.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity rgb_mux is
generic (
	DEFAULT_SRC : integer := 0
);
port (
	CLK     : in  std_logic;
	RST     : in  std_logic;

	SRC_SEL : in  std_logic;
	CUR_SEL : out std_logic;

	IN0_R   : in  std_logic_vector(7 downto 0);
	IN0_G   : in  std_logic_vector(7 downto 0);
	IN0_B   : in  std_logic_vector(7 downto 0);
	IN0_DE  : in  std_logic;
	IN0_HS  : in  std_logic;
	IN0_VS  : in  std_logic;

	IN1_R   : in  std_logic_vector(7 downto 0);
	IN1_G   : in  std_logic_vector(7 downto 0);
	IN1_B   : in  std_logic_vector(7 downto 0);
	IN1_DE  : in  std_logic;
	IN1_HS  : in  std_logic;
	IN1_VS  : in  std_logic;

	OUT_R   : out std_logic_vector(7 downto 0);
	OUT_G   : out std_logic_vector(7 downto 0);
	OUT_B   : out std_logic_vector(7 downto 0);
	OUT_DE  : out std_logic;
	OUT_HS  : out std_logic;
	OUT_VS  : out std_logic
);
end entity;

architecture full of rgb_mux is

	type state_t is (s_src0, s_src1, s_wait_eof0, s_wait0, s_wait_eof1, s_wait1);
	signal state  : state_t;
	signal nstate : state_t;

begin

	fsm_state : process(CLK, RST, nstate)
	begin
		if rising_edge(CLK) then
			if RST = '1' then
				if DEFAULT_SRC = 0 then
					state <= s_src0;
				else
					state <= s_src1;
				end if;
			else
				state <= nstate;
			end if;
		end if;
	end process;

	fsm_next : process(CLK, state, SRC_SEL, IN0_HS, IN0_VS, IN1_HS, IN1_VS)
	begin
		nstate <= state;

		case state is
		when s_src0 =>
			if SRC_SEL = '1' then
				nstate <= s_wait_eof1;
			end if;

		when s_wait_eof1 =>
			if IN0_HS = '0' and IN0_VS = '0' then
				nstate <= s_wait1;
			end if;

		when s_wait1 =>
			if IN0_HS = '1' and IN0_VS = '1' then
				nstate <= s_src1;
			end if;

		when s_src1 =>
			if SRC_SEL = '0' then
				nstate <= s_wait0;
			end if;

		when s_wait_eof0 =>
			if IN1_HS = '0' and IN1_VS = '0' then
				nstate <= s_wait0;
			end if;

		when s_wait0 =>
			if IN1_HS = '1' and IN1_VS = '1' then
				nstate <= s_src0;
		end case;
	end process;

	fsm_output : process(CLK, state)
	begin
		case state is
		when s_src0 | s_wait_eof1 | s_wait1 =>
			OUT_R  <= IN0_R;
			OUT_G  <= IN0_G;
			OUT_B  <= IN0_B;
			OUT_DE <= IN0_DE;
			OUT_HS <= IN0_HS;
			OUT_VS <= IN0_VS;
			CUR_SEL <= '0';

		when others => -- s_src1 | s_wait_eof0 | s_wait0
			OUT_R  <= IN1_R;
			OUT_G  <= IN1_G;
			OUT_B  <= IN1_B;
			OUT_DE <= IN1_DE;
			OUT_HS <= IN1_HS;
			OUT_VS <= IN1_VS;
			CUR_SEL <= '1';
			
		end case;
	end process;
end architecture;
