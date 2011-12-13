-- clk_is_up.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.log2;

entity clk_is_up is
generic (
	MAX_DELAY : integer
);
port (
	CLK     : in  std_logic;
	RST     : in  std_logic;
	IN_CLK  : in  std_logic;
	OUT_UP  : out std_logic
);
end entity;

architecture full of clk_is_up is

	signal reg_change     : std_logic;
	signal reg_change_clr : std_logic;

	signal reg_change_vec : std_logic_vector(1 downto 0);
	
	signal cnt_delay_ce   : std_logic;
	signal cnt_delay      : std_logic_vector(log2(MAX_DELAY) - 1 downto 0);

begin

	OUT_UP  <= reg_change_vec(1);

	---------------------------------------

	reg_changep : process(IN_CLK, reg_change_clr)
	begin
		if rising_edge(IN_CLK) then
			reg_change     <= '1';
		elsif reg_change_clr = '1' then
			reg_change <= '0';
		end if;
	end process;

	reg_change_clr <= '1' when cnt_delay = (cnt_delay'range => '0') else RST;

	---------------------------------------

	cnt_delayp : process(CLK, cnt_delay_ce)
	begin
		if rising_edge(CLK) then
			if RST = '1' then
				cnt_delay <= (others => '0');
			elsif cnt_delay_ce = '1' then
				cnt_delay <= cnt_delay + 1;
			end if;
		end if;
	end process;

	cnt_delay_ce <= '1';

	---------------------------------------

	reg_change_vecp : process(CLK, reg_change)
	begin
		if rising_edge(CLK) then
			reg_change_vec(1) <= reg_change_vec(0);
			reg_change_vec(0) <= reg_change;
		end if;
	end process;

end architecture;

