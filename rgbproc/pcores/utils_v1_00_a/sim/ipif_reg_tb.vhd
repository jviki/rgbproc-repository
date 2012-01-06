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
	constant FREQ     : real := 25.0;
	constant PERIOD   : time := BASE_MHZ / FREQ;

	signal clk     : std_logic;
	signal rst     : std_logic;

	signal IP2Bus_Data  : std_logic_vector(31 downto 0);
	signal IP2Bus_WrAck : std_logic;
	signal IP2Bus_RdAck : std_logic;
	signal IP2Bus_Error : std_logic;
	signal Bus2IP_Data  : std_logic_vector(31 downto 0);
	signal Bus2IP_BE    : std_logic_vector(3 downto 0);
	signal Bus2IP_RNW   : std_logic;
	signal Bus2IP_CS    : std_logic;

	signal ipif_busy    : std_logic;
	signal ipif_done    : std_logic;

begin

	ipif_gen_i : entity work.ipif_generator
	generic map (
		DWIDTH   => 32,
		AWIDTH   => 32,
		ADDR_MIN =>  0,
		ADDR_MAX =>  1
	)
	port map (
		CLK => clk,
		RST => rst,

		Bus2IP_Addr => open,
		Bus2IP_Data => Bus2IP_Data,
		Bus2IP_RNW  => Bus2IP_RNW,
		Bus2IP_BE   => Bus2IP_BE,
		Bus2IP_CS   => Bus2IP_CS,

		IPIF_BUSY   => ipif_busy,
		IPIF_DONE   => ipif_done
	);

	ipif_mon_i : entity work.ipif_monitor
	generic map (
		DWIDTH      => 32		
	)
	port map (
		CLK => clk,
		RST => rst,

		IP2Bus_Data  => IP2Bus_Data,
		IP2Bus_WrAck => IP2Bus_WrAck,
		IP2Bus_RdAck => IP2Bus_RdAck,
		IP2Bus_Error => IP2Bus_Error,

		IPIF_BUSY => ipif_busy,
		IPIF_DONE => ipif_done		
	);

	dut_i : entity work.ipif_reg
	generic map (
		REG_DWIDTH  => 32,
		REG_DEFAULT => 0,
		IPIF_DWIDTH => 32,
		IPIF_MODE   => IPIF_RW
	)
	port map (
		CLK  => clk,
		RST  => rst,

		IP2Bus_Data  => IP2Bus_Data,
		IP2Bus_WrAck => IP2Bus_WrAck,
		IP2Bus_RdAck => IP2Bus_RdAck,
		IP2Bus_Error => IP2Bus_Error,

		Bus2IP_Data  => Bus2IP_Data,
		Bus2IP_BE    => Bus2IP_BE,
		Bus2IP_RNW   => Bus2IP_RNW,
		Bus2IP_CS    => Bus2IP_CS,
		
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

end architecture;

