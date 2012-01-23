-- rgb_line_buff.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>
-- Copyright (C) 2011, 2012 Jan Viktorin

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library rgb_shreg_v1_00_a;
use rgb_shreg_v1_00_a.rgb_shreg;

---
-- Line buffer. Works as a shift register but provides
-- access to more then only one value. It is intended
-- for construction of sliding window mechanism.
--
-- Holds line of WIDTH pixels.
---
entity rgb_line_buff is
generic (
	WIDTH  : integer := 800;
	FIELDS : integer := 3
);
port (
	CLK      : in  std_logic;
	RST      : in  std_logic;
	CE       : in  std_logic;

	IN_R     : in  std_logic_vector(7 downto 0);
	IN_G     : in  std_logic_vector(7 downto 0);
	IN_B     : in  std_logic_vector(7 downto 0);
	IN_DE    : in  std_logic;
	IN_HS    : in  std_logic;
	IN_VS    : in  std_logic;

	FIELD_R  : out std_logic_vector(FIELDS * 8 - 1 downto 0);
	FIELD_G  : out std_logic_vector(FIELDS * 8 - 1 downto 0);
	FIELD_B  : out std_logic_vector(FIELDS * 8 - 1 downto 0);
	FIELD_DE : out std_logic_vector(FIELDS - 1 downto 0);
	FIELD_HS : out std_logic_vector(FIELDS - 1 downto 0);
	FIELD_VS : out std_logic_vector(FIELDS - 1 downto 0);

	OUT_R    : out std_logic_vector(7 downto 0);
	OUT_G    : out std_logic_vector(7 downto 0);
	OUT_B    : out std_logic_vector(7 downto 0);
	OUT_DE   : out std_logic;
	OUT_HS   : out std_logic;
	OUT_VS   : out std_logic
);
end entity;

---
-- Implementation uses rgb_shreg unit to store first WIDTH - FIELDS
-- pixels. The rest is used to provide the readable fields.
---
architecture full of rgb_line_buff is

	type color_t is array(0 to FIELDS) of std_logic_vector(7 downto 0);

	signal fields_r  : color_t;
	signal fields_g  : color_t;
	signal fields_b  : color_t;
	signal fields_de : std_logic_vector(FIELDS downto 0);
	signal fields_hs : std_logic_vector(FIELDS downto 0);
	signal fields_vs : std_logic_vector(FIELDS downto 0);

begin

	rgb_shreg_i : entity rgb_shreg_v1_00_a.rgb_shreg
	generic map (
		DEPTH => WIDTH - FIELDS		
	)
	port map (
		CLK    => CLK,
		RST    => RST,
		CE     => CE,		

		IN_R   => IN_R,
		IN_G   => IN_G,
		IN_B   => IN_B,
		IN_DE  => IN_DE,
		IN_HS  => IN_HS,
		IN_VS  => IN_VS,

		OUT_R  => fields_r(0),
		OUT_G  => fields_g(0),
		OUT_B  => fields_b(0),
		OUT_DE => fields_de(0),
		OUT_HS => fields_hs(0),
		OUT_VS => fields_vs(0)
	);

	----------------------------

gen_fields: for i in 1 to FIELDS
generate

	field_i : entity rgb_shreg_v1_00_a.rgb_shreg
	generic map (
		DEPTH => 1
	)
	port map (
		CLK    => CLK,
		RST    => RST,
		CE     => CE,

		IN_R   => fields_r (i - 1),
		IN_G   => fields_g (i - 1),
		IN_B   => fields_b (i - 1),
		IN_DE  => fields_de(i - 1),
		IN_HS  => fields_hs(i - 1),
		IN_VS  => fields_vs(i - 1),

		OUT_R  => fields_r (i),
		OUT_G  => fields_g (i),
		OUT_B  => fields_b (i),
		OUT_DE => fields_de(i),
		OUT_HS => fields_hs(i),
		OUT_VS => fields_vs(i)
	);

	FIELD_R (i * 8 - 1 downto (i - 1) * 8) <= fields_r(i - 1);
	FIELD_G (i * 8 - 1 downto (i - 1) * 8) <= fields_g(i - 1);
	FIELD_B (i * 8 - 1 downto (i - 1) * 8) <= fields_b(i - 1);
	FIELD_DE(i - 1) <= fields_de(i - 1);
	FIELD_HS(i - 1) <= fields_hs(i - 1);
	FIELD_VS(i - 1) <= fields_vs(i - 1);

end generate;

	----------------------------

	OUT_R  <= fields_r (FIELDS);
	OUT_G  <= fields_g (FIELDS);
	OUT_B  <= fields_b (FIELDS);
	OUT_DE <= fields_de(FIELDS);
	OUT_HS <= fields_hs(FIELDS);
	OUT_VS <= fields_vs(FIELDS);

end architecture;

