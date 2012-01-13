-- rgb_gen.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity rgb_gen is
port (
	CLK : in  std_logic;
	RST : in  std_logic;
	R   : out std_logic_vector(7 downto 0);
	G   : out std_logic_vector(7 downto 0);
	B   : out std_logic_vector(7 downto 0);
	DE  : out std_logic;
	HS  : out std_logic;
	VS  : out std_logic
);
end entity;

architecture simple of rgb_gen is

	constant HBP     : integer := 48;
	constant HDP     : integer := 640;
	constant HFP     : integer := 16;
	constant VBP     : integer := 33;
	constant VDP     : integer := 480;
	constant VFP     : integer := 10;

	constant HPULSE  : integer := 96;
	constant VPULSE  : integer := 2;

	signal cnt_color_ce  : std_logic;
	signal cnt_color_clr : std_logic;
	signal cnt_color     : std_logic_vector(7 downto 0);

begin

	cnt_colorp : process(RGB_CLK, cnt_color_ce, cnt_color_clr)
	begin
		if rising_edge(RGB_CLK) then
			if cnt_color_clr = '1' then
				cnt_color <= (others => '1');
			elsif cnt_color_ce = '1' then
				cnt_color <= cnt_color + 1;
			end if;
		end if;
	end process;

	cnt_color_ce  <= out_de;
	cnt_color_clr <= not out_vs;

	---------------------------------

	ctl_i : entity work.rgbctl_gen
	generic map (
		HBP    => HBP,
		HDP    => HDP,
		HFP    => HFP,
		VBP    => VBP,
		VDP    => VDP,
		VFP    => VFP,
		HPULSE => HPULSE,
		VPULSE => VPULSE
	)
	port map (
		CLK => CLK,
		RST => RST,

		HS  => out_hs,
		VS  => out_vs,
		DE  => out_de
	);

	---------------------------------
	
	R  <= cnt_color;
	G  <= cnt_color;
	B  <= cnt_color;
	DE <= out_de;
	HS <= out_hs;
	VS <= out_vs;
	
end architecture;

