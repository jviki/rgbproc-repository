-- rgb_split.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity rgb_split is
port (
	CLK     : in  std_logic;
	CE      : in  std_logic;

	IN_R    : in  std_logic_vector(7 downto 0);
	IN_B    : in  std_logic_vector(7 downto 0);
	IN_G    : in  std_logic_vector(7 downto 0);
	IN_DE   : in  std_logic;
	IN_HS   : in  std_logic;
	IN_VS   : in  std_logic;

	OUT0_R  : out std_logic_vector(7 downto 0);
	OUT0_G  : out std_logic_vector(7 downto 0);
	OUT0_B  : out std_logic_vector(7 downto 0);
	OUT0_DE : out std_logic;
	OUT0_HS : out std_logic;
	OUT0_VS : out std_logic;

	OUT1_R  : out std_logic_vector(7 downto 0);
	OUT1_G  : out std_logic_vector(7 downto 0);
	OUT1_B  : out std_logic_vector(7 downto 0);
	OUT1_DE : out std_logic;
	OUT1_HS : out std_logic;
	OUT1_VS : out std_logic
);
end entity;

architecture reg_wire of rgb_split is
begin

	regp : process(CLK, CE)
	begin
		if rising_edge(CLK) then
			if CE = '1' then
				OUT0_R  <= IN_R;
				OUT0_G  <= IN_G;
				OUT0_B  <= IN_B;
				OUT0_DE <= IN_DE;
				OUT0_HS <= IN_HS;
				OUT0_VS <= IN_VS;

				OUT1_R  <= IN_R;
				OUT1_G  <= IN_G;
				OUT1_B  <= IN_B;
				OUT1_DE <= IN_DE;
				OUT1_HS <= IN_HS;
				OUT1_VS <= IN_VS;
			end if;
		end if;
	end process;

end architecture;
