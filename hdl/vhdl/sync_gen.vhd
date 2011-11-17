-- sync_gen.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;

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
);
port (
	CLK    : in  std_logic;
	RST    : in  std_logic;
	LAST   : in  std_logic;
	SYNC_N : out std_logic	
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

begin

	cnt_synclenp : process(CLK, cnt_synclen_ce, cnt_synclen_clr)
	begin
		if rising_edge(CLK) then
			if cnt_synclen_clr = '1' then
				cnt_synclen <= (others => '1');
			elsif cnt_synclen_ce = '1' then
				cnt_synclen <= cnt_synclen + 1;
			end if;
		end if;
	end process;

	cnt_synclen_clr <= LAST or RST;
	cnt_synclen_ce  <= '1' when cnt_synclen < SYNC_LEN else '0';

	SYNC_N <= '0' when cnt_synclen < SYNC_LEN else '1';

end architecture;

