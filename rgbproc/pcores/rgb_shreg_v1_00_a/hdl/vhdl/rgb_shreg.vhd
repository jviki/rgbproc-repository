-- rgb_shreg.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity rgb_shreg is
generic (
	DEPTH   : integer := 1		
);
port (
	CLK     : in  std_logic;
	RST     : in  std_logic;
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

architecture full of rgb_shreg is

	type color_t is array(0 to DEPTH - 1) of std_logic_vector(7 downto 0);

	signal reg_r  : color_t;
	signal reg_g  : color_t;
	signal reg_b  : color_t;
	signal reg_de : std_logic_vector(DEPTH - 1 downto 0);
	signal reg_hs : std_logic_vector(DEPTH - 1 downto 0);
	signal reg_vs : std_logic_vector(DEPTH - 1 downto 0);

begin

	rgb_shregp : process(CLK, RST, CE)
	begin
		if rising_edge(CLK) then
			if RST = '1' then
				reg_de <= (others => '0');
				reg_hs <= (others => '0');
				reg_vs <= (others => '0');
			elsif CE = '1' then
				reg_r(0)  <= IN_R;
				reg_g(0)  <= IN_G;
				reg_b(0)  <= IN_B;
				reg_de(0) <= IN_DE;
				reg_hs(0) <= IN_HS;
				reg_vs(0) <= IN_VS;

				for i in 1 to DEPTH - 1 loop
					reg_r(i)  <= reg_r(i - 1);
					reg_g(i)  <= reg_g(i - 1);
					reg_b(i)  <= reg_b(i - 1);
					reg_de(i) <= reg_de(i - 1);
					reg_hs(i) <= reg_hs(i - 1);
					reg_vs(i) <= reg_vs(i - 1);
				end loop;
			end if;
		end if;
	end process;

	------------------

	OUT_R <= reg_r(DEPTH - 1);
	OUT_G <= reg_g(DEPTH - 1);
	OUT_B <= reg_b(DEPTH - 1);

	OUT_DE <= reg_de(DEPTH - 1);
	OUT_HS <= reg_hs(DEPTH - 1);
	OUT_VS <= reg_vs(DEPTH - 1);

end architecture;

