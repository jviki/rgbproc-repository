-- rgb_async.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library utils_v1_00_a;
use utils_v1_00_a.afifo;

---
-- Every IN_CLK data are written unless
-- the FULL flag is asserted.
-- Every OUT_CLK data are read unless
-- the EMPTY flag is asserted.
---
entity rgb_async is
port (
	IN_CLK  : in  std_logic;
	IN_RST  : in  std_logic;

	FULL    : out std_logic;
	IN_R    : in  std_logic_vector(7 downto 0);
	IN_B    : in  std_logic_vector(7 downto 0);
	IN_G    : in  std_logic_vector(7 downto 0);
	IN_DE   : in  std_logic;
	IN_HS   : in  std_logic;
	IN_VS   : in  std_logic;

	OUT_CLK : in  std_logic;
	OUT_RST : in  std_logic;

	EMPTY   : out std_logic;
	OUT_R   : out std_logic_vector(7 downto 0);
	OUT_G   : out std_logic_vector(7 downto 0);
	OUT_B   : out std_logic_vector(7 downto 0);
	OUT_DE  : out std_logic;
	OUT_HS  : out std_logic;
	OUT_VS  : out std_logic
);
end entity;

architecture afifo of rgb_async is

	signal rgb_in    : std_logic_vector(26 downto 0);
	signal rgb_we    : std_logic;
	signal rgb_out   : std_logic_vector(26 downto 0);
	signal rgb_re    : std_logic;
	signal rgb_full  : std_logic;
	signal rgb_empty : std_logic;

	signal or_reset  : std_logic;

begin

	or_reset <= IN_RST or OUT_RST;

	---------------------

	rgb_in( 7 downto  0) <= IN_R;
	rgb_in(15 downto  8) <= IN_G;
	rgb_in(23 downto 16) <= IN_B;
	rgb_in(24) <= IN_DE;
	rgb_in(25) <= IN_HS;
	rgb_in(26) <= IN_VS;

	OUT_R  <= rgb_out( 7 downto  0);
	OUT_G  <= rgb_out(15 downto  8);
	OUT_B  <= rgb_out(23 downto 16);
	OUT_DE <= rgb_out(24);
	OUT_HS <= rgb_out(25);
	OUT_VS <= rgb_out(26);

	rgb_we <= not rgb_full;
	rgb_re <= not rgb_empty;

	FULL   <= rgb_full;
	EMPTY  <= rgb_empty;

	---------------------

	afifo_i : entity utils_v1_00_a.afifo
	generic map (
		DWIDTH => 27,
		DEPTH  => 16		
	)
	port map (
		WCLK   => IN_CLK,
		RCLK   => OUT_CLK,
		RESET  => or_reset,

		WE     => rgb_we,
		FULL   => rgb_full,
		DI     => rgb_in,

		RE     => rgb_re,
		EMPTY  => rgb_empty.
		DO     => rgb_out
	);

end architecture;
