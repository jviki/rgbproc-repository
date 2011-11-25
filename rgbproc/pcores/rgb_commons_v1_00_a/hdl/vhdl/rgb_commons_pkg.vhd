-- rgb_commons_pkg.vhd

library ieee;
use ieee.std_logic_1164.all;

package rgb_commons_pkg is

	---
	-- Counts OR over the given vector.
	---
	function or_over(vec : std_logic_vector) return std_logic;

end package;

package body rgb_commons_pkg is

	function or_over(vec : std_logic_vector) return std_logic is
		variable o : std_logic;
		variable i : integer;
	begin
		o := '0';

		for i in vec'range loop
			o := o or vec(i);	
		end loop;

		return o;
	end function;

end package body;

