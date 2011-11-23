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

	constant WIDTH    : integer := 640;
	constant HEIGHT   : integer := 480;
	constant BUFF_CAP : integer := WIDTH * HEIGHT;
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
	signal out_eol  : std_logic;
	signal out_eof  : std_logic;

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
		WIDTH  => WIDTH,
		HEIGHT => HEIGHT
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
		OUT_EOF  => out_eof,
		OUT_EOL  => out_eol,

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

	data_in : process(CLK, RST, in_rdy)
		variable i : integer;
	begin
		if rising_edge(CLK) then
			if i >= BUFF_CAP - 1 then
				in_done <= '1';
				in_we   <= '0';
			end if;
			
			if RST = '1' or in_rdy = '0' then
				i := 0;
				in_done <= '0';
				in_we   <= '0';
			elsif in_rdy = '1' then
				in_d( 7 downto  0) <= conv_std_logic_vector(i mod 256, 8);
				in_d(15 downto  8) <= conv_std_logic_vector((i * 2) mod 256, 8);
				in_d(23 downto 16) <= conv_std_logic_vector((i / 2) mod 256, 8);

				if i <= BUFF_CAP - 1 then
					in_we <= not in_full;
				else
					in_we <= '0';
				end if;

				if in_full = '0' then
					i := i + 1;
				end if;
			end if;
		end if;
	end process;

	data_out : process(CLK, RST, out_rdy)
		variable i : integer;
	begin
		if rising_edge(CLK) then
			if i = BUFF_CAP - 1 then
				assert out_eof = '1'
					report "Missing EOL"
					severity error;
			end if;

			if out_empty = '1' then
				out_done <= '1';
				out_re   <= '0';
			end if;

			if RST = '1' or out_rdy = '0' then
				out_done <= '0';
				out_re   <= '0';
				i := 0;
			elsif out_rdy = '1' then
				out_re <= not out_empty;

				if out_empty = '0' then
					i := i + 1;
				end if;
			end if;
		end if;
	end process;

	mem_done <= '1';
	m0_re    <= '0';
	m0_we    <= '0';
	m1_re    <= '0';
	m1_we    <= '0';

	assert (in_rdy = '1' and out_rdy = '0' and mem_rdy = '0')
            or (in_rdy = '0' and out_rdy = '1' and mem_rdy = '0')
	    or (in_rdy = '0' and out_rdy = '0' and mem_rdy = '1')
	    or (in_rdy = '0' and out_rdy = '0' and mem_rdy = '0')
	    	report "Invalid RDY signals combination"
		severity error;

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

