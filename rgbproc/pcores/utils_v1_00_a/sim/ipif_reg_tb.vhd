-- ipif_reg_tb.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

use work.utils_pkg.all;

entity ipif_reg_tb is
end entity;

architecture testbench of ipif_reg_tb is

	constant BASE_MHZ : time := 1 us;
	constant FREQ     : real := 100.0;
	constant PERIOD   : time := BASE_MHZ / FREQ;

	constant FREQ_SLOW   : real := 25.0;
	constant PERIOD_SLOW : time := BASE_MHZ / FREQ_SLOW;

	signal clk     : std_logic;
	signal rst     : std_logic;

	signal clk_slow : std_logic;
	signal rst_slow : std_logic;

	signal ipif_busy    : std_logic;
	signal ipif_done    : std_logic;
	signal ipif_read    : std_logic;

	signal M_CLK          : std_logic;
	signal M_RST          : std_logic;
	signal M_IP2Bus_Data  : std_logic_vector(31 downto 0);
	signal M_IP2Bus_WrAck : std_logic;
	signal M_IP2Bus_RdAck : std_logic;
	signal M_IP2Bus_Error : std_logic;
	signal M_Bus2IP_Addr  : std_logic_vector(31 downto 0);
	signal M_Bus2IP_Data  : std_logic_vector(31 downto 0);
	signal M_Bus2IP_RNW   : std_logic;
	signal M_Bus2IP_BE    : std_logic_vector(3 downto 0);
	signal M_Bus2IP_CS    : std_logic_vector(0 downto 0);

	signal S_CLK          : std_logic;
	signal S_RST          : std_logic;
	signal S_IP2Bus_Data  : std_logic_vector(31 downto 0);
	signal S_IP2Bus_WrAck : std_logic;
	signal S_IP2Bus_RdAck : std_logic;
	signal S_IP2Bus_Error : std_logic;
	signal S_Bus2IP_Addr  : std_logic_vector(31 downto 0);
	signal S_Bus2IP_Data  : std_logic_vector(31 downto 0);
	signal S_Bus2IP_RNW   : std_logic;
	signal S_Bus2IP_BE    : std_logic_vector(3 downto 0);
	signal S_Bus2IP_CS    : std_logic_vector(0 downto 0);

begin

	M_CLK <= clk;
	M_RST <= rst;
	S_CLK <= clk_slow;
	S_RST <= rst_slow;

	ipif_gen_i : entity work.ipif_generator
	generic map (
		DWIDTH   => 32,
		AWIDTH   => 32,
		ADDR_MIN =>  0,
		ADDR_MAX =>  1
	)
	port map (
		CLK => M_CLK,
		RST => M_RST,

		Bus2IP_Addr => M_Bus2IP_Addr,
		Bus2IP_Data => M_Bus2IP_Data,
		Bus2IP_RNW  => M_Bus2IP_RNW,
		Bus2IP_BE   => M_Bus2IP_BE,
		Bus2IP_CS   => M_Bus2IP_CS(0),

		IPIF_BUSY   => ipif_busy,
		IPIF_READ   => ipif_read,
		IPIF_DONE   => ipif_done
	);

	ipif_mon_i : entity work.ipif_monitor
	generic map (
		DWIDTH      => 32		
	)
	port map (
		CLK => M_CLK,
		RST => M_RST,

		IP2Bus_Data  => M_IP2Bus_Data,
		IP2Bus_WrAck => M_IP2Bus_WrAck,
		IP2Bus_RdAck => M_IP2Bus_RdAck,
		IP2Bus_Error => M_IP2Bus_Error,

		IPIF_BUSY => ipif_busy,
		IPIF_READ => ipif_read,
		IPIF_DONE => ipif_done		
	);

	async_ipif_i : entity work.async_ipif
	generic map (
		AWIDTH => 32,
		DWIDTH => 32,
		NADDR  => 1		
	)
	port map (
		M_CLK          => M_CLK,
		M_RST          => M_RST,
		M_IP2Bus_Data  => M_IP2Bus_Data,
		M_IP2Bus_WrAck => M_IP2Bus_WrAck,
		M_IP2Bus_RdAck => M_IP2Bus_RdAck,
		M_IP2Bus_Error => M_IP2Bus_Error,
		M_Bus2IP_Addr  => M_Bus2IP_Addr,
		M_Bus2IP_Data  => M_Bus2IP_Data,
		M_Bus2IP_RNW   => M_Bus2IP_RNW,
		M_Bus2IP_BE    => M_Bus2IP_BE,
		M_Bus2IP_CS    => M_Bus2IP_CS,

		S_CLK          => S_CLK,
		S_RST          => S_RST,
		S_IP2Bus_Data  => S_IP2Bus_Data,
		S_IP2Bus_WrAck => S_IP2Bus_WrAck,
		S_IP2Bus_RdAck => S_IP2Bus_RdAck,
		S_IP2Bus_Error => S_IP2Bus_Error,
		S_Bus2IP_Addr  => S_Bus2IP_Addr,
		S_Bus2IP_Data  => S_Bus2IP_Data,
		S_Bus2IP_RNW   => S_Bus2IP_RNW,
		S_Bus2IP_BE    => S_Bus2IP_BE,
		S_Bus2IP_CS    => S_Bus2IP_CS
	);

	dut_i : entity work.ipif_reg
	generic map (
		REG_DWIDTH  => 32,
		REG_DEFAULT => X"00000000",
		IPIF_DWIDTH => 32,
		IPIF_MODE   => IPIF_RW
	)
	port map (
		CLK  => S_CLK,
		RST  => S_RST,

		IP2Bus_Data  => S_IP2Bus_Data,
		IP2Bus_WrAck => S_IP2Bus_WrAck,
		IP2Bus_RdAck => S_IP2Bus_RdAck,
		IP2Bus_Error => S_IP2Bus_Error,

		Bus2IP_Data  => S_Bus2IP_Data,
		Bus2IP_BE    => S_Bus2IP_BE,
		Bus2IP_RNW   => S_Bus2IP_RNW,
		Bus2IP_CS    => S_Bus2IP_CS(0),
		
		REG_DO       => open,
		REG_WE       => '0',
		REG_DI       => (others => 'X')
	);

	clkgenp : process
	begin
		clk <= '1';
		wait for PERIOD / 2;
		clk <= '0';
		wait for PERIOD / 2;
	end process;

	rstgenp : process
	begin
		rst <= '1';
		wait for 4 * PERIOD;
		wait until rising_edge(clk);
		rst <= '0';
		wait;
	end process;

	clk_slow_genp : process
	begin
		clk_slow <= '1';
		wait for PERIOD_SLOW / 2;
		clk_slow <= '0';
		wait for PERIOD_SLOW / 2;
	end process;

	rst_slow_genp : process
	begin
		rst_slow <= '1';
		wait for 4 * PERIOD_SLOW;
		wait until rising_edge(clk_slow);
		rst_slow <= '0';
		wait;
	end process;


end architecture;

