-- rgb_filter.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

use work.rgb_filter_pkg.all;

entity rgb_filter is
generic (
	OPERATION : integer := OP_AND
);
port (
	CLK    : in  std_logic;
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
	OUT_VS : out std_logic;

	RED    : in  std_logic_vector(7 downto 0);
	GREEN  : in  std_logic_vector(7 downto 0);
	BLUE   : in  std_logic_vector(7 downto 0)
);
end entity;

architecture full of rgb_filter is

	signal filtered_r : std_logic_vector(7 downto 0);
	signal filtered_g : std_logic_vector(7 downto 0);
	signal filtered_b : std_logic_vector(7 downto 0);

begin

	output_regp : process(CLK, CE, filtered_r, filtered_g, filtered_b)
	begin
		if rising_edge(CLK) then
			if CE = '1' then
				OUT_R  <= filtered_r;
				OUT_G  <= filtered_g;
				OUT_B  <= filtered_b;
				OUT_DE <= IN_DE;
				OUT_HS <= IN_HS;
				OUT_VS <= IN_VS;
			end if;
		end if;
	end process;

gen_and: if OPERATION = OP_AND
generate
	filtered_r <= IN_R and RED;
	filtered_g <= IN_G and GREEN;
	filtered_b <= IN_B and BLUE;
end generate;

gen_or: if OPERATION = OP_OR
generate
	filtered_r <= IN_R or RED;
	filtered_g <= IN_G or GREEN;
	filtered_b <= IN_B or BLUE;
end generate;

gen_xor: if OPERATION = OP_XOR
generate
	filtered_r <= IN_R xor RED;
	filtered_g <= IN_G xor GREEN;
	filtered_b <= IN_B xor BLUE;
end generate;

end architecture;

