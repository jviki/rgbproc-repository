-- vga_watch_cs.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity vga_watch_cs is
generic (
	CS_XVEC_ENABLE : boolean := true
);
port (
	VGA_CLK : in  std_logic;
	VGA_R   : in  std_logic_vector(7 downto 0);
	VGA_G   : in  std_logic_vector(7 downto 0);
	VGA_B   : in  std_logic_vector(7 downto 0);
	VGA_HS  : in  std_logic;
	VGA_VS	: in  std_logic;
	VGA_SOGOUT     : in std_logic;
	VGA_ODD_EVEN_B : in std_logic;

	CS_CLK  : out std_logic;
	CS_VEC  : out std_logic_vector(31 downto 0);
	CS_XVEC : out std_logic_vector(31 + 4 + (3 * 16) downto 0)
);
end entity;

architecture full of vga_watch_cs is

	signal cnt_hs_high     : std_logic_vector(15 downto 0);
	signal cnt_hs_high_ce  : std_logic;
	signal cnt_hs_high_clr : std_logic;

	signal cnt_hs_low      : std_logic_vector(15 downto 0);
	signal cnt_hs_low_ce   : std_logic;
	signal cnt_hs_low_clr  : std_logic;

	signal cnt_vs_high     : std_logic_vector(15 downto 0);
	signal cnt_vs_high_ce  : std_logic;
	signal cnt_vs_high_clr : std_logic;

	signal cnt_vs_low      : std_logic_vector(3 downto 0);
	signal cnt_vs_low_ce   : std_logic;
	signal cnt_vs_low_clr  : std_logic;

	signal cs_vec_simple   : std_logic_vector(31 downto 0);

begin

	CS_CLK <= VGA_CLK;

	cs_vec_simple(0) <= VGA_ODD_EVEN_B;

	cs_vec_simple(1) <= VGA_HS;
	cs_vec_simple(2) <= VGA_VS;

	cs_vec_simple(10 downto  3) <= VGA_R;
	cs_vec_simple(18 downto 11) <= VGA_G;
	cs_vec_simple(26 downto 19) <= VGA_B;

	cs_vec_simple(31 downto 27) <= (others => '1');

	CS_VEC <= cs_vec_simple;

	----------------------------------

gen_cs_xvec: if CS_XVEC_ENABLE = true
generate

	CS_XVEC(31 downto  0) <= cs_vec_simple;

	CS_XVEC(47 downto 32) <= cnt_hs_high;
	CS_XVEC(63 downto 48) <= cnt_hs_low;
	CS_XVEC(79 downto 64) <= cnt_vs_high;
	CS_XVEC(83 downto 80) <= cnt_vs_low;

	----------------------------------

	cnt_hs_highp : process(VGA_CLK, cnt_hs_high_ce, cnt_hs_high_clr)
	begin
		if rising_edge(VGA_CLK) then
			if cnt_hs_high_clr = '1' then
				cnt_hs_high <= (others => '0');
			elsif cnt_hs_high_ce = '1' then
				cnt_hs_high <= cnt_hs_high + 1;
			end if;
		end if;
	end process;

	cnt_hs_high_clr <= not VGA_HS;
	cnt_hs_high_ce  <= VGA_HS;

	-----------------

	cnt_hs_lowp : process(VGA_CLK, cnt_hs_low_ce, cnt_hs_low_clr)
	begin
		if rising_edge(VGA_CLK) then
			if cnt_hs_low_clr = '1' then
				cnt_hs_low <= (others => '0');
			elsif cnt_hs_low_ce = '1' then
				cnt_hs_low <= cnt_hs_low + 1;
			end if;
		end if;
	end process;

	cnt_hs_low_clr <= VGA_HS;
	cnt_hs_low_ce  <= not VGA_HS;

	----------------------------------

	cnt_vs_highp : process(VGA_HS, cnt_vs_high_ce, cnt_vs_high_clr)
	begin
		if rising_edge(VGA_HS) then
			if cnt_vs_high_clr = '1' then
				cnt_vs_high <= (others => '0');
			elsif cnt_vs_high_ce = '1' then
				cnt_vs_high <= cnt_vs_high + 1;
			end if;
		end if;
	end process;

	cnt_vs_high_clr <= not VGA_VS;
	cnt_vs_high_ce  <= VGA_VS;

	-----------------

	cnt_vs_lowp : process(VGA_HS, cnt_vs_low_ce, cnt_vs_low_clr)
	begin
		if rising_edge(VGA_HS) then
			if cnt_vs_low_clr = '1' then
				cnt_vs_low <= (others => '0');
			elsif cnt_vs_low_ce = '1' then
				cnt_vs_low <= cnt_vs_low + 1;
			end if;
		end if;
	end process;

	cnt_vs_low_clr <= VGA_VS;
	cnt_vs_low_ce  <= not VGA_VS;

end generate;

end architecture;

