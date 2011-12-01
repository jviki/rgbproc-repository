-- line4_buff_tb.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.log2;

entity line4_buff_tb is
end entity;

architecture testbench of line4_buff_tb is

	constant LINE_WIDTH   : integer := 32;
	constant RATIO_OUT_IN : integer := 2;

	constant IN_FREQ    : real := 50.0;
	constant IN_PERIOD  : time := 1 us / IN_FREQ;

	constant OUT_FREQ   : real := IN_FREQ * real(RATIO_OUT_IN);
	constant OUT_PERIOD : time := 1 us / OUT_FREQ;

	signal in_clk       : std_logic;
	signal in_rst       : std_logic;

	signal out_clk      : std_logic;
	signal out_rst      : std_logic;

	signal in_r         : std_logic_vector(7 downto 0);
	signal in_g         : std_logic_vector(7 downto 0);
	signal in_b         : std_logic_vector(7 downto 0);
	signal in_vld       : std_logic;
	signal in_req       : std_logic;

	signal out_r        : std_logic_vector(31 downto 0);
	signal out_g        : std_logic_vector(31 downto 0);
	signal out_b        : std_logic_vector(31 downto 0);
	signal out_mark     : std_logic_vector(3 downto 0);
	signal out_mask     : std_logic_vector(3 downto 0);
	signal out_addr     : std_logic_vector(log2(LINE_WIDTH) - 1 downto 0);

begin

	dut_i : entity work.line4_buff
	generic map (
		LINE_WIDTH   => LINE_WIDTH,
		RATIO_OUT_IN => RATIO_OUT_IN
	)
	port map (
		IN_CLK     => in_clk,
		IN_RST     => in_rst,

		IN_R       => in_r,
		IN_G       => in_g,
		IN_B       => in_b,
		IN_EOL     => '0',
		IN_EOF     => '0',
		IN_VLD     => in_vld,
		IN_REQ     => in_req,

		OUT_CLK    => out_clk,
		OUT_RST    => out_rst,
		OUT_R      => out_r,
		OUT_G      => out_g,
		OUT_B      => out_b,
		OUT_MASK   => out_mask,
		OUT_MARK   => out_mark,
		OUT_ADDR   => out_addr
	);

	---------------------------

	gen_rgb_data : process(in_clk, in_req)
		variable i : integer;
	begin
		if rising_edge(in_clk) then
			if in_rst = '1' then
				i := 0;
			elsif in_req = '1' then
				i := i + 1;
			end if;

			in_r <= conv_std_logic_vector(i, in_r'length);
			in_g <= conv_std_logic_vector(i, in_g'length);
			in_b <= conv_std_logic_vector(i, in_b'length);
		end if;
	end process;

	---------------------------

	gen_in_vld : process(in_clk, IN_RST)
	begin
		if rising_edge(in_clk) then
			in_vld <= not IN_RST;
		end if;
	end process;

	---------------------------

	read_data : process
	begin
		out_addr <= (others => '0');
		out_mark <= (others => '0');

		wait until out_mask(0) = '1';
		wait until out_mask(1) = '1';
		wait until rising_edge(out_clk);

		for i in 0 to LINE_WIDTH - 1 loop
			out_addr <= conv_std_logic_vector(i, out_addr'length);
			wait until rising_edge(out_clk);
		end loop;

		-----------------------------

		for j in 2 to 128 loop
			wait until out_mask(j mod 4) = '1';

			for i in 0 to LINE_WIDTH - 1 loop
				out_addr <= conv_std_logic_vector(i, out_addr'length);
				wait until rising_edge(out_clk);
			end loop;

			out_mark((j - 2) mod 4) <= '1';
			wait until rising_edge(out_clk);
			wait until rising_edge(out_clk);
			wait until rising_edge(out_clk);
			out_mark((j - 2) mod 4) <= '0';

			if j mod 8 = 0 then
				out_addr <= (others => 'X');

				for k in 1 to LINE_WIDTH loop
					wait until rising_edge(in_clk);
				end loop;

				wait until rising_edge(out_clk);
			end if;
		end loop;

		wait;
	end process;

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

