-- frame_ctrl.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.log2;

---
-- Calculates HS, VS and DE signals (in active is HIGH).
-- It never waits for data, external logic must assure
-- that the data are ready to be written to the output
-- when requested (DE = HIGH).
--
-- When SLEEP is asserted HS and VS are held HIGH. Then
-- when SLEEP is deasserted the frame starts with horizontal
-- and vertical pulses (so if some data are present they
-- will not be used immediately).
---
entity frame_ctrl is
generic (
	HP : integer := 96;
	HB : integer := 48;
	HD : integer := 640;
	HF : integer := 16;
	VP : integer := 2;
	VB : integer := 31;
	VD : integer := 480;
	VF : integer := 12
);
port (
	CLK     : in  std_logic;
	RST     : in  std_logic;

	SLEEP   : in  std_logic;
	DE      : out std_logic;
	LAST    : out std_logic;
	HS      : out std_logic;
	VS      : out std_logic
);
end entity;

architecture counter of frame_ctrl is

	constant HPIXELS : integer := HP + HB + HD + HF;
	constant VLINES  : integer := VP + VB + VD + VF;

	signal cnt_horiz_clr : std_logic;
	signal cnt_horiz_ce  : std_logic;
	signal cnt_horiz_of  : std_logic; -- overflow
	signal cnt_horiz     : std_logic_vector(log2(HPIXELS) - 1 downto 0);

	signal cnt_vert_clr  : std_logic;
	signal cnt_vert_ce   : std_logic;
	signal cnt_vert_of   : std_logic; -- overflow
	signal cnt_vert      : std_logic_vector(log2(VLINES) - 1 downto 0);

	signal st_hp         : std_logic;
	signal st_hb         : std_logic;
	signal st_hd         : std_logic;
	signal st_hf         : std_logic;
	signal st_vp         : std_logic;
	signal st_vb         : std_logic;
	signal st_vd         : std_logic;
	signal st_vf         : std_logic;

	signal rgb_data_req  : std_logic;

begin

	st_hp <= '1' when cnt_horiz <  HP else '0';
	st_hb <= '1' when cnt_horiz >= HP
	              and cnt_horiz <  (HP + HB) else '0';
	st_hd <= '1' when cnt_horiz >= (HP + HB)
	              and cnt_horiz <  (HP + HB + HD) else '0';
	st_hf <= '1' when cnt_horiz >= (HP + HB + HD)
	              and cnt_horiz <  (HP + HB + HD + HF) else '0';

	st_vp <= '1' when cnt_vert <  VP else '0';
	st_vb <= '1' when cnt_vert >= VP
                      and cnt_vert <  (VP + VB) else '0';
	st_vd <= '1' when cnt_vert >= (VP + VB)
                      and cnt_vert <  (VP + VB + VD) else '0';
	st_vf <= '1' when cnt_vert >= (VP + VB + VD)
                      and cnt_vert <  (VP + VB + VD + VF) else '0';

	-------------------------------------------

	HS    <= st_hp or cnt_horiz_of;
	VS    <= st_vp or cnt_vert_of;
	DE    <= st_hd and st_vd;
	LAST  <= '1' when cnt_horiz = HP + HB + HD - 1 and cnt_vert = VP + VB + VD - 1 else '0';

	-------------------------------------------
	
	cnt_horiz_ce <= '1';
	cnt_vert_ce  <= cnt_horiz_of;

	cnt_horiz_clr <= RST or SLEEP;
	cnt_vert_clr  <= RST or SLEEP;
	
	-------------------------------------------

	assert (st_hp = '1' and st_hb = '0' and st_hd = '0' and st_hf = '0') or
	       (st_hp = '0' and st_hb = '1' and st_hd = '0' and st_hf = '0') or
	       (st_hp = '0' and st_hb = '0' and st_hd = '1' and st_hf = '0') or
	       (st_hp = '0' and st_hb = '0' and st_hd = '0' and st_hf = '1') or
	       (st_hp = '0' and st_hb = '0' and st_hd = '0' and st_hf = '0')
	       report "Invalid horizontal states combination: "
	            & integer'image(conv_integer(st_hp)) & integer'image(conv_integer(st_hb))
	            & integer'image(conv_integer(st_hd)) & integer'image(conv_integer(st_hf))
	       severity error;

	assert (st_vp = '1' and st_vb = '0' and st_vd = '0' and st_vf = '0') or
	       (st_vp = '0' and st_vb = '1' and st_vd = '0' and st_vf = '0') or
	       (st_vp = '0' and st_vb = '0' and st_vd = '1' and st_vf = '0') or
	       (st_vp = '0' and st_vb = '0' and st_vd = '0' and st_vf = '1') or
	       (st_vp = '0' and st_vb = '0' and st_vd = '0' and st_vf = '0')
	       report "Invalid vertical states combination: "
	            & integer'image(conv_integer(st_vp)) & integer'image(conv_integer(st_vb))
	            & integer'image(conv_integer(st_vd)) & integer'image(conv_integer(st_vf))
	       severity error;

	-------------------------------------------

	cnt_horizp : process(CLK, cnt_horiz_ce, cnt_horiz_clr)
	begin
		if rising_edge(CLK) then
			if cnt_horiz_clr = '1' then
				cnt_horiz    <= (others => '0');
				cnt_horiz_of <= '0';
			elsif cnt_horiz_ce = '1' then
				if cnt_horiz = HPIXELS - 1 then
					cnt_horiz_of <= '1';
					cnt_horiz    <= (others => '0');
				else
					cnt_horiz_of <= '0';
					cnt_horiz    <= cnt_horiz + 1;
				end if;
			end if;
		end if;
	end process;

	cnt_vertp : process(CLK, cnt_vert_ce, cnt_vert_clr)
	begin
		if rising_edge(CLK) then
			if cnt_vert_clr = '1' then
				cnt_vert    <= (others => '0');
				cnt_vert_of <= '0';
			elsif cnt_vert_ce = '1' then
				if cnt_vert = VLINES - 1 then
					cnt_vert <= (others => '0');
				else
					cnt_vert <= cnt_vert + 1;
				end if;
			end if;
		end if;
	end process;

end architecture;
