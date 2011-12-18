-- rgb_filter_pkg.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

package rgb_filter_pkg is

	constant OP_AND : integer := 0;
	constant OP_OR  : integer := 1;
	constant OP_XOR : integer := 2;

end package;

