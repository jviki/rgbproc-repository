-- buffer_mem_tb.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.log2;

entity buffer_mem_tb is
end entity;

architecture testbench of buffer_mem_tb is

	constant FREQ     : real := 100.0;
	constant PERIOD   : time := 1 us / FREQ;
	constant BUFF_CAP : integer := 640 * 480;
	constant WADDR    : integer := log2(BUFF_CAP);

	signal clk      : std_logic;
	signal rst      : std_logic;

	signal m_wea    : std_logic;
	signal m_addra  : std_logic_vector(WADDR - 1 downto 0);
	signal m_dina   : std_logic_vector(7 downto 0);
	signal m_douta  : std_logic_vector(7 downto 0);

begin

	mem_i : entity work.buffer_mem(bram_model)
	generic map (
		CAPACITY => BUFF_CAP,
		DWIDTH   => 8
	)
	port map (
		CLKA     => clk,
		ADDRA    => m_addra,
		DINA     => m_dina,
		DOUTA    => m_douta,
		WEA      => m_wea,

		CLKB     => clk,
		ADDRB    => (others => '0'),
		DINB     => (others => '0'),
		DOUTB    => open,
		WEB      => '0'
	);

	-------------------------
	
	mema : process
	begin
		m_wea <= '0';
		wait until rst = '0';
		wait until rising_edge(clk);

		m_addra <= "000" & X"0000";
		m_dina  <= X"FF";
		m_wea   <= '1';
		wait until rising_edge(clk);

		m_addra <= "000" & X"0001";
		m_dina  <= X"EE";
		m_wea   <= '1';
		wait until rising_edge(clk);

		m_addra <= "000" & X"0002";
		m_dina  <= X"DD";
		m_wea   <= '1';
		wait until rising_edge(clk);
	end process;
	
	-------------------------

	clkgen_i : process
	begin
		clk <= '0';
		wait for PERIOD / 2;
		clk <= '1';
		wait for PERIOD / 2;
	end process;

	rstgen_i : process
	begin
		rst <= '1';
		wait for 32 * PERIOD;
		rst <= '0';
		wait;
	end process;


end architecture;

