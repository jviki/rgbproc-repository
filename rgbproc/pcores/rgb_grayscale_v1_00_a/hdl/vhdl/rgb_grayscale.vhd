-- rgb_grayscale.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>
-- Copyright (C) 2011, 2012 Jan Viktorin

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library utils_v1_00_a;
use utils_v1_00_a.multiply18;

---
-- Performs RGB to grayscale conversion.
-- The result is that all color channels
-- have the same value.
---
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

---
-- Uses theorem
--  G := r * 0.30 + g * 0.59 + b * 0.11
--
-- Multiplication is performed in fixed point arithmetic
-- using Xilinx DSP blocks. Extends each 8b channel to
-- 18 bits for enough precision and sign.
-- After mutliplication and sum it is divided by 1024.
---
architecture dsp of rgb_grayscale is

	constant RAW_RED_FACTOR   : real := 0.30;
	constant RAW_GREEN_FACTOR : real := 0.59;
	constant RAW_BLUE_FACTOR  : real := 0.11;

	constant INT_RED_FACTOR   : integer := integer(RAW_RED_FACTOR   * 1024.0);
	constant INT_GREEN_FACTOR : integer := integer(RAW_GREEN_FACTOR * 1024.0);
	constant INT_BLUE_FACTOR  : integer := integer(RAW_BLUE_FACTOR  * 1024.0);

	constant RED_FACTOR       : std_logic_vector(17 downto 0) := conv_std_logic_vector(INT_RED_FACTOR, 18);
	constant GREEN_FACTOR     : std_logic_vector(17 downto 0) := conv_std_logic_vector(INT_GREEN_FACTOR, 18);
	constant BLUE_FACTOR      : std_logic_vector(17 downto 0) := conv_std_logic_vector(INT_BLUE_FACTOR, 18);

	signal arg_r  : std_logic_vector(17 downto 0);
	signal arg_g  : std_logic_vector(17 downto 0);
	signal arg_b  : std_logic_vector(17 downto 0);

	signal prod_r : std_logic_vector(35 downto 0);
	signal prod_g : std_logic_vector(35 downto 0);
	signal prod_b : std_logic_vector(35 downto 0);

	signal prod_de : std_logic;
	signal prod_hs : std_logic;
	signal prod_vs : std_logic;

	signal gray_c : std_logic_vector(35 downto 0);

	signal gray_de : std_logic;
	signal gray_hs : std_logic;
	signal gray_vs : std_logic;

begin

	arg_r <= "0000000000" & IN_R;
	arg_g <= "0000000000" & IN_G;
	arg_b <= "0000000000" & IN_B;

	mult_r : entity utils_v1_00_a.multiply18
	generic map (
		CTL_WIDTH => 1
	)
	port map (
		CLK  => CLK,
		CE   => CE,
		A    => arg_r,
		B    => RED_FACTOR,
		P    => prod_r,
		CTLI(0) => IN_DE,
		CTLO(0) => prod_de
	);

	mult_g : entity utils_v1_00_a.multiply18
	generic map (
		CTL_WIDTH => 1
	)
	port map (
		CLK  => CLK,
		CE   => CE,
		A    => arg_g,
		B    => GREEN_FACTOR,
		P    => prod_g,
		CTLI(0) => IN_HS,
		CTLO(0) => prod_hs
	);

	mult_b : entity utils_v1_00_a.multiply18
	generic map (
		CTL_WIDTH => 1
	)
	port map (
		CLK  => CLK,
		CE   => CE,
		A    => arg_b,
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

	OUT_R  <= gray_c(17 downto 10);
	OUT_G  <= gray_c(17 downto 10);
	OUT_B  <= gray_c(17 downto 10);
	OUT_DE <= gray_de;
	OUT_HS <= gray_hs;
	OUT_VS <= gray_vs;

end architecture;

