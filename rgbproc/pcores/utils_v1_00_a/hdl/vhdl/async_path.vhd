-- async_path.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity async_path is
generic (
	DWIDTH : integer := 8		
);
port (
	CLKA   : in  std_logic;
	RSTA   : in  std_logic;
	CLKB   : in  std_logic;
	RSTB   : in  std_logic;
	
	WEA    : in  std_logic;
	BUSYA  : out std_logic;
	DA     : in  std_logic_vector(DWIDTH - 1 downto 0);

	DRDYB  : out std_logic;
	REB    : in  std_logic;
	DB     : out std_logic_vector(DWIDTH - 1 downto 0)
);
end entity;

architecture full of async_path is
begin

	req_i : entity work.async_req
	port map (
		CLK  => CLKA,
		RST  => RSTA,
		DRDY =>	WEA,
		BUSY => BUSYA,
		REQ  => async_reqa,
		ACK  => async_acka
	);

	ack_i : entity work.async_ack
	port map (
		CLK  =>	CLKB,
		RST  => RSTB,
		REQ  => async_reqb,
		ACK  => async_ackb,
		DRDY => DRDYB,
		RE   => REB
	);

	sync_req_i : entity work.synchronizer
	port map (
		CLKA => CLKA,
		CLKB => CLKB,
		DA   => async_reqa,
		DB   => async_reqb	
	);

	sync_ack_i : entity work.synchronizer
	port map (
		CLKA => CLKB,
		CLKB => CLKA,
		DA   => async_ackb,
		DB   => async_acka
	);

end architecture;
