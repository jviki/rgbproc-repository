-- rgb_in.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>
-- Copyright (C) 2011, 2012 Jan Viktorin

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.log2;

entity rgb_in is
port (
	VGA_CLK  : in  std_logic;
	VGA_R    : in  std_logic_vector(7 downto 0);
	VGA_G    : in  std_logic_vector(7 downto 0);
	VGA_B    : in  std_logic_vector(7 downto 0);
	VGA_HS   : in  std_logic;
	VGA_VS   : in  std_logic;
	VGA_CLAMP      : out std_logic;
	VGA_COAST      : out std_logic;
	VGA_ODD_EVEN_B : in  std_logic;
	VGA_SOGOUT     : in  std_logic;

	RGB_R    : out std_logic_vector(7 downto 0);
	RGB_G    : out std_logic_vector(7 downto 0);
	RGB_B    : out std_logic_vector(7 downto 0);
	RGB_DE   : out std_logic;
	RGB_HS   : out std_logic;
	RGB_VS   : out std_logic
);
end entity;

---
-- Designed to work with AD9980 codec (but should work with any
-- digital VGA input). For details see codec at URL:
--  http://www.xilinx.com/products/boards/ml505/datasheets/464471350AD9980_0.pdf
-- 
-- Current configuration assumes VGA mode:
--  * 640x480, 60 Hz; HS and VS at LOW when pulse occures
--
-- Generates RGB_DE signal. All other bits are only bypassed
-- from input.
--
-- Signals VGA_CLAMP, VGA_COAST, VGA_ODD_EVEN_B, VGA_SOGOUT
-- are not used.
--
-- The constants HBP, HDP, HFP, VBP, VDP, VFP, HPULSE, VPULSE
-- can be changed to support other modes. In that case it would
-- be better to change them to generic parameters.
---
architecture full of rgb_in is

	constant HBP     : integer := 48;
	constant HDP     : integer := 640;
	constant HFP     : integer := 16;
	constant VBP     : integer := 33;
	constant VDP     : integer := 480;
	constant VFP     : integer := 10;

	constant HPULSE  : integer := 96;
	constant VPULSE  : integer := 2;

	constant HPIXELS : integer := HPULSE + HBP + HDP + HFP;
	constant VLINES  : integer := VPULSE + VBP + VDP + VFP;

	signal cnt_horiz     : std_logic_vector(log2(HPIXELS) - 1 downto 0);
	signal cnt_horiz_ce  : std_logic;
	signal cnt_horiz_clr : std_logic;
	signal cnt_vert      : std_logic_vector(log2(VLINES) - 1 downto 0);
	signal cnt_vert_ce   : std_logic;
	signal cnt_vert_clr  : std_logic;

	signal st_hd         : std_logic;
	signal st_vd         : std_logic;

	signal buff_r        : std_logic_vector(7 downto 0);
	signal buff_g        : std_logic_vector(7 downto 0);
	signal buff_b        : std_logic_vector(7 downto 0);
	signal buff_hs       : std_logic;
	signal buff_vs       : std_logic;
	signal buff_de       : std_logic;

begin

	buffp : process(VGA_CLK)
	begin
		if rising_edge(VGA_CLK) then
			buff_r  <= VGA_R;
			buff_g  <= VGA_G;
			buff_b  <= VGA_B;
			buff_hs <= VGA_HS;
			buff_vs <= VGA_VS;
			buff_de <= st_hd and st_vd;
		end if;
	end process;

	-------------------------------

	cnt_horizp : process(VGA_CLK, cnt_horiz_ce, cnt_horiz_clr)
	begin
		if rising_edge(VGA_CLK) then
			if cnt_horiz_clr = '1' then
				cnt_horiz    <= (others => '0');
			elsif cnt_horiz_ce = '1' then
				cnt_horiz    <= cnt_horiz + 1;
			end if;
		end if;
	end process;

	cn_vertp : process(VGA_CLK, cnt_vert_ce, cnt_vert_clr)
	begin
		if rising_edge(VGA_CLK) then
			if cnt_vert_clr = '1' then
				cnt_vert <= (others => '0');
			elsif cnt_vert_ce = '1' then
				cnt_vert <= cnt_vert + 1;
			end if;
		end if;
	end process;

	-------------------------------

	cnt_horiz_ce  <= '1';
	cnt_horiz_clr <= not(buff_hs);

	cnt_vert_ce   <= '1' when cnt_horiz = HBP + HDP + HFP - 1 else '0';
	cnt_vert_clr  <= not(buff_vs);

	-------------------------------

	st_hd <= '1' when cnt_horiz >= HBP and cnt_horiz < (HBP + HDP) else '0';
	st_vd <= '1' when cnt_vert  >= VBP and cnt_vert  < (VBP + VDP) else '0';

	-------------------------------

	RGB_R <= buff_r;
	RGB_G <= buff_g;
	RGB_B <= buff_b;

	RGB_DE <= buff_de;
	RGB_HS <= buff_hs;
	RGB_VS <= buff_vs;

end architecture;

