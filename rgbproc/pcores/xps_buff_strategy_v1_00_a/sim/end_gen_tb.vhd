-- end_gen_tb.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.math_real.uniform;

entity end_gen_tb is
end entity;

architecture testbench of end_gen_tb is

	constant FREQ   : real := 100.0;
	constant PERIOD : time := 1 us / FREQ;

	constant WIDTH  : integer := 640;
	constant HEIGHT : integer := 480;

	signal clk      : std_logic;
	signal rst      : std_logic;

	signal px_vld   : std_logic;
	signal out_eol  : std_logic;
	signal out_eof  : std_logic;

	-- from ISE
	shared variable seed0 : integer := 844396720;
	shared variable seed1 : integer := 821616997;

	impure function getrand return boolean is
		variable r : real;
	begin
		uniform(seed0, seed1, r);
		return r < 0.5;
	end function;

begin

	dut_i : entity work.end_gen
	generic map (
		WIDTH  => WIDTH,
		HEIGHT => HEIGHT
	)
	port map (
		CLK => clk,
		RST => rst,

		PX_VLD  => px_vld,
		OUT_EOL => out_eol,
		OUT_EOF => out_eof
	);

	---------------------------
	
	---
	-- Generate pixels valid at random.
	-- Generate much more valid pixels then invalid ones.
	-- Probability of invalid pixel is higher on EOL or EOF.
	---
	process(clk, rst)
		variable curr : boolean;
		variable last : boolean;
	begin
		if rising_edge(clk) then
			curr := getrand;

			if rst = '1' then
				last := getrand;
				px_vld <= '0';
			elsif curr and last and out_eol = '0' and out_eof = '0' then
				px_vld <= '1';
				last := true;
			elsif curr and last and out_eol = '0' and out_eof = '0' then
				px_vld <= '1';
				last := true;
			elsif curr and not last and out_eol = '0' and out_eof = '0' then
				px_vld <= '1';
				last := true;
			elsif not curr and not last then
				px_vld <= '1';
				last := true;
			elsif getrand then
				px_vld <= '0';
				last := false;
			end if;
		end if;
	end process;
	
	---------------------------

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

