-- ipif_sim.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity ipif_sim is
generic (
	DWIDTH : integer := 32;
	AWIDTH : integer := 32;
	ADDR_MIN : integer := 0;
	ADDR_MAX : integer := 128
);
port (
	CLK          : in  std_logic;
	RST          : in  std_logic;

	Bus2IP_Addr  : out std_logic_vector(AWIDTH - 1 downto 0);
	Bus2IP_Data  : out std_logic_vector(DWIDTH - 1 downto 0);
	Bus2IP_RNW   : out std_logic;
	Bus2IP_BE    : out std_logic_vector(DWIDTH / 8 - 1 downto 0);
	Bus2IP_CS    : out std_logic;

	IP2Bus_Data  : in  std_logic_vector(DWIDTH - 1 downto 0);
	IP2Bus_WrAck : in  std_logic;
	IP2Bus_RdAck : in  std_logic;
	IP2Bus_Error : in  std_logic
);
end entity;

architecture wrapper of ipif_sim is

	signal ipif_busy    : std_logic;
	signal ipif_done    : std_logic;
	signal ipif_read    : std_logic;

begin

	gen_i : entity work.ipif_generator
	generic map (
		DWIDTH => DWIDTH,
		AWIDTH => AWIDTH,
		ADDR_MIN => ADDR_MIN,
		ADDR_MAX => ADDR_MAX
	)
	port map (
		CLK    => CLK,
		RST    => RST,

		Bus2IP_Addr => Bus2IP_Addr,
		Bus2IP_Data => Bus2IP_Data,
		Bus2IP_RNW  => Bus2IP_RNW,
		Bus2IP_BE   => Bus2IP_BE,
		Bus2IP_CS   => Bus2IP_CS,

		IPIF_BUSY   => ipif_busy,
		IPIF_READ   => ipif_read,
		IPIF_DONE   => ipif_done
	);

	mon_i : entity work.ipif_monitor
	generic map (
		DWIDTH => DWIDTH
	)
	port map (
		CLK          => CLK,
		RST          => RST,

		IP2Bus_Data  => IP2Bus_Data,
		IP2Bus_WrAck => IP2Bus_WrAck,
		IP2Bus_RdAck => IP2Bus_RdAck,
		IP2Bus_Error => IP2Bus_Error,

		IPIF_BUSY    => ipif_busy,
		IPIF_READ    => ipif_read,
		IPIF_DONE    => ipif_done
	);

end architecture;
