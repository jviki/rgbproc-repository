-- vga2rgb.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library rgb_commons_v1_00_a;
use rgb_commons_v1_00_a.rgb_asfifo;

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.log2;

---
-- 
---
entity vga2rgb is
generic (
	DEBUG    : boolean := false
);
port (
	VGA_CLK  : in  std_logic;
	VGA_R    : in  std_logic_vector(7 downto 0);
	VGA_G    : in  std_logic_vector(7 downto 0);
	VGA_B    : in  std_logic_vector(7 downto 0);
	VGA_HS   : in  std_logic;
	VGA_VS   : in  std_logic;

	RGB_CLK  : in  std_logic;
	RGB_RST  : in  std_logic;
	RGB_R    : out std_logic_vector(7 downto 0);
	RGB_G    : out std_logic_vector(7 downto 0);
	RGB_B    : out std_logic_vector(7 downto 0);
	RGB_EOL  : out std_logic;
	RGB_EOF  : out std_logic;

	RGB_VLD  : out std_logic;
	RGB_REQ  : in  std_logic
);
end entity;

architecture full of vga2rgb is

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

	signal internal_reset : std_logic;

	signal fifo_we       : std_logic;
	signal fifo_full     : std_logic;
	signal fifo_re       : std_logic;
	signal fifo_empty    : std_logic;

	signal vga_eol       : std_logic;
	signal vga_eof       : std_logic;
	signal vga_reset     : std_logic;

	signal cnt_horiz     : std_logic_vector(log2(HPIXELS) - 1 downto 0);
	signal cnt_horiz_ce  : std_logic;
	signal cnt_horiz_clr : std_logic;
	signal cnt_vert      : std_logic_vector(log2(VLINES) - 1 downto 0);
	signal cnt_vert_ce   : std_logic;
	signal cnt_vert_clr  : std_logic;

	signal st_hd         : std_logic;
	signal st_vd         : std_logic;

begin

	asfifo_rgb : entity rgb_commons_v1_00_a.rgb_asfifo
	port map (
		ASYNC_RST     => RGB_RST,

		RGB_IN_CLK    => VGA_CLK,
		RGB_IN_R      => VGA_R,
		RGB_IN_G      => VGA_G,
		RGB_IN_B      => VGA_B,
		RGB_IN_EOL    => vga_eol,
		RGB_IN_EOF    => vga_eof,
		RGB_IN_WE     => fifo_we,
		RGB_IN_FULL   => fifo_full,

		RGB_OUT_CLK   => RGB_CLK,
		RGB_OUT_R     => RGB_R,
		RGB_OUT_G     => RGB_G,
		RGB_OUT_B     => RGB_B,
		RGB_OUT_EOL   => RGB_EOL,
		RGB_OUT_EOF   => RGB_EOF,
		RGB_OUT_RE    => fifo_re,
		RGB_OUT_EMPTY => fifo_empty
	);

	-------------------------------

	internal_reset <= RGB_RST or vga_reset;
	vga_reset      <= not(VGA_VS or VGA_HS);

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
	cnt_horiz_clr <= internal_reset or not(VGA_HS);

	cnt_vert_ce   <= '1' when cnt_horiz = HBP + HPIXELS + HFP - 1 else '0';
	cnt_vert_clr  <= internal_reset or not(VGA_VS);

	-------------------------------

	st_hd <= '1' when cnt_horiz >= HBP and cnt_horiz < (HBP + HDP) else '0';
	st_vd <= '1' when cnt_vert  >= VBP and cnt_vert  < (VBP + VDP) else '0';

	vga_eol <= '1'     when cnt_horiz = HBP + HDP - 1 else '0';
	vga_eof <= vga_eol when cnt_vert  = VBP + VDP - 1 else '0';

	-------------------------------

	fifo_we <= (st_hd and st_vd) and not fifo_full;

	-------------------------------

	fifo_re <= RGB_REQ and not fifo_empty;
	RGB_VLD <= not fifo_empty;

end architecture;

