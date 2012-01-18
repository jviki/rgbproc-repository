-- rgbctl_gen.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.log2;

entity rgbctl_gen is
generic (
	HBP     : integer := 48;
	HDP     : integer := 640;
	HFP     : integer := 16;
	VBP     : integer := 33;
	VDP     : integer := 480;
	VFP     : integer := 10;
	HPULSE  : integer := 96;
	VPULSE  : integer := 2
);
port (
	CLK     : in  std_logic;
	RST     : in  std_logic;
	HS      : out std_logic;
	VS      : out std_logic;
	DE      : out std_logic
);
end entity;

architecture full of rgbctl_gen is

	constant HPIXELS : integer := HPULSE + HBP + HDP + HFP;
	constant VLINES  : integer := VPULSE + VBP + VDP + VFP;

	signal cnt_horiz     : std_logic_vector(log2(HPIXELS) - 1 downto 0);
	signal cnt_horiz_ce  : std_logic;
	signal cnt_horiz_o   : std_logic;

	signal cnt_vert      : std_logic_vector(log2(VLINES) - 1 downto 0);
	signal cnt_vert_ce   : std_logic;
	signal cnt_vert_clr  : std_logic;

	signal hdp_active    : std_logic;
	signal vdp_active    : std_logic;

	signal hpulse_active : std_logic;
	signal vpulse_active : std_logic;

begin

	hdp_active <= '1' when cnt_horiz >= HPULSE + HBP and cnt_horiz < HPULSE + HBP + HDP else '0';
	vdp_active <= '1' when cnt_vert  >= VPULSE + VBP and cnt_vert  < VPULSE + VBP + VDP else '0';

	hpulse_active <= '1' when cnt_horiz < HPULSE else '0';
	vpulse_active <= '1' when cnt_vert  < VPULSE else '0';

	DE <= hdp_active and vdp_active;

	-- negative logic:
	HS <= not hpulse_active;
	VS <= not vpulse_active;

	--------------------

	cnt_horiz_ce <= '1';
	cnt_vert_ce  <= cnt_horiz_o;

	--------------------

	cnt_horizp : process(CLK, RST, cnt_horiz_ce)
	begin
		if rising_edge(CLK) then
			if RST = '1' then
				cnt_horiz   <= (others => '0');
			elsif cnt_horiz_ce = '1' then
				if cnt_horiz = HPIXELS - 1 then
					cnt_horiz   <= (others => '0');
				else
					cnt_horiz <= cnt_horiz + 1;
				end if;
			end if;
		end if;
	end process;

	cnt_horiz_o <= '1' when cnt_horiz = HPIXELS - 1 else '0';

	--------------------

	cnt_vertp : process(CLK, RST, cnt_vert_ce)
	begin
		if rising_edge(CLK) then
			if RST = '1' then
				cnt_vert <= (others => '0');
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
