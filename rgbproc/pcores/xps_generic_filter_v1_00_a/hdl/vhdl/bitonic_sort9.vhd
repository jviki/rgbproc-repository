-- bitonic_sort9.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity bitonic_sort9 is
generic (
	LEVEL : integer := -1		
);
port (
	CLK : in  std_logic;
	CE  : in  std_logic;
	DI  : in  std_logic_vector(9 * 8 - 1 downto 0);
	DO  : out std_logic_vector(9 * 8 - 1 downto 0)
);
end entity;

---
-- Pipeline level of the bitonic_sort9 unit.
-- For every LEVEL in range 0..7 generates apropriate cmp_swap units
-- and pipeline registers.
--
-- See paper Novel Hardware Implementation of Adaptive Median Filters
--        at http://www.fit.vutbr.cz/research/view_pub.php.cs?id=8604.
---
architecture level_x of bitonic_sort9 is
begin

	assert LEVEL >= 0 and LEVEL <= 7
		report "Invalid LEVEL of bitonic_sort9(level_x): " & integer'image(LEVEL)
		severity failure;

-----------------------------------------
-----------------------------------------
-----------------------------------------

gen_level0: if LEVEL = 0
generate

	swap_10_i : entity work.cmp_swap
	port (
		CLK => CLK,
		CE  => CE,
		I_A => DI(15 downto 8),
		I_B => DI( 7 downto 0),
		O_A => DO(15 downto 8),
		O_B => DO( 7 downto 0)
	);

	swap_23_i : entity work.cmp_swap
	port (
		CLK => CLK,
		CE  => CE,
		I_A => DI(23 downto 16),
		I_B => DI(31 downto 24),
		O_A => DO(23 downto 16),
		O_B => DO(31 downto 24)
	);

	swap_45_i : entity work.cmp_swap
	port (
		CLK => CLK,
		CE  => CE,
		I_A => DI(39 downto 32),
		I_B => DI(47 downto 40),
		O_A => DO(39 downto 32),
		O_B => DO(47 downto 40)
	);

	reg_6p : process(CLK, CE, DI)
	begin
		if rising_edge(CLK) then
			if CE = '1' then
				DO(55 downto 48) <= DI(55 downto 48);
			end if;
		end if;
	end process;

	swap_87_i : entity work.cmp_swap
	port (
		CLK => CLK,
		CE  => CE,
		I_A => DI(71 downto 64),
		I_B => DI(63 downto 56),
		O_A => DO(71 downto 64),
		O_B => DO(63 downto 56)
	);

end generate;

-----------------------------------------
-----------------------------------------
-----------------------------------------

gen_level1: if LEVEL = 1
generate

	swap_02_i : entity work.cmp_swap
	port (
		CLK => CLK,
		CE  => CE,
		I_A => DI( 7 downto  0),
		I_B => DI(23 downto 16),
		O_A => DO( 7 downto  0),
		O_B => DO(23 downto 16)
	);

	swap_13_i : entity work.cmp_swap
	port (
		CLK => CLK,
		CE  => CE,
		I_A => DI(15 downto  8),
		I_B => DI(31 downto 24),
		O_A => DO(15 downto  8),
		O_B => DO(31 downto 24)
	);

	reg_457p : process(CLK, CE, DI)
	begin
		if rising_edge(CLK) then
			if CE = '1' then
				DO(47 downto 32) <= DI(47 downto 32);
				DO(63 downto 56) <= DI(63 downto 56);
			end if;
		end if;
	end process;

	swap_86_i : entity work.cmp_swap
	port (
		CLK => CLK,
		CE  => CE,
		I_A => DI(71 downto 64),
		I_B => DI(55 downto 48),
		O_A => DO(71 downto 64),
		O_B => DO(55 downto 48)
	);

end generate;

-----------------------------------------
-----------------------------------------
-----------------------------------------

gen_level2: if LEVEL = 2
generate

	swap_01_i : entity work.cmp_swap
	port (
		CLK => CLK,
		CE  => CE,
		I_A => DI( 7 downto  0),
		I_B => DI(15 downto  8),
		O_A => DO( 7 downto  0),
		O_B => DO(15 downto  8)
	);

	swap_23_i : entity work.cmp_swap
	port (
		CLK => CLK,
		CE  => CE,
		I_A => DI(23 downto 16),
		I_B => DI(31 downto 24),
		O_A => DO(23 downto 16),
		O_B => DO(31 downto 24)
	);

	swap_84_i : entity work.cmp_swap
	port (
		CLK => CLK,
		CE  => CE,
		I_A => DI(71 downto 64),
		I_B => DI(39 downto 32),
		O_A => DO(71 downto 64),
		O_B => DO(39 downto 32)
	);

	reg_5p : process(CLK, CE, DI)
	begin
		if rising_edge(CLK) then
			if CE = '1' then
				DO(47 downto 40) <= DI(47 downto 40);
			end if;
		end if;
	end process;

	swap_76_i : entity work.cmp_swap
	port (
		CLK => CLK,
		CE  => CE,
		I_A => DI(63 downto 56),
		I_B => DI(55 downto 48),
		O_A => DO(63 downto 56),
		O_B => DO(55 downto 48)
	);

end generate;

-----------------------------------------
-----------------------------------------
-----------------------------------------

gen_level3: if LEVEL = 3
generate

	swap_80_i : entity work.cmp_swap
	port (
		CLK => CLK,
		CE  => CE,
		I_A => DI(71 downto 64),
		I_B => DI( 7 downto  0),
		O_A => DO(71 downto 64),
		O_B => DO( 7 downto  0)
	);

	reg_123p : process(CLK, CE, DI)
	begin
		if rising_edge(CLK) then
			if CE = '1' then
				DO(47 downto  8) <= DI(47 downto  8);
			end if;
		end if;
	end process;

	swap_64_i : entity work.cmp_swap
	port (
		CLK => CLK,
		CE  => CE,
		I_A => DI(55 downto 48),
		I_B => DI(39 downto 32),
		O_A => DO(55 downto 48),
		O_B => DO(39 downto 32)
	);

	swap_75_i : entity work.cmp_swap
	port (
		CLK => CLK,
		CE  => CE,
		I_A => DI(63 downto 56),
		I_B => DI(47 downto 40),
		O_A => DO(63 downto 56),
		O_B => DO(47 downto 40)
	);

end generate;

-----------------------------------------
-----------------------------------------
-----------------------------------------

gen_level4: if LEVEL = 4
generate

	reg_01238p : process(CLK, CE, DI)
	begin
		if rising_edge(CLK) then
			if CE = '1' then
				DO(31 downto  0) <= DI(31 downto  0);
				DO(71 downto 64) <= DI(71 downto 64);
			end if;
		end if;
	end process;

	swap_54_i : entity work.cmp_swap
	port (
		CLK => CLK,
		CE  => CE,
		I_A => DI(47 downto 40),
		I_B => DI(39 downto 32),
		O_A => DO(47 downto 40),
		O_B => DO(39 downto 32)
	);

	swap_76_i : entity work.cmp_swap
	port (
		CLK => CLK,
		CE  => CE,
		I_A => DI(63 downto 56),
		I_B => DI(55 downto 48),
		O_A => DO(63 downto 56),
		O_B => DO(55 downto 48)
	);

end generate;

-----------------------------------------
-----------------------------------------
-----------------------------------------

gen_level5: if LEVEL = 5
generate

	swap_40_i : entity work.cmp_swap
	port (
		CLK => CLK,
		CE  => CE,
		I_A => DI(39 downto 32),
		I_B => DI( 7 downto  0),
		O_A => DO(39 downto 32),
		O_B => DO( 7 downto  0)
	);

	swap_51_i : entity work.cmp_swap
	port (
		CLK => CLK,
		CE  => CE,
		I_A => DI(47 downto 40),
		I_B => DI(15 downto  8),
		O_A => DO(47 downto 40),
		O_B => DO(15 downto  8)
	);

	swap_62_i : entity work.cmp_swap
	port (
		CLK => CLK,
		CE  => CE,
		I_A => DI(55 downto 48),
		I_B => DI(23 downto 16),
		O_A => DO(55 downto 48),
		O_B => DO(23 downto 16)
	);

	swap_73_i : entity work.cmp_swap
	port (
		CLK => CLK,
		CE  => CE,
		I_A => DI(63 downto 56),
		I_B => DI(31 downto 24),
		O_A => DO(63 downto 56),
		O_B => DO(31 downto 24)
	);

	reg_8p : process(CLK, CE, DI)
	begin
		if rising_edge(CLK) then
			if CE = '1' then
				DO(71 downto 64) <= DI(71 downto 64);
			end if;
		end if;
	end process;

end generate;

-----------------------------------------
-----------------------------------------
-----------------------------------------

gen_level6: if LEVEL = 6
generate

	swap_20_i : entity work.cmp_swap
	port (
		CLK => CLK,
		CE  => CE,
		I_A => DI(23 downto 16),
		I_B => DI( 7 downto  0),
		O_A => DO(23 downto 16),
		O_B => DO( 7 downto  0)
	);

	swap_31_i : entity work.cmp_swap
	port (
		CLK => CLK,
		CE  => CE,
		I_A => DI(31 downto 24),
		I_B => DI(15 downto  8),
		O_A => DO(31 downto 24),
		O_B => DO(15 downto  8)
	);

	swap_46_i : entity work.cmp_swap
	port (
		CLK => CLK,
		CE  => CE,
		I_A => DI(39 downto 32),
		I_B => DI(55 downto 48),
		O_A => DO(39 downto 32),
		O_B => DO(55 downto 48)
	);

	swap_57_i : entity work.cmp_swap
	port (
		CLK => CLK,
		CE  => CE,
		I_A => DI(47 downto 40),
		I_B => DI(63 downto 56),
		O_A => DO(47 downto 40),
		O_B => DO(63 downto 56)
	);

	reg_8p : process(CLK, CE, DI)
	begin
		if rising_edge(CLK) then
			if CE = '1' then
				DO(71 downto 64) <= DI(71 downto 64);
			end if;
		end if;
	end process;

end generate;

-----------------------------------------
-----------------------------------------
-----------------------------------------

gen_level7: if LEVEL = 7
generate

	swap_10_i : entity work.cmp_swap
	port (
		CLK => CLK,
		CE  => CE,
		I_A => DI(15 downto  8),
		I_B => DI( 7 downto  0),
		O_A => DO(15 downto  8),
		O_B => DO( 7 downto  0)
	);

	swap_32_i : entity work.cmp_swap
	port (
		CLK => CLK,
		CE  => CE,
		I_A => DI(31 downto 24),
		I_B => DI(23 downto 16),
		O_A => DO(31 downto 24),
		O_B => DO(23 downto 16)
	);

	swap_54_i : entity work.cmp_swap
	port (
		CLK => CLK,
		CE  => CE,
		I_A => DI(39 downto 32),
		I_B => DI(47 downto 40),
		O_A => DO(39 downto 32),
		O_B => DO(47 downto 40)
	);

	swap_76_i : entity work.cmp_swap
	port (
		CLK => CLK,
		CE  => CE,
		I_A => DI(63 downto 56),
		I_B => DI(55 downto 48),
		O_A => DO(63 downto 56),
		O_B => DO(55 downto 48)
	);

	reg_8p : process(CLK, CE, DI)
	begin
		if rising_edge(CLK) then
			if CE = '1' then
				DO(71 downto 64) <= DI(71 downto 64);
			end if;
		end if;
	end process;

end generate;

end architecture;

---
-- Top level creates 8 levels of smaller sorters.
-- Generic LEVEL is ignored and must be set to -1.
---
architecture top_level of bitonic_sort9 is

	type level_t is array(0 to 8) of std_logic_vector(7 downto 0);
	signal level : level_t;

begin

	assert LEVEL = -1
		report "Setting LEVEL for bitonic_sort9(top_level) does not make sense"
		severity failure;

	-----------------------------------------
	
	level(0) <= DI;
	DO <= level(8);
	
	-----------------------------------------

gen_levels: for i in 0 to 7
generate

	level_x_i : entity work.bitonic_sort9(level_x)
	generic map (
		LEVEL => i		
	)
	port map (
		CLK   => CLK,
		CE    => CE,
		DI    => level(i),
		DO    => level(i + 1)
	);

end generate;

end architecture;

