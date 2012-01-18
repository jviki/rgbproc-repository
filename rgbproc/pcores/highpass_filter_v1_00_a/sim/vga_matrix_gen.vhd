-- vga_matrix_gen.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library rgb_gen_v1_00_a;
use rgb_gen_v1_00_a.rgbctl_gen;

entity vga_matrix_gen is
port (
	CLK    : in  std_logic;
	RST    : in  std_logic;
	R      : out std_logic_vector(71 downto 0);
	G      : out std_logic_vector(71 downto 0);
	B      : out std_logic_vector(71 downto 0);
	HS     : out std_logic_vector(8 downto 0);
	VS     : out std_logic_vector(8 downto 0);
	DE     : out std_logic_vector(8 downto 0)
);
end entity;

architecture full of vga_matrix_gen is

	signal hs_vec : std_logic_vector(8 downto 0);
	signal vs_vec : std_logic_vector(8 downto 0);
	signal de_vec : std_logic_vector(8 downto 0);

	signal hs_in  : std_logic;
	signal vs_in  : std_logic;
	signal de_in  : std_logic;

begin

	matrix_gen_i : entity work.matrix_pixel_gen
	port map (
		CLK => CLK,
		RST => RST,
		R   => R,
		G   => G,
		B   => B,
		PX_REQ => de_vec(4)
	);

	rgbctl_gen_i : entity rgb_gen_v1_00_a.rgbctl_gen
	port map (
		CLK => CLK,
		RST => RST,
		HS  => hs_in,
		VS  => vs_in,
		DE  => de_in
	);

	HS <= hs_vec;
	VS <= vs_vec;
	DE <= de_vec;

	ctl_shiftp : process(CLK, RST, hs_in, vs_in, de_in)
	begin
		if rising_edge(CLK) then
			for i in hs_vec'range loop
				if i = 0 then
					hs_vec(i) <= hs_in;
					vs_vec(i) <= vs_in;
					de_vec(i) <= de_in;
				else
					hs_vec(i) <= hs_vec(i - 1);
					vs_vec(i) <= vs_vec(i - 1);
					de_vec(i) <= de_vec(i - 1);
				end if;
			end loop;
		end if;
	end process;

end architecture;
