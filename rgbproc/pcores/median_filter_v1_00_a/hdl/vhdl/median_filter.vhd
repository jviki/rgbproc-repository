-- median_filter.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

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

	OUT_R  : in  std_logic_vector(7 downto 0);
	OUT_G  : in  std_logic_vector(7 downto 0);
	OUT_B  : in  std_logic_vector(7 downto 0);
	OUT_DE : in  std_logic;
	OUT_HS : in  std_logic;
	OUT_VS : in  std_logic
);
end entity;

architecture median9_filter of median_filter
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

	ctl_bypass_i : entity work.ctl_bypass
	generic map (
		DWIDTH => 3,
		DEPTH  => 10
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

end architecture;
