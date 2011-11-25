-- active_detect.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.log2;

---
-- Detects active phase in which the data (pixels) are passed. 
--        ___      _______________________________________      __
-- SYNC_N    \____/                                       \____/
--                         _______________________
-- ACTIVE ________________/                       \_______________
--                |BEG_OFF|                       |END_OFF|     
--                |================ LENGTH ===============|
--                         _
-- FIRST _________________/ \_____________________________________
--                                               _
-- LAST  _______________________________________/ \_______________
--
-- Does not solve problem when the SYNC_N comes earlier (should not happen).
---
entity active_detect is
generic (
	BEG_OFF : integer;
	END_OFF : integer;
	LENGTH  : integer
);
port (
	CLK     : in  std_logic;
	SYNC_N  : in  std_logic;
	ACTIVE  : out std_logic;
	FIRST   : out std_logic;
	LAST    : out std_logic
);
end entity;

architecture full of active_detect is

	constant END_OFF_AT : integer := LENGTH - END_OFF - 1;

	---
	-- Current position inside the SYNC_N phase.
	-- Not all bits of the counter are used.
	-- Probably it can be replaced by log2(LENGTH - END_OFF + 1).
	---
	signal cnt_pos     : std_logic_vector(log2(LENGTH - 1) downto 0);
	signal cnt_pos_ce  : std_logic;
	signal cnt_pos_clr : std_logic;

begin

	assert BEG_OFF < END_OFF_AT
		report "BEG_OFF "
			& "(" & integer'image(BEG_OFF) & ")"
			& " must be less then END_OFF "
			& "(" & integer'image(END_OFF) & ")"
		severity error;

	assert BEG_OFF + END_OFF < LENGTH
		report "BEG_OFF "
			& "(" & integer'image(BEG_OFF) & ")"
			& " + END_OFF "
			& "(" & integer'image(END_OFF) & ")"
			& "must be less then LENGTH"
			& "(" & integer'image(LENGTH) & ")"
		severity error;

	----------------------------------

	cnt_posp : process(CLK, cnt_pos_ce, cnt_pos_clr)
	begin
		if rising_edge(CLK) then
			if cnt_pos_clr = '1' then
				cnt_pos <= (others => '0');
			elsif cnt_pos_ce = '1' then
				cnt_pos <= cnt_pos + 1;
			end if;
		end if;
	end process;

	cnt_pos_ce  <= SYNC_N;
	cnt_pos_clr <= not SYNC_N;

	----------------------------------

	ACTIVE <= SYNC_N when cnt_pos >= BEG_OFF
	                  and cnt_pos <= END_OFF_AT else '0';

	FIRST  <= SYNC_N when cnt_pos  = BEG_OFF    else '0';
	LAST   <= SYNC_N when cnt_pos  = END_OFF_AT else '0';

end architecture;

