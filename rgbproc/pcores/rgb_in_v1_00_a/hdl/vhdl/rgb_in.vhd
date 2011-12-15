-- rgb_in.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

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

begin

	buffp : process(VGA_CLK)
	begin
		if rising_edge(VGA_CLK) then
			buff_r  <= VGA_R;
			buff_g  <= VGA_G;
			buff_b  <= VGA_B;
			buff_hs <= VGA_HS;
			buff_vs <= VGA_VS;
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

	RGB_DE <= st_hd and st_vd;
	RGB_HS <= buff_hs;
	RGB_VS <= buff_vs;

end architecture;

