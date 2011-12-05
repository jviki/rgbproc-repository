-- bypass_shreg.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity bypass_shreg is
generic (
	LINE_DEPTH : integer
);
port (
	CLK : in  std_logic;
	CE  : in  std_logic;
	DI  : in  std_logic_vector(23 downto 0);
	DO  : out std_logic_vector(23 downto 0)
);
end entity;

architecture by_array of bypass_shreg is

	type shreg_t is array (0 to LINE_DEPTH - 1) of std_logic_vector(23 downto 0);

	signal shreg     : shreg_t;
	signal shreg_ce  : std_logic;
	signal shreg_in  : std_logic_vector(23 downto 0);
	signal shreg_out : std_logic_vector(23 downto 0);

begin

	shreg_in <= DI;
	DO <= shreg_out;

	shreg_ce <= CE;

	---------------------------------

	shregp : process(CLK, shreg_ce, shreg_in)
	begin
		if rising_edge(CLK) then
			if shreg_ce = '1' then
				for i in shreg'range loop
					if i = 0 then
						shreg(0) <= shreg_in;
					else
						shreg(i) <= shreg(i - 1);
					end if;
				end loop;
			end if;
		end if;
	end process;

	---------------------------------

	shreg_out <= shreg(shreg'length - 1);

end architecture;

