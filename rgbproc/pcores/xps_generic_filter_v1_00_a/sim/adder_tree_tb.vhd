-- adder_tree_tb.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity adder_tree_tb is
end entity;

architecture testbench of adder_tree_tb is

	constant FREQ       : real := 100.0;
	constant PERIOD     : time := 1 us / FREQ;

	constant INPUT_COUNT : integer := 9;

	signal clk          : std_logic;
	signal rst          : std_logic;

	signal ce           : std_logic;
	signal datain       : std_logic_vector(INPUT_COUNT * 8 - 1 downto 0);
	signal result       : std_logic_vector(7 downto 0);

begin

	dut_i : entity work.adder_tree(full)
	generic map (
		INPUT_COUNT => INPUT_COUNT		
	)
	port map (
		CLK => clk,
		CE  => ce,
		DIN => datain,
		DOUT => result		
	);

	---------------------------

	gen_datain : process
		variable sum : integer;
	begin
		ce <= '0';
		wait until rst = '0';
		wait until rising_edge(clk);

		sum := 0;
		report "Sum of:";
		for i in 1 to INPUT_COUNT loop
			report integer'image(i);
			sum := sum + i;
			datain(i * 8 - 1 downto (i - 1) * 8) <= conv_std_logic_vector(i, 8);
		end loop;

		ce <= '1';
		wait until rising_edge(clk);
		wait until result /= (result'range => 'X');

		report "is: " & integer'image(conv_integer(result)) & " (should be " & integer'image(sum) & ")";
		assert sum = result
			report "Incorrect sum counted by adder_tree"
			severity failure;

		wait;
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

