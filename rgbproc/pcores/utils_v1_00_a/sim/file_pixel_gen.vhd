-- file_pixel_gen.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>
-- Copyright (C) 2011, 2012 Jan Viktorin

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

use std.textio.all;

entity file_pixel_gen is
generic (
	WIDTH  : integer;
	HEIGHT : integer
);
port (
	CLK    : in  std_logic;
	RST    : in  std_logic;
	R      : out std_logic_vector(7 downto 0);
	G      : out std_logic_vector(7 downto 0);
	B      : out std_logic_vector(7 downto 0);
	PX_REQ : in  std_logic
);
end entity;

architecture plain_numbers of file_pixel_gen is
begin

	read_file : process(CLK, RST, PX_REQ)
		file infile : text;
		variable l  : line;
		variable vr : integer;
		variable vg : integer;
		variable vb : integer;

		procedure read_pixel is
		begin
			readline(infile, l);
			read(l, vr);
			read(l, vg);
			read(l, vb);

			R <= conv_std_logic_vector(vr, 8);
			G <= conv_std_logic_vector(vg, 8);
			B <= conv_std_logic_vector(vb, 8);
		end procedure;
	begin
		if rising_edge(CLK) then
			if RST = '1' or endfile(infile) then
				file_close(infile);
				file_open(infile, "input_file.txt", READ_MODE);
				read_pixel;
			elsif PX_REQ = '1' then
				read_pixel;
			end if;
		end if;
	end process;

end architecture;

