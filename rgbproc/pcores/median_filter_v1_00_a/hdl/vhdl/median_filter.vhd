-- median_filter.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>
-- Copyright (C) 2011, 2012 Jan Viktorin

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library utils_v1_00_a;
use utils_v1_00_a.ctl_bypass;

---
-- Performs median filtering on RGB window bus. The window
-- must be create by another unit. Median filter sorts the
-- values in the window and outputs its median.
---
entity median_filter is
generic (
	MATRIX_SIZE : integer := 3		
);
port (
	CLK    : in  std_logic;
	CE     : in  std_logic;
	
	WIN_R  : in  std_logic_vector((MATRIX_SIZE ** 2) * 8 - 1 downto 0);
	WIN_G  : in  std_logic_vector((MATRIX_SIZE ** 2) * 8 - 1 downto 0);
	WIN_B  : in  std_logic_vector((MATRIX_SIZE ** 2) * 8 - 1 downto 0);
	WIN_DE : in  std_logic_vector((MATRIX_SIZE ** 2) - 1     downto 0);
	WIN_HS : in  std_logic_vector((MATRIX_SIZE ** 2) - 1     downto 0);
	WIN_VS : in  std_logic_vector((MATRIX_SIZE ** 2) - 1     downto 0);

	OUT_R  : out std_logic_vector(7 downto 0);
	OUT_G  : out std_logic_vector(7 downto 0);
	OUT_B  : out std_logic_vector(7 downto 0);
	OUT_DE : out std_logic;
	OUT_HS : out std_logic;
	OUT_VS : out std_logic
);
end entity;

---
-- Implementation uses unit median9 with bitonic sorter.
-- It does not care about the borders it just uses the
-- incoming values. Thus the unit can be improved by
-- using eg. zero values on window fields with DE = '0'.
--
-- This implementation is for 3x3 windows only.
---
architecture median9_filter of median_filter is

	signal median_r : std_logic_vector(7 downto 0);
	signal median_g : std_logic_vector(7 downto 0);
	signal median_b : std_logic_vector(7 downto 0);

begin

	median_r_i : entity work.median9
	port map (
		CLK => CLK,
		CE  => CE,
		DI  => WIN_R,
		DO  => median_r
	);

	median_g_i : entity work.median9
	port map (
		CLK => CLK,
		CE  => CE,
		DI  => WIN_G,
		DO  => median_g
	);

	median_b_i : entity work.median9
	port map (
		CLK => CLK,
		CE  => CE,
		DI  => WIN_B,
		DO  => median_b
	);

	ctl_bypass_i : entity utils_v1_00_a.ctl_bypass
	generic map (
		DWIDTH => 3,
		DEPTH  => 8
	)
	port map (
		CLK    => CLK,
		CE     => CE,
		DI(0)  => WIN_DE(4),
		DI(1)  => WIN_HS(4),
		DI(2)  => WIN_VS(4),
		DO(0)  => OUT_DE,
		DO(1)  => OUT_HS,
		DO(2)  => OUT_VS
	);

	OUT_R <= median_r;
	OUT_G <= median_g;
	OUT_B <= median_b;

end architecture;
