-- cmp_swap.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity cmp_swap is
generic (
	SWAP_ON_A_GT_B : boolean := true
);
port (
	CLK : in  std_logic;
	CE  : in  std_logic;
	I_A : in  std_logic_vector(7 downto 0);
	I_B : in  std_logic_vector(7 downto 0);
	O_A : out std_logic_vector(7 downto 0);
	O_B : out std_logic_vector(7 downto 0)
);
end entity;

architecture full of cmp_swap is

	function bool2bit(b : boolean) return std_logic is
	begin
		if b then
			return '1';
		else
			return '0';
		end if;
	end function;
	constant EXPECTED_CMP_A_GT_B := bool2bit(SWAP_ON_A_GT_B);
	signal cmp_a_gt_b : std_logic;

	signal a_out      : std_logic_vector(7 downto 0);
	signal b_out      : std_logic_vector(7 downto 0);

begin

	cmp_a_gt_b <= '1' when IN_A > IN_B else '0';

	a_out <= I_A when cmp_a_gt_b = EXPECTED_CMP_A_GT_B else
	         I_B;

	b_out <= I_A when cmp_a_gt_b = not EXPECTED_CMP_A_GT_B else
	         I_B;

	process(CLK, CE)
	begin
		if rising_edge(CLK) then
			if CE = '1' then
				O_A <= a_out;
				O_B <= b_out;
			end if;
		end if;
	end process;

end architecture;

