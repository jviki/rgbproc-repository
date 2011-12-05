-- name.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity median_filter is
generic (
	BYPASS_EN : boolean := true
);
port (
	CLK     : in  std_logic;
	RST	: in  std_logic;
	
	WIN_R   : in  std_logic_vector(9 * 8 - 1 downto 0);
	WIN_G   : in  std_logic_vector(9 * 8 - 1 downto 0);
	WIN_B   : in  std_logic_vector(9 * 8 - 1 downto 0);
	WIN_VLD : in  std_logic;
	WIN_REQ : out std_logic;

	OUT_R   : out std_logic_vector(7 downto 0);
	OUT_G   : out std_logic_vector(7 downto 0);
	OUT_B   : out std_logic_vector(7 downto 0);
	OUT_VLD : out std_logic;
	OUT_REQ : in  std_logic;

	BYPASS  : out std_logic_vector(23 downto 0)
);
end entity;

architecture bitonic_sort_median9 of median_filter is

	signal filter_ce : std_logic;

begin

	median9_r : entity work.median9
	port map (
		CLK => CLK,
		CE  => filter_ce,
		DI  => WIN_R,
		DO  => OUT_R		
	);

	median9_g : entity work.median9
	port map (
		CLK => CLK,
		CE  => filter_ce,
		DI  => WIN_G,
		DO  => OUT_G		
	);

	rmedian9_b : entity work.median9
	port map (
		CLK => CLK,
		CE  => filter_ce,
		DI  => WIN_B,
		DO  => OUT_B		
	);

	---------------------------------
	
	rgb_handshake_i : entity work.rgb_handshake
	generic map (
		LINE_DEPTH => 8		
	)
	port map (
		CLK     => CLK,
		IN_REQ  => WIN_REQ,
		IN_VLD  => WIN_VLD,
		OUT_REQ => OUT_REQ,
		OUT_VLD => OUT_VLD,
		LINE_CE => filter_ce
	);
	
	---------------------------------

	---
	-- Bypass
	---

gen_bypass: if BYPASS_EN = true
generate

	bypass_i : entity work.bypass_shreg
	generic map (
		LINE_DEPTH => 8
	)
	port map (
		CLK => CLK,
		CE  => sum_ce,

		DI( 7 downto  0) => WIN_R(39 downto 32),
		DI(15 downto  8) => WIN_G(39 downto 32),
		DI(23 downto 16) => WIN_B(39 downto 32),
		DO  => BYPASS
	);
	
end generate;

end architecture;

