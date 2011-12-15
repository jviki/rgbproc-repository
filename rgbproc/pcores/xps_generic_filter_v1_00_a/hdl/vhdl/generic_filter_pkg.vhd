-- generic_filter_pkg.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

package generic_filter_pkg is

	constant FILTER_MEDIAN : integer := 0;
	constant FILTER_SHIFT  : integer := 1;

end package;

