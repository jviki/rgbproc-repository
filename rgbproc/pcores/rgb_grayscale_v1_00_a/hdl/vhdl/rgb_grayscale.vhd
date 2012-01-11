-- rgb_grayscale.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity rgb_grayscale is
port (
	CLK     : in  std_logic;
	CE      : in  std_logic;

	IN_R    : in  std_logic_vector(7 downto 0);
	IN_B    : in  std_logic_vector(7 downto 0);
	IN_G    : in  std_logic_vector(7 downto 0);
	IN_DE   : in  std_logic;
	IN_HS   : in  std_logic;
	IN_VS   : in  std_logic;

	OUT_R   : out std_logic_vector(7 downto 0);
	OUT_G   : out std_logic_vector(7 downto 0);
	OUT_B   : out std_logic_vector(7 downto 0);
	OUT_DE  : out std_logic;
	OUT_HS  : out std_logic;
	OUT_VS  : out std_logic
);
end entity;

architecture dsp of rgb_grayscale is

	signal prod_r : std_logic_vector(15 downto 0);
	signal prod_g : std_logic_vector(15 downto 0);
	signal prod_b : std_logic_vector(15 downto 0);

	signal gray_c : std_logic_vector(15 downto 0);

begin

	sum_outp : process(CLK, CE)
	begin
		if rising_edge(CLK) then
			if CE = '1' then
				gray_c <= prod_r + prod_g + prod_b;
			end if;
		end if;
	end process;

	OUT_R  <= gray_c(15 downto 8);
	OUT_G  <= gray_c(15 downto 8);
	OUT_B  <= gray_c(15 downto 8);

end architecture;

