-- plbv46_config_bus.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity ip_reg is
generic (
	IP_ID      : std_logic_vector(15 downto 0);
	IP_VERSION : std_logic_vector(15 downto 0)
);
port (
	CLK      : in std_logic;
	RST      : in std_logic;

	R_IP     : out std_logic_vector(31 downto 0);
	R_NEG    : out std_logic_vector(31 downto 0);
	R_NEG_IN : in  std_logic_vector(31 downto 0);
	R_NEG_BE : in  std_logic_vector(3 downto 0);
	R_NEG_WE : in  std_logic
);
end entity;

architecture full of ip_reg is

	signal reg_neg    : std_logic_vector(31 downto 0);
	signal reg_neg_in : std_logic_vector(31 downto 0);
	signal reg_neg_be : std_logic_vector(3 downto 0);
	signal reg_neg_we : std_logic;

begin

	reg_negp : process(CLK, RST, reg_neg_we, reg_neg_in, reg_neg_be)
	begin
		if rising_edge(CLK) then
			if RST = '1' then
				reg_neg <= (others => '1');
			elsif reg_neg_we = '1' then
				if reg_neg_be(3) = '1' then
					reg_neg(31 downto 24) <= not reg_neg_in(31 downto 24);
				end if;

				if reg_neg_be(2) = '1' then
					reg_neg(23 downto 16) <= not reg_neg_in(23 downto 16);
				end if;

				if reg_neg_be(1) = '1' then
					reg_neg(15 downto  8) <= not reg_neg_in(15 downto  8);
				end if;

				if reg_neg_be(0) = '1' then
					reg_neg( 7 downto  0) <= not reg_neg_in( 7 downto  0);
				end if;
			end if;
		end if;
	end process;

	reg_neg_in <= R_NEG_IN;
	reg_neg_be <= R_NEG_BE;
	reg_neg_we <= R_NEG_WE;

	--------------------------------------------------

	R_IP <= IP_ID & IP_VERSION;

end architecture;

