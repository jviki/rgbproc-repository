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

	constant HPIXELS : integer := 800;
	constant VLINES  : integer := 525;

	constant HBP     : integer := 48;
	constant HFP     : integer := 16;
	constant VBP     : integer := 33;
	constant VFP     : integer := 10;

	constant HPULSE  : integer := 96;

	signal self_vgarst    : std_logic_vector(5 downto 0);
	signal self_vga_reset : std_logic;

	signal noclk_reset    : std_logic;
	signal internal_reset : std_logic;

	signal fifo_we     : std_logic;
	signal fifo_full   : std_logic;
	signal fifo_re     : std_logic;
	signal fifo_empty  : std_logic;

	signal cnt_vactive     : std_logic_vector(log2(VLINES) - 1 downto 0);
	signal cnt_vactive_ce  : std_logic;
	signal cnt_vactive_clr : std_logic;

	signal vga_hactive : std_logic;
	signal vga_vactive : std_logic;
	signal vga_dena    : std_logic;

	signal vga_eof     : std_logic;
	signal vga_sol     : std_logic;
	signal vga_eol     : std_logic;

begin

	internal_reset <= self_vga_reset or noclk_reset;

	-------------------------------

	asfifo_rgb : entity rgb_commons_v1_00_a.rgb_asfifo
	port map (
		ASYNC_RST     => self_vga_reset,

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

	fifo_we <= vga_dena and not fifo_full;
	fifo_re <= RGB_REQ;
	
	RGB_VLD <= not fifo_empty;
	
	-------------------------------

	hactive_detect_i : entity work.active_detect
	generic map (
		BEG_OFF => HBP,
		END_OFF => HFP,
		LENGTH  => HPIXELS - HPULSE
	)
	port map (
		CLK    => VGA_CLK,
		RST    => internal_reset,
		SYNC_N => VGA_HS,
		ACTIVE => vga_hactive,
		FIRST  => vga_sol,
		LAST   => vga_eol
	);

	cnt_vactivep : process(VGA_CLK, cnt_vactive_ce, cnt_vactive_clr)
	begin
		if rising_edge(VGA_CLK) then
			if cnt_vactive_clr = '1' then
				cnt_vactive <= (others => '0');
			elsif cnt_vactive_ce = '1' then
				cnt_vactive <= cnt_vactive + 1;
			end if;
		end if;
	end process;

	cnt_vactive_ce  <= vga_sol;
	cnt_vactive_clr <= not VGA_VS or internal_reset;

	-- This vactive signal is different (little bit late) from that from source (e.g. simulation).
	-- It is up after a small delay of HBP, because of using vga_sol.
	vga_vactive <= vga_sol           when cnt_vactive = VBP else
	               not vga_sol       when cnt_vactive = VLINES - VFP - 2 else
	               VGA_VS or vga_sol when cnt_vactive > VBP and cnt_vactive < VLINES - VFP - 1
		       else '0';

	vga_eof     <= vga_eol when cnt_vactive = VLINES - VFP - 2 else '0';

	-------------------------------

	vga_dena <= vga_hactive and vga_vactive;

	-------------------------------

	self_vgarstp : process(VGA_CLK, self_vgarst)
	begin
		if rising_edge(VGA_CLK) then
			self_vgarst(0) <= not RGB_RST;
			self_vgarst(1) <= self_vgarst(0);
			self_vgarst(2) <= self_vgarst(1);
			self_vgarst(3) <= self_vgarst(2);
			self_vgarst(4) <= self_vgarst(3);
			self_vgarst(5) <= self_vgarst(4);
		end if;
	end process;

	self_vga_reset <= '0' when self_vgarst = (5 downto 0 => '1') else '1';

	-------------------------------

	noclk_reset_i : entity work.noclk_reset
	generic map (
		CLK_RATIO => 5
	)
	port map (
		REF_CLK   => RGB_CLK,
		REF_RST   => self_vga_reset,
		NO_CLK    => VGA_CLK,
		GEN_RST   => noclk_reset
	);

end architecture;

