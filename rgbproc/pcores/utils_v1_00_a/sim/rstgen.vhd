-- rstgen.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>
-- Copyright (C) 2011, 2012 Jan Viktorin

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity rstgen is
generic (
	CYCLES : integer := 16
);
port (
	CLK : in  std_logic;
	RST : out std_logic
);
end entity;

architecture full of rstgen is

	signal cnt_clk : integer := 0;

begin

	cnt_clkp : process(CLK)
	begin
		if rising_edge(CLK) then
			cnt_clk <= cnt_clk + 1;
		end if;
	end process;

	RST <= '1' when cnt_clk < CYCLES else '0';

end architecture;
