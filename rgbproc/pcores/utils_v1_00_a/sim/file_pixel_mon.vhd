-- file_pixel_mo.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

use std.textio.all;

entity file_pixel_mon is
port (
	CLK : in  std_logic;
	RST : in  std_logic;
	R   : in  std_logic_vector(7 downto 0);
	G   : in  std_logic_vector(7 downto 0);
	B   : in  std_logic_vector(7 downto 0);
	DE  : in  std_logic;
	HS  : in  std_logic;
	VS  : in  std_logic
);
end entity;

architecture plain_numbers of file_pixel_mon is

	file allfile : text open WRITE_MODE is "output_file.txt";

begin

	write_file : process(CLK, RST, DE, R, G, B)
		file outfile : text;
		variable l0  : line;
		variable l1  : line;
		variable vr  : integer;
		variable vg  : integer;
		variable vb  : integer;
		variable id  : integer := 0;

		procedure write_pixel is
		begin
			write(l0, vr);
			write(l1, vr);
			write(l0, string'(" "));
			write(l1, string'(" "));
			write(l0, vg);
			write(l1, vg);
			write(l0, string'(" "));
			write(l1, string'(" "));
			write(l0, vb);
			write(l1, vb);
			writeline(outfile, l0);
			writeline(allfile, l1);
		end procedure;
	begin
		if rising_edge(CLK) then
			if RST = '1' or VS = '0' then
				file_close(outfile);
				file_open(outfile, "output_file-" & integer'image(id) &  ".txt", WRITE_MODE);
			elsif DE = '1' then
				vr := conv_integer(R);
				vg := conv_integer(G);
				vb := conv_integer(B);
				write_pixel;
			end if;
		end if;
	end process;

end architecture;

