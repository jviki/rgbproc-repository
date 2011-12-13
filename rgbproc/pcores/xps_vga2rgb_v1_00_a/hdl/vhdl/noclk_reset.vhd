-- noclk_reset.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity noclk_reset is
generic (
	-- (faster)  (slower)
	-- REF_CLK / NO_CLK
	CLK_RATIO : integer := 4
);
port (
	REF_CLK : in  std_logic;
	REF_RST : in  std_logic;
	NO_CLK	: in  std_logic;
	GEN_RST : out std_logic
);
end entity;

architecture full of noclk_reset is

	---
	-- Wait for more then 1 CLK of NO_CLK...
	---
	constant WAIT_CLK : integer := CLK_RATIO * 8;

	signal shreg    : std_logic_vector(WAIT_CLK - 1 downto 0);

	signal cross_in : std_logic_vector(CLK_RATIO - 1 downto 0);
	signal clk_in   : std_logic;

begin

	---
	-- Cross domain register line.
	---
	cross_inp : process(REF_CLK, NO_CLK)
	begin
		if rising_edge(REF_CLK) then
			if REF_RST = '1' then
				cross_in <= (others => '0');
				clk_in   <= '0';
			else
				for i in 0 to CLK_RATIO - 1 loop
					if i = 0 then
						cross_in(0) <= NO_CLK;
					else
						cross_in(i) <= cross_in(i - 1);
					end if;
				end loop;

				clk_in <= cross_in(cross_in'length - 1);
			end if;
		end if;
	end process;

	---
	-- No clock detection using the shift register.
	---
	shregp : process(REF_CLK, clk_in, REF_RST)
	begin
		if rising_edge(REF_CLK) then
			if REF_RST = '1' then
				shreg <= (others => '0');
			else
				for i in 0 to WAIT_CLK - 1 loop
					if i = 0 then
						shreg(0) <= clk_in;
					else
						shreg(i) <= shreg(i - 1);
					end if;
				end loop;
			end if;
		end if;
	end process;

	GEN_RST <= '1' when shreg = 0 else '0';

end architecture;

