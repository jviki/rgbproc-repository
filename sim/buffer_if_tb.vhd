-- buffer_if_tb.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.log2;

entity buffer_if_tb is
end entity;

architecture testbench of buffer_if_tb is

	constant BUFF_CAP : integer := 640 * 480;
	constant WADDR    : integer := log2(BUFF_CAP);

	constant FREQ     : real := 100.0;
	constant PERIOD   : time := 1 us / FREQ;

	signal clk      : std_logic;
	signal rst      : std_logic;

	signal in_done  : std_logic;
	signal in_rdy   : std_logic;
	signal out_done : std_logic;
	signal out_rdy  : std_logic;
	signal mem_done : std_logic;
	signal mem_rdy  : std_logic;

	signal in_d     : std_logic_vector(23 downto 0);
	signal in_we    : std_logic;
	signal in_full  : std_logic;

	signal out_d    : std_logic_vector(23 downto 0);
	signal out_re   : std_logic;
	signal out_empty : std_logic;

	signal m0_a     : std_logic_vector(WADDR - 1 downto 0);
	signal m0_do    : std_logic_vector(23 downto 0);
	signal m0_di    : std_logic_vector(23 downto 0);
	signal m0_we    : std_logic;
	signal m0_re    : std_logic;
	signal m0_drdy  : std_logic;

	signal m1_a     : std_logic_vector(WADDR - 1 downto 0);
	signal m1_do    : std_logic_vector(23 downto 0);
	signal m1_di    : std_logic_vector(23 downto 0);
	signal m1_we    : std_logic;
	signal m1_re    : std_logic;
	signal m1_drdy  : std_logic;
	signal mem_size : std_logic_vector(WADDR - 1 downto 0);

begin

	dut_i : entity work.buffer_if
	generic map (
		BUFF_CAP => BUFF_CAP
	)
	port map (
		CLK => clk,
		RST => rst,

		IN_DONE  => in_done,
		IN_RDY   => in_rdy,
		OUT_DONE => out_done,
		OUT_RDY  => out_rdy,
		MEM_DONE => mem_done,
		MEM_RDY  => mem_rdy,

		IN_D     => in_d,
		IN_WE    => in_we,
		IN_FULL  => in_full,

		OUT_D    => out_d,
		OUT_RE   => out_re,
		OUT_EMPTY => out_empty,

		M0_A     => m0_a,
		M0_DO    => m0_do,
		M0_WE    => m0_we,
		M0_DI    => m0_di,
		M0_RE    => m0_re,
		M0_DRDY  => m0_drdy,
			
		M1_A     => m1_a,
		M1_DO    => m1_do,
		M1_WE    => m1_we,
		M1_DI    => m1_di,
		M1_RE    => m1_re,
		M1_DRDY  => m1_drdy,
			
		MEM_SIZE => mem_size
	);

	-------------------------

	test : process
	begin
		in_done  <= '0';
		out_done <= '0';
		mem_done <= '0';

		in_d   <= (others => 'X');
		in_we  <= '0';
		out_re <= '0';

		m0_a   <= (others => 'X');
		m0_we  <= '0';
		m0_di  <= (others => 'X');
		m0_re  <= '0';

		m1_a   <= (others => 'X');
		m1_we  <= '0';
		m1_di  <= (others => 'X');
		m1_re  <= '0';

		wait until rst = '0';
		wait until rising_edge(clk);

		for i in 1 to 16 loop
			assert in_rdy = '1'
				report "IN interface is not ready"
				severity error;

			assert mem_rdy = '0'
				report "MEM interface is ready, must not be"
				severity error;

			assert out_rdy = '0'
				report "OUT interface is ready, must not be"
				severity error;

			in_d( 7 downto  0) <= conv_std_logic_vector(i mod 256, 8);
			in_d(15 downto  8) <= conv_std_logic_vector((i * 2) mod 256, 8);
			in_d(23 downto 16) <= conv_std_logic_vector((i / 2) mod 256, 8);
			in_we <= not in_full;
			wait until rising_edge(clk);
		end loop;

		assert in_full = '1'
			report "IN interface is not full"
			severity error;

		in_we <= '0';
		wait until rising_edge(clk);

		in_done <= '1';
		wait until rising_edge(clk);

		for i in 1 to 16 loop
			assert in_rdy = '0'
				report "IN interface is ready, must not be"
				severity error;

			assert mem_rdy = '1'
				report "MEM interface is not ready"
				severity error;

			assert out_rdy = '0'
				report "OUT interface is ready, must not be"
				severity error;

			m0_a  <= conv_std_logic_vector(i, m0_a'length);
			m0_re <= '1';

			m1_a  <= conv_std_logic_vector(16 - i, m1_a'length);
			m1_re <= '1';

			wait until rising_edge(clk);
		end loop;

		m0_re <= '0';
		m1_re <= '0';
		mem_done <= '1';
		wait until rising_edge(clk);
		wait until out_rdy = '1';
		wait until rising_edge(clk);

		while out_empty = '0' loop
			assert in_rdy = '0'
				report "IN interface is ready, must not be"
				severity error;

			assert mem_rdy = '0'
				report "MEM interface is ready, must not be"
				severity error;

			assert out_rdy = '1'
				report "OUT interface is not ready"
				severity error;

			out_re <= not out_empty and out_rdy;
			wait until rising_edge(clk);
		end loop;

		out_done <= '1';
		out_re   <= '0';
		wait until rising_edge(clk);

		assert in_rdy = '1'
			report "IN interface is not ready"
			severity error;

		wait;
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

