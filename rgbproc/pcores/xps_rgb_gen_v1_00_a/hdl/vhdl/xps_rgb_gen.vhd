-- xps_rgb_watch.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library xps_buff_strategy_v1_00_a;
use xps_buff_strategy_v1_00_a.end_gen;

entity xps_rgb_watch is
port (
	RGB_CLK : in  std_logic;
	RGB_RST : in  std_logic;
	RGB_R   : in  std_logic_vector(7 downto 0);
	RGB_G   : in  std_logic_vector(7 downto 0);
	RGB_B   : in  std_logic_vector(7 downto 0);
	RGB_EOL : in  std_logic;
	RGB_EOF : in  std_logic;
	RGB_VLD : out std_logic;
	RGB_REQ : in  std_logic
);
end entity;

architecture wrapper of xps_rgb_watch is

	signal cnt_color_ce  : std_logic;
	signal cnt_color_clr : std_logic;
	signal cnt_color     : std_logic_vector(7 downto 0);

	signal eol : std_logic;
	signal eof : std_logic; 

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

	cnt_color_ce  <= eol;
	cnt_color_clr <= eof;

	---------------------------------
	
	end_gen_i : entity xps_buff_strategy_v1_00_a.end_gen
	port map (
		CLK     => RGB_CLK,
		RST     => RGB_RST,
		PX_VLD  => RGB_REQ,
		OUT_EOL => eol,
		OUT_EOF => eof
	);
	
	---------------------------------

	RGB_VLD <= '1';
	RGB_EOL <= eol
	RGB_EOF <= eof;

	RGB_R   <= cnt_color;
	RGB_G   <= cnt_color;
	RGB_B   <= cnt_color;
	
end architecture;

