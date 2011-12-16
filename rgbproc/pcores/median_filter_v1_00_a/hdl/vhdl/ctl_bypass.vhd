-- ctl_bypass.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity ctl_bypass is
generic (
	DWIDTH : integer := 3;
	DEPTH  : integer := 9
);
port (
	CLK    : in  std_logic;
	CE     : in  std_logic;
	DI     : in  std_logic_vector(DWIDTH - 1 downto 0);
	DO     : in  std_logic_vector(DWIDTH - 1 downto 0)
);
end entity;

architecture full of ctl_bypass is

	type shreg_t is array(0 to DEPTH - 1) of std_logic_vector(DWIDTH - 1 downto 0);
	signal shreg : shreg_t;

begin

	shregp : process(CLK, CE, DI)
	begin
		if rising_edge(CLK) then
			if CE = '1' then
				shreg(0) <= DI;

				for i in 1 to DEPTH - 1 loop
					shreg(i) <= shreg(i - 1);
				end loop;
			end if;
		end if;
	end process;

end architecture;
