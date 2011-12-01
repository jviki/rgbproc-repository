-- rgb_row3.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity rgb_row3 is
port (
	CLK    : in  std_logic;
	RST    : in  std_logic;
	IN_R   : in  std_logic_vector(7 downto 0);
	IN_G   : in  std_logic_vector(7 downto 0);
	IN_B   : in  std_logic_vector(7 downto 0);
	IN_WE  : in  std_logic

	LAST_R : out std_logic_vector(7 downto 0);
	LAST_G : out std_logic_vector(7 downto 0);
	LAST_B : out std_logic_vector(7 downto 0);

	OUT_R  : out std_logic_vector(3 * 8 - 1 downto 0);
	OUT_G  : out std_logic_vector(3 * 8 - 1 downto 0);
	OUT_B  : out std_logic_vector(3 * 8 - 1 downto 0)
);
end entity;

architecture shift_reg of rgb_row3 is

	signal reg_row_r : std_logic_vector(3 * 8 - 1 downto 0);
	signal reg_row_g : std_logic_vector(3 * 8 - 1 downto 0);
	signal reg_row_b : std_logic_vector(3 * 8 - 1 downto 0);

	signal row_r_in  : std_logic_vector(7 downto 0);
	signal row_g_in  : std_logic_vector(7 downto 0);
	signal row_b_in  : std_logic_vector(7 downto 0);

	signal row_we    : std_logic;

begin

	sh_reg : process(CLK, row_r_in, row_g_in, row_b_in)
	begin
		if rising_edge(CLK) then
			if row_we = '1' then
				reg_row_r(23 downto 16) <= row_r_in;
				reg_row_g(23 downto 16) <= row_g_in;
				reg_row_b(23 downto 16) <= row_b_in;

				reg_row_r(15 downto  8) <= reg_row_r(23 downto 16);
				reg_row_g(15 downto  8) <= reg_row_g(23 downto 16);
				reg_row_b(15 downto  8) <= reg_row_b(23 downto 16);

				reg_row_r( 7 downto  0) <= reg_row_r(15 downto  8);
				reg_row_g( 7 downto  0) <= reg_row_g(15 downto  8);
				reg_row_b( 7 downto  0) <= reg_row_b(15 downto  8);
			end if;
		end if;
	end process;

	row_we   <= IN_WE;
	row_r_in <= IN_R;
	row_g_in <= IN_G;
	row_b_in <= IN_B;

	LAST_R   <= reg_row_r(23 downto 16);
	LAST_G   <= reg_row_g(23 downto 16);
	LAST_B   <= reg_row_b(23 downto 16);

	OUT_R    <= reg_row_r;
	OUT_G    <= reg_row_g;
	OUT_B    <= reg_row_b;

end architecture;

