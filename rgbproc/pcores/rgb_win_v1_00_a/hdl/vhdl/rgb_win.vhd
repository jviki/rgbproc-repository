-- rgb_win.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity rgb_win is
generic (
	WIN_SIZE : integer := 3		
);
port (
	CLK     : in  std_logic;
	CE      : in  std_logic;

	ROW0_R  : in  std_logic_vector(WIN_SIZE * 8 - 1 downto 0);
	ROW0_G  : in  std_logic_vector(WIN_SIZE * 8 - 1 downto 0);
	ROW0_B  : in  std_logic_vector(WIN_SIZE * 8 - 1 downto 0);
	ROW0_DE : in  std_logic_vector(WIN_SIZE - 1 downto 0);
	ROW0_HS : in  std_logic_vector(WIN_SIZE - 1 downto 0);
	ROW0_VS : in  std_logic_vector(WIN_SIZE - 1 downto 0);

	ROW1_R  : in  std_logic_vector(WIN_SIZE * 8 - 1 downto 0);
	ROW1_G  : in  std_logic_vector(WIN_SIZE * 8 - 1 downto 0);
	ROW1_B  : in  std_logic_vector(WIN_SIZE * 8 - 1 downto 0);
	ROW1_DE : in  std_logic_vector(WIN_SIZE - 1 downto 0);
	ROW1_HS : in  std_logic_vector(WIN_SIZE - 1 downto 0);
	ROW1_VS : in  std_logic_vector(WIN_SIZE - 1 downto 0);

	ROW2_R  : in  std_logic_vector(WIN_SIZE * 8 - 1 downto 0);
	ROW2_G  : in  std_logic_vector(WIN_SIZE * 8 - 1 downto 0);
	ROW2_B  : in  std_logic_vector(WIN_SIZE * 8 - 1 downto 0);
	ROW2_DE : in  std_logic_vector(WIN_SIZE - 1 downto 0);
	ROW2_HS : in  std_logic_vector(WIN_SIZE - 1 downto 0);
	ROW2_VS : in  std_logic_vector(WIN_SIZE - 1 downto 0);

	WIN_R     : out std_logic_vector((WIN_SIZE ** 2) * 8 - 1 downto 0);
	WIN_G     : out std_logic_vector((WIN_SIZE ** 2) * 8 - 1 downto 0);
	WIN_B     : out std_logic_vector((WIN_SIZE ** 2) * 8 - 1 downto 0);
	WIN_DE    : out std_logic_vector((WIN_SIZE ** 2) - 1 downto 0);
	WIN_HS    : out std_logic_vector((WIN_SIZE ** 2) - 1 downto 0);
	WIN_VS    : out std_logic_vector((WIN_SIZE ** 2) - 1 downto 0)
);
end entity;

architecture rgb_win3 of rgb_win is
begin

	assert WIN_SIZE = 3
		report "Unsupported window size: " & integer'image(WIN_SIZE)
		severity failure;

	-------------------------------

	reg_winp : process(CLK, CE)
	begin
		if rising_edge(CLK) then
			if CE = '1' then
				WIN_R(23 downto  0) <= ROW0_R;
				WIN_G(23 downto  0) <= ROW0_G;
				WIN_B(23 downto  0) <= ROW0_B;
				WIN_DE(2 downto 0)  <= ROW0_DE;
				WIN_HS(2 downto 0)  <= ROW0_HS;
				WIN_VS(2 downto 0)  <= ROW0_VS;

				WIN_R(47 downto 24) <= ROW1_R;
				WIN_G(47 downto 24) <= ROW1_G;
				WIN_B(47 downto 24) <= ROW1_B;
				WIN_DE(5 downto 3)  <= ROW1_DE;
				WIN_HS(5 downto 3)  <= ROW1_HS;
				WIN_VS(5 downto 3)  <= ROW1_VS;

				WIN_R(71 downto 48) <= ROW2_R;
				WIN_G(71 downto 48) <= ROW2_G;
				WIN_B(71 downto 48) <= ROW2_B;
				WIN_DE(8 downto 6)  <= ROW2_DE;
				WIN_HS(8 downto 6)  <= ROW2_HS;
				WIN_VS(8 downto 6)  <= ROW2_VS;
			end if;
		end if;
	end process;

end architecture;

