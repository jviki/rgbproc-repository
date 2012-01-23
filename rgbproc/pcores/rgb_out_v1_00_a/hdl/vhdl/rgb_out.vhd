-- rgb_out.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>
-- Copyright (C) 2011, 2012 Jan Viktorin

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity rgb_out is
port (
	CLK         : in  std_logic;
	RST         : in  std_logic;
	
	RGB_R       : in  std_logic_vector(7 downto 0);
	RGB_G       : in  std_logic_vector(7 downto 0);
	RGB_B       : in  std_logic_vector(7 downto 0);
	RGB_DE      : in  std_logic;
	RGB_HS      : in  std_logic;
	RGB_VS	    : in  std_logic;

	OUT_D       : out std_logic_vector(11 downto 0);
	OUT_XCLK_P  : out std_logic;
	OUT_XCLK_N  : out std_logic;
	OUT_RESET_N : out std_logic;
	OUT_DE      : out std_logic;
	OUT_HS      : out std_logic;
	OUT_VS      : out std_logic
);
end entity;

---
-- Design to work with CH7301C codec. Outputs data using 12b bus
-- with IDF0 encoding (see www.chrontel.com/pdf/7301ds.pdf) on
-- double-data rate (DDR).
--
-- Anyway it simply bypasses RGB bus data to the codec.
---
architecture full of rgb_out is

	signal out_data0 : std_logic_vector(11 downto 0);
	signal out_data1 : std_logic_vector(11 downto 0);

begin

	idf0_i : entity work.idf_encoding(idf0)
	port map (
		RED   => RGB_R,
		GREEN => RGB_G,
		BLUE  => RGB_B,
		D0    => out_data0,
		D1    => out_data1
	);

	ddr_i : entity work.data_out(ddr)
	port map (
		CLK   => CLK,
		RST   => RST,

		D0    => out_data0,
		D1    => out_data1,
		DE    => RGB_DE,
		HS    => RGB_HS,
		VS    => RGB_VS,

		OUT_XCLK_P  => OUT_XCLK_P,
		OUT_XCLK_N  => OUT_XCLK_N,
		OUT_RESET_N => OUT_RESET_N,
		OUT_D       => OUT_D,
		OUT_DE      => OUT_DE,
		OUT_HS      => OUT_HS,
		OUT_VS      => OUT_VS
	);

end architecture;

