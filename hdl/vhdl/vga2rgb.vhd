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

	type state_t is (s_drop, s_pass, s_hsync, s_vsync);
	signal state  : state_t;
	signal nstate : state_t;

	signal self_vgarst    : std_logic_vector(5 downto 0);
	signal self_vga_reset : std_logic;

	signal fifo_we     : std_logic;
	signal fifo_full   : std_logic;
	signal fifo_re     : std_logic;
	signal fifo_empty  : std_logic;

	signal cnt_hp     : std_logic_vector(log2(HPIXELS + 1) - 1 downto 0);
	signal cnt_hp_ce  : std_logic;
	signal cnt_hp_clr : std_logic;

	signal cnt_vp     : std_logic_vector(log2(VLINES + 1) - 1 downto 0);
	signal cnt_vp_ce  : std_logic;
	signal cnt_vp_clr : std_logic;

begin

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

	-------------------------------
	
	cnt_hpp : process(VGA_CLK, cnt_hp_ce, cnt_hp_clr)
	begin
		if rising_edge(VGA_CLK) then
			if cnt_hp_clr = '1' then
				cnt_hp <= (others => '0');
			elsif cnt_hp_ce = '1' then
				cnt_hp <= cnt_hp + 1;
			end if;
		end if;
	end process;
	
	cnt_vpp : process(VGA_CLK, cnt_vp_ce, cnt_vp_clr)
	begin
		if rising_edge(VGA_CLK) then
			if cnt_vp_clr = '1' then
				cnt_vp <= (others => '0');
			elsif cnt_vp_ce = '1' then
				cnt_vp <= cnt_vp + 1;
			end if;
		end if;
	end process;
	
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

	fsm_state : process(VGA_CLK, self_vga_reset, nstate)
	begin
		if rising_edge(VGA_CLK) then
			if self_vga_reset = '1' then
				state <= s_drop;
			else
				state <= nstate;
			end if;
		end if;
	end process;

	fsm_next : process(VGA_CLK, state, VGA_VS, VGA_HS)
	begin
		nstate <= state;

		case state is
		when s_drop =>
			if VGA_VS = '0' then
				nstate <= s_vsync;
			end if;

		when s_vsync =>
			if VGA_VS = '1' then
				nstate <= s_pass;
			end if;

		when s_pass =>
			if VGA_VS = '0' then
				nstate <= s_vsync;
			elsif VGA_HS = '0' then
				nstate <= s_hsync;
			end if;

		when s_hsync =>
			if VGA_VS = '0' then
				nstate <= s_vsync;
			elsif VGA_HS = '1' then
				nstate <= s_pass;
			end if;

		end case;
	end process;

	fsm_output : process(VGA_CLK, state, vga_hactive, vga_vactive)
	begin
		vga_dena <= '0';

		case state is
		when s_pass =>
			vga_dena <= vga_hactive and vga_vactive;

		when others =>
		end case;
	end process;

end architecture;

