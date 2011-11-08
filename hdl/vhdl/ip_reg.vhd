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
	R_NEG_WE : in  std_logic
);
end entity;

architecture full of ip_reg is

	signal reg_neg    : std_logic_vector(31 downto 0);
	signal reg_neg_in : std_logic_vector(31 downto 0);
	signal reg_neg_we : std_logic;

begin

	reg_negp : process(CLK, RST, reg_neg_we, reg_neg_in)
	begin
		if rising_edge(CLK) then
			if RST = '1' then
				reg_neg <= (others => '1');
			elsif reg_neg_we = '1' then
				reg_neg <= not reg_neg_in;
			end if;
		end if;
	end process;

	reg_neg_in <= R_NEG_IN;
	reg_neg_we <= R_NEG_WE;

	--------------------------------------------------

	R_IP <= IP_ID & IP_VERSION;

end architecture;

