-- rgb_watch_cs.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

---
-- Watchs RGB bus and reports its internals
-- to chipscope.
---
entity rgb_watch_cs is
port (
	RGB_CLK : in  std_logic;
	RGB_RST : in  std_logic;
	RGB_R   : in  std_logic_vector(7 downto 0);
	RGB_G   : in  std_logic_vector(7 downto 0);
	RGB_B   : in  std_logic_vector(7 downto 0);
	RGB_EOL : in  std_logic;
	RGB_EOF : in  std_logic;
	RGB_VLD : in  std_logic;
	RGB_REQ : in  std_logic;

	CS_CLK  : out std_logic;
	CS_VEC  : out std_logic_vector(47 downto 0)
);
end entity;

architecture full of rgb_watch_cs is

 	signal cnt_lines     : std_logic_vector(15 downto 0);
 	signal cnt_lines_clr : std_logic;
 	signal cnt_lines_ce  : std_logic;

begin

	cnt_linesp : process(RGB_CLK, cnt_lines_ce, cnt_lines_clr)
	begin
		if rising_edge(RGB_CLK) then
			if cnt_lines_clr = '1' or RGB_RST = '1' then
				cnt_lines <= (others => '0');
			elsif cnt_lines_ce = '1' then
				cnt_lines <= cnt_lines + 1;
			end if;
		end if;
	end process;

	cnt_lines_ce  <= RGB_VLD and RGB_REQ and RGB_EOL;
	cnt_lines_clr <= RGB_VLD and RGB_REQ and RGB_EOF;

	--------------------------------
	
	CS_CLK    <= RGB_CLK;

	CS_VEC(0) <= '1';

	CS_VEC(1) <= RGB_RST;
	CS_VEC(9 downto  2) <= RGB_R;

	CS_VEC(10) <= RGB_EOL;
	CS_VEC(11) <= RGB_EOF;
	CS_VEC(19 downto 12) <= RGB_G;

	CS_VEC(20) <= RGB_VLD;
	CS_VEC(21) <= RGB_REQ;
	CS_VEC(22) <= RGB_REQ and RGB_VLD;
	CS_VEC(30 downto 23) <= RGB_B;

	CS_VEC(31) <= '1';

	CS_VEC(47 downto 32) <= cnt_lines;

end architecture;

