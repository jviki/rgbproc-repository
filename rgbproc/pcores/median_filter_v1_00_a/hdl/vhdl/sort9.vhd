-- sort9.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>
-- Copyright (C) 2011, 2012 Jan Viktorin

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity sort9 is
port (
	CLK : in  std_logic;
	CE  : in  std_logic;
	DI  : in  std_logic_vector(9 * 8 - 1 downto 0);
	DO  : out std_logic_vector(9 * 8 - 1 downto 0)
);
end entity;

architecture bitonic9 of sort9 is
begin

	bitonic9 : entity work.bitonic_sort9
	port map (
		CLK => CLK,
		CE  => CE,
		DI  => DI,
		DO  => DO
	);

end architecture;

