-- line_buff_tb.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.log2;

entity line_buff_tb is
end entity;

architecture testbench of line_buff_tb is

	constant LINE_WIDTH   : integer := 128;
	constant RATIO_OUT_IN : integer := 2;

	constant IN_FREQ    : real := 50.0;
	constant IN_PERIOD  : time := 1 us / IN_FREQ;

	constant OUT_FREQ   : real := IN_FREQ * RATIO_OUT_IN;
	constant OUT_PERIOD : time := 1 us / OUT_FREQ;

	signal in_clk       : std_logic;
	signal in_rst       : std_logic;

	signal out_clk      : std_logic;
	signal out_rst      : std_logic;

	signal in_r         : std_logic_vector(7 downto 0);
	signal in_g         : std_logic_vector(7 downto 0);
	signal in_b         : std_logic_vector(7 downto 0);
	signal in_we        : std_logic;
	signal in_full      : std_logic;
	signal mark_full    : std_logic;

	signal out_r        : std_logic_vector(7 downto 0);
	signal out_g        : std_logic_vector(7 downto 0);
	signal out_b        : std_logic_vector(7 downto 0);
	signal out_addr     : std_logic_vector(log2(LINE_WIDTH) - 1 downto 0);
	signal out_full     : std_logic;
	signal mark_empty   : std_logic;

begin

	dut_i : entity work.line_buff
	generic map (
		LINE_WIDTH   => LINE_WIDTH,
		RATIO_OUT_IN => RATIO_OUT_IN
	)
	port map (
		IN_CLK     => in_clk,
		IN_RST     => in_rst,

		IN_R       => in_r,
		IN_G       => in_g,
		IN_B       => in_b
		IN_WE      => in_we,
		IN_FULL    => in_full,
		MARK_FULL  => mark_full,

		OUT_CLK    => out_clk,
		OUT_RST    => out_rst,
		OUT_R      => out_r,
		OUT_G      => out_g,
		OUT_B      => out_b,
		OUT_ADDR   => out_addr,
		OUT_FULL   => out_full,
		MARK_EMPTY => mark_empty
	);

	---------------------------

	gen_rgb_data : process(in_clk)
		variable i : integer;
	begin
		if rising_edge(in_clk) then
			if in_rst = '1' then
				i := 0;
			elsif in_we = '1' then
				i := i + 1;
				in_r <= conv_std_logic_vector(i, in_r'length);
				in_g <= conv_std_logic_vector(i, in_g'length);
				in_b <= conv_std_logic_vector(i, in_b'length);
			end if;
		end if;
	end process;

	---------------------------

	in_we <= not in_full;

	out_addr   <= conv_std_logic_vector(0, out_addr'length);
	mark_empty <= '0';

	---------------------------

	out_clkgen_i : process
	begin
		out_clk <= '0';
		wait for OUT_PERIOD / 2;
		out_clk <= '1';
		wait for OUT_PERIOD / 2;
	end process;

	out_rstgen_i : process
	begin
		out_rst <= '1';
		wait for 32 * OUT_PERIOD;
		out_rst <= '0';
		wait;
	end process;

	in_clkgen_i : process
	begin
		in_clk <= '0';
		wait for IN_PERIOD / 2;
		in_clk <= '1';
		wait for IN_PERIOD / 2;
	end process;

	in_rstgen_i : process
	begin
		in_rst <= '1';
		wait for 32 * IN_PERIOD;
		in_rst <= '0';
		wait;
	end process;

end architecture;

