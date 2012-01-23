-- utils_pkg.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>
-- Copyright (C) 2011, 2012 Jan Viktorin

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

package utils_pkg is

	constant IPIF_RO : integer := 0;
	constant IPIF_WO : integer := 1;
	constant IPIF_RW : integer := 2;

	function width_of_be(dwidth : in integer) return integer;

end package;

package body utils_pkg is

	function width_of_be(dwidth : in integer) return integer is
		variable bwidth : integer;
		variable brest  : integer;
	begin
		assert dwidth > 0
			report "Invalid dwidth, must be greater then zero"
			severity failure;

		brest  := dwidth mod 8;

		if brest = 0 then
			bwidth := dwidth / 8;
		else
			bwidth := dwidth / 8 + 1;
		end if;

		return bwidth;
	end function;

end package body;

