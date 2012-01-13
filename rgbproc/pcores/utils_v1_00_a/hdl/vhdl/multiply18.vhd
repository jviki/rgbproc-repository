-- multiply18.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

---
-- Multiplication of 18 bit data with bypass
-- line for related control signals (CTL).
---
entity multiply18 is
generic (
	CTL_WIDTH : integer := 3
);
port (
	CLK  : in  std_logic;
	CE   : in  std_logic;
	A    : in  std_logic_vector(17 downto 0);
	B    : in  std_logic_vector(17 downto 0);
	P    : out std_logic_vector(35 downto 0);
	CTLI : in  std_logic_vector(CTL_WIDTH - 1 downto 0);
	CTLO : out std_logic_vector(CTL_WIDTH - 1 downto 0)
);
end entity;

architecture full of multiply18 is

	component mult_impl18
		port (
		clk: in std_logic;
		ce: in std_logic;
		a: in std_logic_vector(17 downto 0);
		b: in std_logic_vector(17 downto 0);
		p: out std_logic_vector(35 downto 0));
	end component;

	-- Synplicity black box declaration
	attribute syn_black_box : boolean;
	attribute syn_black_box of mult_impl18: component is true;

	constant MULT_DELAY : integer := 3;

begin

	impl_i : mult_impl18
	port map (
		CLK => CLK,
		CE  => CE,
		A   => A,
		B   => B,
		P   => P		
	);

	bypass_i : entity work.ctl_bypass
	generic map (
		DWIDTH => CTL_WIDTH,
		DEPTH  => MULT_DELAY
	)
	port map (
		CLK => CLK,
		CE  => CE,
		DI  => CTLI,
		DO  => CTLO
	);

end architecture;
