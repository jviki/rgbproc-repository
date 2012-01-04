-- afifo.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity afifo is
generic (
	DWIDTH : integer := 8;
	DEPTH  : integer := 16
);
port (
	WCLK  : in  std_logic;
	RCLK  : in  std_logic;
	RESET : in  std_logic;

	WE    : in  std_logic;
	FULL  : out std_logic;
	DI    : in  std_logic_vector(DWIDTH - 1 downto 0);

	RE    : in  std_logic;
	EMPTY : out std_logic;
	DO    : out std_logic_vector(DWIDTH - 1 downto 0)
);
end entity;

architecture full of afifo is
begin

end architecture;
