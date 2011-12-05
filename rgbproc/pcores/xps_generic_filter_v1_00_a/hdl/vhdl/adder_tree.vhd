-- adder_tree.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity adder_tree is
generic (
	INPUT_COUNT : integer := 9
);
port (
	CLK  : in  std_logic;
	CE   : in  std_logic;
	DIN  : in  std_logic_vector(INPUT_COUNT * 8 - 1 downto 0);
	DOUT : out std_logic_vector(7 downto 0)	
);
end entity;

architecture full of adder_tree is

	constant LEFT_COUNT  : integer := INPUT_COUNT / 2 + INPUT_COUNT mod 2;
	constant RIGHT_COUNT : integer := INPUT_COUNT / 2;

	constant LEFT_BEG    : integer := INPUT_COUNT;
	constant LEFT_END    : integer := INPUT_COUNT - LEFT_COUNT;

	constant RIGHT_BEG   : integer := LEFT_END;
	constant RIGHT_END   : integer := 0;

	signal left_din   : std_logic_vector(LEFT_COUNT  * 8 - 1 downto 0);
	signal right_din  : std_logic_vector(RIGHT_COUNT * 8 - 1 downto 0);
	signal left_dout  : std_logic_vector(7 downto 0);
	signal right_dout : std_logic_vector(7 downto 0);

begin

	assert INPUT_COUNT > 0
		report "INPUT_COUNT must be greater then 0 to make sense"
		severity failure;

	assert RIGHT_BEG - RIGHT_END = RIGHT_COUNT
		report "BUG: invalid RIGHT_* computation for " & integer'image(INPUT_COUNT) & " inputs"
		severity failure;

	assert LEFT_BEG - LEFT_END = LEFT_COUNT
		report "BUG: invalid LEFT_* computation for " & integer'image(INPUT_COUNT) & " inputs"
		severity failure;

	---------------------------------------

gen_register: if INPUT_COUNT = 1
generate

	add_op : process(CLK, DIN, CE)
	begin
		if rising_edge(CLK) then
			if CE = '1' then
				DOUT <= DIN;
			end if;
		end if;
	end process;

end generate;

	---------------------------------------

gen_simple_add: if INPUT_COUNT = 2
generate

	add_op : process(CLK, DIN, CE)
	begin
		if rising_edge(CLK) then
			if CE = '1' then
				DOUT <= DIN(7 downto 0) + DIN(15 downto 8);
			end if;
		end if;
	end process;

end generate;

	---------------------------------------

gen_tree: if INPUT_COUNT > 2
generate
	left_i : entity work.adder_tree(full)
	generic map (
		INPUT_COUNT => LEFT_COUNT
	)
	port map (
		CLK  => CLK,
		CE   => CE,
		DIN  => left_din,
		DOUT => left_dout
	);

	left_din <= DIN(LEFT_BEG * 8 - 1 downto LEFT_END * 8);

	--------------------

	right_i : entity work.adder_tree
	generic map (
		INPUT_COUNT => RIGHT_COUNT
	)
	port map (
		CLK  => CLK,
		CE   => CE,
		DIN  => right_din,
		DOUT => right_dout
	);

	right_din <= DIN(RIGHT_BEG * 8 - 1 downto RIGHT_END * 8);

	--------------------

	add_levels : process(CLK, left_dout, right_dout, CE)
	begin
		if rising_edge(CLK) then
			if CE = '1' then
				DOUT <= left_dout + right_dout;
			end if;
		end if;
	end process;

end generate;

end architecture;

