-- median9.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity median9 is
port (
	CLK : in  std_logic;
	CE  : in  std_logic;
	DI  : in  std_logic_vector(9 * 8 - 1 downto 0);
	DO  : out std_logic_vector(7 downto 0)
);
end entity;

architecture sort9 of median9 is

	component sort9 is
	port (
		CLK : in  std_logic;
		CE  : in  std_logic;
		DI  : in  std_logic_vector(9 * 8 - 1 downto 0);
		DO  : out std_logic_vector(9 * 8 - 1 downto 0)
	);
	end component;

	signal sorted_data : std_logic_vector(9 * 8 - 1 downto 0);

begin

	sorter_i : sort9
	port map (
		CLK => CLK,
		CE  => CE,
		DI  => DI,
		DO  => sorted_data
	);

	DO <= sorted_data(39 downto 32); -- median		

end architecture;

