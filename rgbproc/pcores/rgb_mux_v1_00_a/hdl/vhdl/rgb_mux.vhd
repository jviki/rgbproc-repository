-- rgb_mux.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library utils_v1_00_a;
use utils_v1_00_a.ipif_reg;
use utils_v1_00_a.ipif_reg_logic;

entity rgb_mux is
generic (
	IPIF_AWIDTH : integer := 32;
	IPIF_DWIDTH : integer := 32;
	DEFAULT_SRC : integer := 0
);
port (
	CLK     : in  std_logic;
	RST     : in  std_logic;

	Bus2IP_Addr  : out std_logic_vector(IPIF_AWIDTH - 1 downto 0);
	Bus2IP_CS    : out std_logic_vector(0 downto 0);
	Bus2IP_RNW   : out std_logic;
	Bus2IP_Data  : out std_logic_vector(IPIF_DWIDTH - 1 downto 0);
	Bus2IP_BE    : out std_logic_vector(IPIF_DWIDTH/8 - 1 downto 0);
	IP2Bus_Data  : in  std_logic_vector(IPIF_DWIDTH - 1 downto 0);
	IP2Bus_RdAck : in  std_logic;
	IP2Bus_WrAck : in  std_logic;
	IP2Bus_Error : in  std_logic;

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

	signal src_sel      : std_logic;
	signal cur_sel      : std_logic;

begin

	---
	-- Device ID register
	---
	reg_id : utils_v1_00_a.ipif_reg
	generic map (
		REG_DWIDTH  => 32,
		REG_DEFAULT => 1,
		IPIF_DWIDTH => IPIF_DWIDTH,
		IPIF_MODE   => 0
	)
	port map (
		CLK          => CLK,
		RST          => RST,

		IP2Bus_Data  => ipif_data(31 downto 0),
		IP2Bus_WrAck => ipif_wrack(0),
		IP2Bus_RdAck => ipif_rdack(0),
		IP2Bus_Error => ipif_error(0),		
		Bus2IP_Data  => Bus2IP_Data,
		Bus2IP_BE    => Bus2IP_BE,
		Bus2IP_RNW   => Bus2IP_RNW,
		Bus2IP_CS    => ipif_cs(0),

		REG_DI       => (others => 'X'),
		REG_WE       => '0'
	);

	---
	-- MUX select register
	---
	cfg_sel : utils_v1_00_a.ipif_reg_logic
	generic map (
		REG_DWIDTH  => 1,
		IPIF_DWIDTH => IPIF_DWIDTH,
		IPIF_MODE   => 2
	)
	port map (
		CLK          => CLK,
		RST          => RST,

		IP2Bus_Data  => ipif_data(63 downto 32),
		IP2Bus_WrAck => ipif_wrack(1),
		IP2Bus_RdAck => ipif_rdack(1),
		IP2Bus_Error => ipif_error(1),		
		Bus2IP_Data  => Bus2IP_Data,
		Bus2IP_BE    => Bus2IP_BE,
		Bus2IP_RNW   => Bus2IP_RNW,
		Bus2IP_CS    => ipif_cs(1),

		REG_DO       => cur_sel,
		REG_BE       => src_sel_be,
		REG_DI       => src_sel_in,
		REG_WE       => src_sel_we
	);

	---
	-- IPIF address logic
	---

	ipif_cs(0)  <= Bus2IP_CS(0) when Bus2IP_Addr = X"00000000" else '0';
	ipif_cs(1)  <= Bus2IP_CS(0) when Bus2IP_Addr = X"00000004" else '0';
	
	-- invalid address request
	ipif_gerror <= Bus2IP_CS(0) and (ipif_cs = "00");

	IP2Bus_Data <= ipif_data(63 downto 32) when ipif_cs = "10" else
                    <= ipif_data(31 downto  0);

	IP2Bus_WrAck <= ipif_wrack(0) or ipif_wrack(1);
	IP2Bus_RdAck <= ipif_rdack(0) or ipif_rdack(1);
	IP2Bus_Error <= ipif_error(0) or ipif_error(1) or ipif_gerror;

	----------------------------------

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

	fsm_next : process(CLK, state, src_sel, IN0_HS, IN0_VS, IN1_HS, IN1_VS)
	begin
		nstate <= state;

		case state is
		when s_src0 =>
			if src_sel = '1' and IN0_HS = '0' and IN0_VS = '0' and pulse_start1 = '1' then
				nstate <= s_src1;
			elsif src_sel = '1' and IN0_HS = '0' and IN0_VS = '0' then
				nstate <= s_0_to_sync1;
			elsif src_sel = '1' then
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
			if src_sel = '0' and IN1_HS = '0' and IN1_VS = '0' and pulse_start0 = '1' then
				nstate <= s_src0;
			elsif src_sel = '0' and IN1_HS = '0' and IN1_VS = '0' then
				nstate <= s_1_to_sync0;
			elsif src_sel = '0' then
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
			cur_sel <= '0';

		when s_0_to_sync1 =>
			cur_sel <= '0';

		when s_src1 | s_sync1_to_0 =>
			OUT_R  <= IN1_R;
			OUT_G  <= IN1_G;
			OUT_B  <= IN1_B;
			OUT_DE <= IN1_DE;
			OUT_HS <= IN1_HS;
			OUT_VS <= IN1_VS;
			cur_sel <= '1';

		when s_1_to_sync0 =>
			cur_sel <= '1';
			
		end case;
	end process;
end architecture;
