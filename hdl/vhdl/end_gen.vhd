-- end_gen.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.log2;

entity end_gen is
generic (
	WIDTH  : integer := 640;
	HEIGHT : integer := 480
);
port (
	CLK     : in  std_logic;
	RST     : in  std_logic;

	PX_VLD  : in  std_logic;
	OUT_EOL : out std_logic;
	OUT_EOF : out std_logic
);
end entity;

architecture full of end_gen is
	
	signal cnt_pixels_ce  : std_logic;
	signal cnt_pixels_clr : std_logic;
	signal cnt_pixels     : std_logic_vector(log2(WIDTH) downto 0);

	signal cnt_lines_ce  : std_logic;
	signal cnt_lines_clr : std_logic;
	signal cnt_lines     : std_logic_vector(log2(HEIGHT) downto 0);

begin

	OUT_EOL <= '1' when cnt_pixels = WIDTH  else '0';
	OUT_EOF <= '1' when cnt_lines  = HEIGHT else '0';

	cnt_pixelsp : process(CLK, cnt_pixels_ce, cnt_pixels_clr, RST)
	begin
		if rising_edge(CLK) then
			if RST = '1' or cnt_pixels_clr = '1' then
				cnt_pixels <= (others => '0');
			elsif cnt_pixels_ce = '1' then
				cnt_pixels <= cnt_pixels + 1;
			end if;
		end if;
	end process;

	cnt_pixels_ce  <= PX_VLD;
	cnt_pixels_clr <= PX_VLD when cnt_pixels = WIDTH else '0';

	cnt_linesp : process(CLK, cnt_lines_ce, cnt_lines_clr, RST)
	begin
		if rising_edge(CLK) then
			if RST = '1' or cnt_lines_clr = '1' then
				cnt_lines <= (others => '0');
			elsif cnt_lines_ce = '1' then
				cnt_lines <= cnt_lines + 1;
			end if;
		end if;
	end process;

	cnt_lines_ce  <= PX_VLD when cnt_pixels = WIDTH else '0';
	cnt_lines_clr <= PX_VLD when cnt_pixels = WIDTH and cnt_lines = HEIGHT else '0';

end architecture;



