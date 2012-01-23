-- matrix_pixel_gen.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>
-- Copyright (C) 2011, 2012 Jan Viktorin

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

use std.textio.all;

entity matrix_pixel_gen is
port (
	CLK    : in  std_logic;
	RST    : in  std_logic;
	R      : out std_logic_vector(71 downto 0);
	G      : out std_logic_vector(71 downto 0);
	B      : out std_logic_vector(71 downto 0);
	PX_REQ : in  std_logic
);
end entity;

architecture plain_numbers of matrix_pixel_gen is
begin

	read_file : process(CLK, RST, PX_REQ)
		file infile : text;
		variable l  : line;
		variable vr0 : integer;
		variable vg0 : integer;
		variable vb0 : integer;
		variable vr1 : integer;
		variable vg1 : integer;
		variable vb1 : integer;
		variable vr2 : integer;
		variable vg2 : integer;
		variable vb2 : integer;
		variable vr3 : integer;
		variable vg3 : integer;
		variable vb3 : integer;
		variable vr4 : integer;
		variable vg4 : integer;
		variable vb4 : integer;
		variable vr5 : integer;
		variable vg5 : integer;
		variable vb5 : integer;
		variable vr6 : integer;
		variable vg6 : integer;
		variable vb6 : integer;
		variable vr7 : integer;
		variable vg7 : integer;
		variable vb7 : integer;
		variable vr8 : integer;
		variable vg8 : integer;
		variable vb8 : integer;

		procedure read_matrix is
		begin
			readline(infile, l);
			read(l, vr0); read(l, vg0); read(l, vb0);
			read(l, vr1); read(l, vg1); read(l, vb1);
			read(l, vr2); read(l, vg2); read(l, vb2);
			read(l, vr3); read(l, vg3); read(l, vb3);
			read(l, vr4); read(l, vg4); read(l, vb4);
			read(l, vr5); read(l, vg5); read(l, vb5);
			read(l, vr6); read(l, vg6); read(l, vb6);
			read(l, vr7); read(l, vg7); read(l, vb7);
			read(l, vr8); read(l, vg8); read(l, vb8);

			R( 7 downto  0) <= conv_std_logic_vector(vr0, 8);
			G( 7 downto  0) <= conv_std_logic_vector(vg0, 8);
			B( 7 downto  0) <= conv_std_logic_vector(vb0, 8);
			R(15 downto  8) <= conv_std_logic_vector(vr1, 8);
			G(15 downto  8) <= conv_std_logic_vector(vg1, 8);
			B(15 downto  8) <= conv_std_logic_vector(vb1, 8);
			R(23 downto 16) <= conv_std_logic_vector(vr2, 8);
			G(23 downto 16) <= conv_std_logic_vector(vg2, 8);
			B(23 downto 16) <= conv_std_logic_vector(vb2, 8);
			R(31 downto 24) <= conv_std_logic_vector(vr3, 8);
			G(31 downto 24) <= conv_std_logic_vector(vg3, 8);
			B(31 downto 24) <= conv_std_logic_vector(vb3, 8);
			R(39 downto 32) <= conv_std_logic_vector(vr4, 8);
			G(39 downto 32) <= conv_std_logic_vector(vg4, 8);
			B(39 downto 32) <= conv_std_logic_vector(vb4, 8);
			R(47 downto 40) <= conv_std_logic_vector(vr5, 8);
			G(47 downto 40) <= conv_std_logic_vector(vg5, 8);
			B(47 downto 40) <= conv_std_logic_vector(vb5, 8);
			R(55 downto 48) <= conv_std_logic_vector(vr6, 8);
			G(55 downto 48) <= conv_std_logic_vector(vg6, 8);
			B(55 downto 48) <= conv_std_logic_vector(vb6, 8);
			R(63 downto 56) <= conv_std_logic_vector(vr7, 8);
			G(63 downto 56) <= conv_std_logic_vector(vg7, 8);
			B(63 downto 56) <= conv_std_logic_vector(vb7, 8);
			R(71 downto 64) <= conv_std_logic_vector(vr8, 8);
			G(71 downto 64) <= conv_std_logic_vector(vg8, 8);
			B(71 downto 64) <= conv_std_logic_vector(vb8, 8);
		end procedure;
	begin
		if rising_edge(CLK) then
			if RST = '1' or endfile(infile) then
				file_close(infile);
				file_open(infile, "input_file.txt", READ_MODE);
				read_matrix;
			elsif PX_REQ = '1' then
				read_matrix;
			end if;
		end if;
	end process;

end architecture;

