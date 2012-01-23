-- rgb_invert.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>
-- Copyright (C) 2011, 2012 Jan Viktorin

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

---
-- Performs bitwise invert of each channel.
---
entity rgb_invert is
port (
	CLK      : in  std_logic;
	CE       : in  std_logic;

	IN_R     : in  std_logic_vector(7 downto 0);
	IN_G     : in  std_logic_vector(7 downto 0);
	IN_B     : in  std_logic_vector(7 downto 0);
	IN_DE    : in  std_logic;
	IN_HS    : in  std_logic;
	IN_VS    : in  std_logic;
		
	OUT_R    : out std_logic_vector(7 downto 0);
	OUT_G    : out std_logic_vector(7 downto 0);
	OUT_B    : out std_logic_vector(7 downto 0);
	OUT_DE   : out std_logic;
	OUT_HS   : out std_logic;
	OUT_VS   : out std_logic
);
end entity;

---
-- Introduces 1 CLK delay.
---
architecture full of rgb_invert is
begin

	invertp : process(CLK, CE)
	begin
		if rising_edge(CLK) then
			if CE = '1' then
				OUT_R  <= not IN_R;
				OUT_G  <= not IN_G;
				OUT_B  <= not IN_B;
				OUT_DE <= IN_DE;
				OUT_HS <= IN_HS;
				OUT_VS <= IN_VS;
			end if;
		end if;
	end process;

end architecture;
