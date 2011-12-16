-- rgb_filter.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity rgb_filter is
generic (
	OPERATION : integer := 0		
);
port (
	CLK    : in  std_logic;
	RST    : in  std_logic;
	CE     : in  std_logic;

	IN_R   : in  std_logic;
	IN_G   : in  std_logic;
	IN_B   : in  std_logic;
	IN_DE  : in  std_logic;
	IN_HS  : in  std_logic;
	IN_VS  : in  std_logic;

	OUT_R  : out std_logic;
	OUT_G  : out std_logic;
	OUT_B  : out std_logic;
	OUT_DE : out std_logic;
	OUT_HS : out std_logic;
	OUT_VS : out std_logic
);
end entity;

architecture full of rgb_filter is
begin

end architecture;

