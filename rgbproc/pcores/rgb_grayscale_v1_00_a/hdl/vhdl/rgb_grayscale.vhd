-- rgb_grayscale.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library utils_v1_00_a;
use utils_v1_00_a.multiply8;

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

	constant RAW_RED_FACTOR   : real := 0.30;
	constant RAW_GREEN_FACTOR : real := 0.59;
	constant RAW_BLUE_FACTOR  : real := 0.11;

	constant INT_RED_FACTOR   : integer := integer(RAW_RED_FACTOR   * 1024.0);
	constant INT_GREEN_FACTOR : integer := integer(RAW_GREEN_FACTOR * 1024.0);
	constant INT_BLUE_FACTOR  : integer := integer(RAW_BLUE_FACTOR  * 1024.0);

	constant RED_FACTOR       : std_logic_vector(7 downto 0) := conv_std_logic_vector(INT_RED_FACTOR, 8);
	constant GREEN_FACTOR     : std_logic_vector(7 downto 0) := conv_std_logic_vector(INT_GREEN_FACTOR, 8);
	constant BLUE_FACTOR      : std_logic_vector(7 downto 0) := conv_std_logic_vector(INT_BLUE_FACTOR, 8);

	signal prod_r : std_logic_vector(15 downto 0);
	signal prod_g : std_logic_vector(15 downto 0);
	signal prod_b : std_logic_vector(15 downto 0);

	signal prod_de : std_logic;
	signal prod_hs : std_logic;
	signal prod_vs : std_logic;

	signal gray_c : std_logic_vector(15 downto 0);

	signal gray_de : std_logic;
	signal gray_hs : std_logic;
	signal gray_vs : std_logic;

begin

	mult_r : entity utils_v1_00_a.multiply8
	generic map (
		CTL_WIDTH => 1
	)
	port map (
		CLK  => CLK,
		CE   => CE,
		A    => IN_R,
		B    => RED_FACTOR,
		P    => prod_r,
		CTLI(0) => IN_DE,
		CTLO(0) => prod_de
	);

	mult_g : entity utils_v1_00_a.multiply8
	generic map (
		CTL_WIDTH => 1
	)
	port map (
		CLK  => CLK,
		CE   => CE,
		A    => IN_G,
		B    => GREEN_FACTOR,
		P    => prod_g,
		CTLI(0) => IN_HS,
		CTLO(0) => prod_hs
	);

	mult_b : entity utils_v1_00_a.multiply8
	generic map (
		CTL_WIDTH => 1
	)
	port map (
		CLK  => CLK,
		CE   => CE,
		A    => IN_B,
		B    => BLUE_FACTOR,
		P    => prod_b,
		CTLI(0) => IN_VS,
		CTLO(0) => prod_VS
	);

	----------------------------------

	sum_outp : process(CLK, CE, prod_r, prod_g, prod_b, prod_de, prod_hs, prod_vs)
	begin
		if rising_edge(CLK) then
			if CE = '1' then
				gray_c <= prod_r + prod_g + prod_b;
				gray_de <= prod_de;
				gray_hs <= prod_hs;
				gray_vs <= prod_vs;
			end if;
		end if;
	end process;

	OUT_R  <= gray_c(15 downto 8);
	OUT_G  <= gray_c(15 downto 8);
	OUT_B  <= gray_c(15 downto 8);
	OUT_DE <= gray_de;
	OUT_HS <= gray_hs;
	OUT_VS <= gray_vs;

end architecture;

