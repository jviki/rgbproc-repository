-- sync_gen.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.log2;

---
-- Generates SYNC_N just after LAST comes.
--           _   _   _   _   _   _   _
-- CLK    \_/ \_/ \_/ \_/ \_/ \_/ \_/ \
--               _
-- LAST   ______/ \____________________
--        _________                 ___
-- SYNC_N          \_______________/
--                 | SYNC_LEN = 4 |
--
---
entity sync_gen is
generic (
	SYNC_LEN : integer;
	DEBUG    : boolean := false
);
port (
	CLK    : in  std_logic;
	RST    : in  std_logic;
	LAST   : in  std_logic;
	SYNC_N : out std_logic;

	DBGOUT : out std_logic_vector(5 downto 0)
);
end entity;

---
-- Based on cnt_synclen counter.
-- When cnt_synclen >= SYNC_LEN nothing is generated.
--
-- The counter is set to value greater then SYNC_LEN.
-- When LAST is asserted, the cnt_synclen is cleared to zero.
--
-- Until cnt_synclen counts to SYNC_LEN the SYNC_N is asserted.
-- When the counter reachs (or exceeds) the value SYNC_LEN
-- the SYNC_N is deasserted.
--
-- The next LAST will clear it again to restart the generation.
---
architecture full of sync_gen is

	signal cnt_synclen     : std_logic_vector(log2(SYNC_LEN + 1) - 1 downto 0);
	signal cnt_synclen_ce  : std_logic;
	signal cnt_synclen_clr : std_logic;
	signal cnt_synclen_z   : std_logic;

begin

	cnt_synclenp : process(CLK, cnt_synclen_ce, cnt_synclen_clr)
	begin
		if rising_edge(CLK) then
			if cnt_synclen_z = '1' then
				cnt_synclen <= (others => '0');
			elsif cnt_synclen_clr = '1' then
				cnt_synclen <= (others => '1');
			elsif cnt_synclen_ce = '1' then
				cnt_synclen <= cnt_synclen + 1;
			end if;
		end if;
	end process;

	cnt_synclen_clr <= RST;
	cnt_synclen_z   <= LAST;
	cnt_synclen_ce  <= '1' when cnt_synclen < SYNC_LEN else '0';

	SYNC_N <= '0' when cnt_synclen < SYNC_LEN else '1';

	--------------------------------------------------

gen_debug: if DEBUG = true
generate
	DBGOUT(0) <= cnt_synclen_z;
	DBGOUT(1) <= cnt_synclen_clr;
	DBGOUT(2) <= cnt_synclen_ce;
	DBGOUT(3) <= RST;
	DBGOUT(4) <= LAST;
	DBGOUT(5) <= SYNC_N;
end generate;

end architecture;

