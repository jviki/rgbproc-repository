-- async_ipif.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity async_ipif is
generic (
	AWIDTH : integer := 32;
	DWIDTH : integer := 32
);
port (
	CLKA   : in  std_logic;
	WEA    : in  std_logic;
	REA    : in  std_logic;
	ADDRA  : in  std_logic_vector(AWIDTH - 1 downto 0);
	DIA    : in  std_logic_vector(DWIDTH - 1 downto 0);
	DOA    : out std_logic_vector(DWIDTH - 1 downto 0);
	ACKA   : out std_logic;

	CLKB   : in  std_logic;
	WEB    : out std_logic;
	REB    : out std_logic;
	ADDRB  : out std_logic_vector(AWIDTH - 1 downto 0);
	DIB    : out std_logic_vector(DWIDTH - 1 downto 0);
	DOB    : in  std_logic_vector(DWIDTH - 1 downto 0);
	ACKB   : in  std_logic
);
end entity;

architecture full of async_ipif is
begin

	req_fsm_i : entity work.req_fsm
	port map (
		CLK       => CLKA,
		
		WE        => WEA,
		RE        => REA,
		ACK       => ACKA,

		REQ_WE    => req_we,
		REQ_FULL  => req_full,
		RES_RE    => res_re,
		RES_EMPTY => res_empty
	);

	req_afifo_i : entity work.req_afifo
	port map (
		CLKA  => CLKA,
		CLKB  => CLKB,
		
		WE    => req_we,
		FULL  => req_full,
		DI    => req_di,

		RE    => req_re,
		EMPTY => req_empty,
		DO    => req_do
	);

	res_fsm_i : entity work.res_fsm
	port map (
		CLK       => CLKB,
		
		WE        => WEB,
		RE        => REB,
		ACK       => ACKB,
		
		REQ_RE    => req_re,
		REQ_EMPTY => req_empty,
		RES_WE    => res_we,
		RES_FULL  => res_full		
	);

	res_afifo_i : entity work.res_afifo
	port map (
		CLKA  => CLKB,
		CLKB  => CLKA,

		WE    => res_we,
		FULL  => res_full,
		DI    => res_di,

		RE    => res_re,
		EMPTY => res_empty,
		DO    => res_do		
	);

end architecture;

