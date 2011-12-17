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

	type state_t is (s_src0, s_src1, s_sync0_to_1, s_0_to_sync1, s_sync1_to_0, s_1_to_sync0);
	signal state  : state_t;
	signal nstate : state_t;

	signal sync0        : std_logic;
	signal sync1        : std_logic;
	signal pulse_start0 : std_logic;
	signal pulse_start1 : std_logic;


begin

	sync0 <= IN0_HS or IN0_VS;
	sync1 <= IN1_HS or IN1_VS;

	----------------------------------

	detect_start_of_pulse0 : entity work.detect_start_of_pulse
	port map (
		CLK  => CLK,
		RST  => RST,
		SYNC => sync0,
		SOP  => pulse_start0
	);

	detect_start_of_pulse1 : entity work.detect_start_of_pulse
	port map (
		CLK  => CLK,
		RST  => RST,
		SYNC => sync1,
		SOP  => pulse_start1
	);

	----------------------------------

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
			if SRC_SEL = '1' and IN0_HS = '0' and IN0_VS = '0' and pulse_start1 = '1' then
				nstate <= s_src1;
			elsif SRC_SEL = '1' and IN0_HS = '0' and IN0_VS = '0' then
				nstate <= s_0_to_sync1;
			elsif SRC_SEL = '1' then
				nstate <= s_sync0_to_1;
			end if;

		when s_sync0_to_1 =>
			if IN0_HS = '0' and IN0_VS = '0' then
				nstate <= s_0_to_sync1;
			end if;

		when s_0_to_sync1 =>
			if pulse_start1 = '1' then
				nstate <= s_src1;
			end if;

		when s_src1 =>
			if SRC_SEL = '0' and IN1_HS = '0' and IN1_VS = '0' and pulse_start0 = '1' then
				nstate <= s_src0;
			elsif SRC_SEL = '0' and IN1_HS = '0' and IN1_VS = '0' then
				nstate <= s_1_to_sync0;
			elsif SRC_SEL = '0' then
				nstate <= s_sync1_to_0;;
			end if;

		when s_sync1_to_0 =>
			if IN1_HS = '0' and IN1_VS = '0' then
				nstate <= s_1_to_sync0;
			end if;

		when s_1_to_sync0 =>
			if pulse_start0 = '1' then
				nstate <= s_src0;
			end if;

		end case;
	end process;

	fsm_output : process(CLK, state)
	begin
		OUT_R <= (others => 'X');
		OUT_G <= (others => 'X');
		OUT_B <= (others => 'X');
		OUT_DE <= '0';
		OUT_HS <= '0';
		OUT_VS <= '0';

		case state is
		when s_src0 | s_sync0_to_1 =>
			OUT_R  <= IN0_R;
			OUT_G  <= IN0_G;
			OUT_B  <= IN0_B;
			OUT_DE <= IN0_DE;
			OUT_HS <= IN0_HS;
			OUT_VS <= IN0_VS;
			CUR_SEL <= '0';

		when s_0_to_sync1 =>
			CUR_SEL <= '0';

		when s_src1 | s_sync1_to_0 =>
			OUT_R  <= IN1_R;
			OUT_G  <= IN1_G;
			OUT_B  <= IN1_B;
			OUT_DE <= IN1_DE;
			OUT_HS <= IN1_HS;
			OUT_VS <= IN1_VS;
			CUR_SEL <= '1';

		when s_1_to_sync0 =>
			CUR_SEL <= '1';
			
		end case;
	end process;
end architecture;
