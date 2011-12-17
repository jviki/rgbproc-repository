-- idf_encoding.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity idf_encoding is
port (
	RED   : in  std_logic_vector(7 downto 0);
	GREEN : in  std_logic_vector(7 downto 0);
	BLUE  : in  std_logic_vector(7 downto 0);
	D0    : out std_logic_vector(11 downto 0);
	D1    : out std_logic_vector(11 downto 0)
);
end entity;

architecture idf0 of idf_encoding is
begin

	D0(11 downto 8) <= GREEN(3 downto 0);
	D0(7 downto 0)  <= BLUE(7 downto 0);

	D1(11 downto 4) <= RED(7 downto 0);
	D1(3 downto 0)  <= GREEN(7 downto 4);

end architecture;

