-- synchronizer.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity synchronizer is
port (
	CLKA : in  std_logic;
	CLKB : in  std_logic;
	DA   : in  std_logic;
	DB   : out std_logic
);
end entity;

architecture full of synchronizer is

	signal rega_in : std_logic;
	signal regb_0  : std_logic;

begin

	rega_inp : process(CLKA, DA)
	begin
		if rising_edge(CLKA) then
			rega_in <= DA;
		end if;	
	end process;

	regb_0p : process(CLKB, rega_in)
	begin
		if rising_edge(CLKB) then
			regb_0 <= rega_in;
		end if;
	end process;

	regb_1p : process(CLKB, regb_0)
	begin
		if rising_edge(CLKB) then
			DB <= regb_0;
		end if;
	end process;

end architecture;

