-- end_check.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity end_check is
generic (
	WIDTH  : integer := 640;
	HEIGHT : integer := 480
);
port (
	CLK     : in  std_logic;
	RST     : in  std_logic;

	PX_VLD  : in  std_logic;
	IN_EOL  : in  std_logic;
	IN_EOF  : in  std_logic;

	CLEAR   : in  std_logic;
	INVALID : out std_logic
);
end entity;

architecture full of end_check is

	signal expect_eol      : std_logic;
	signal expect_eof      : std_logic;

	signal reg_invalid     : std_logic;
	signal reg_invalid_ce  : std_logic;
	signal reg_invalid_clr : std_logic;

begin

	reg_expectp : process(CLK, RST, reg_invalid_ce, reg_invalid_clr)
	begin
		if rising_edge(CLK) then
			if RST = '1' or reg_invalid_clr = '1' then
				reg_invalid <= '0';
			elsif reg_invalid_ce = '1' then
				reg_invalid <= '1';
			end if;
		end if;
	end process;

	reg_invalid_ce  <= (expect_eof xor IN_EOF) or (expect_eol xor IN_EOL);
	reg_invalid_clr <= CLEAR;

	---------------------------------

	end_check_i : entity work.end_gen
	generic map (
		WIDTH  => WIDTH,
		HEIGHT => HEIGHT
	)
	port map (
		CLK     => CLK,
		RST     => RST,
		PX_VLD  => PX_VLD,
		OUT_EOL => expect_eol,
		OUT_EOF => expect_eof
	);

	---------------------------------

	INVALID <= reg_invalid;

end architecture;

