-- simple_pixel_gen.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity simple_pixel_gen is
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

architecture full of simple_pixel_gen is

	signal vga_r : std_logic_vector(7 downto 0);
	signal vga_g : std_logic_vector(7 downto 0);
	signal vga_b : std_logic_vector(7 downto 0);

begin

	process(CLK, RST, PX_REQ, vga_r, vga_g, vga_b)
	begin
		if rising_edge(CLK) then
			if RST = '1' or PX_REQ = '0' then
				vga_r <= (others => '0');
				vga_g <= (others => '0');
				vga_b <= (others => '0');
			elsif PX_REQ = '1' then
				vga_r <= vga_r + 1;
				vga_g <= vga_g + 1;
				vga_b <= vga_b + 1;
			end if;
		end if;
	end process;

	R <= vga_r;
	G <= vga_g;
	B <= vga_b;

end architecture;

