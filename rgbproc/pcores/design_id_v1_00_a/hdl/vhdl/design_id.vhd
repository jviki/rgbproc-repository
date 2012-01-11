-- design_id.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library utils_v1_00_a;
use utils_v1_00_a.ipif_reg_logic;
use utils_v1_00_a.ipif_reg;
use utils_v1_00_a.utils_pkg.all;

entity design_id is
generic (
	VERSION : std_logic_vector;
	ID      : std_logic_vector;
	NAME    : string;
	IPIF_AWIDTH  : integer := 32;
	IPIF_DWIDTH  : integer := 32;
	IPIF_NADDR   : integer := 1;
	CS_ENABLE    : integer := 0
);
port (
	CLK          : in  std_logic;
	RST          : in  std_logic;
	IP2Bus_Data  : out std_logic_vector(IPIF_DWIDTH - 1 downto 0);
	IP2Bus_WrAck : out std_logic;
	IP2Bus_RdAck : out std_logic;
	IP2Bus_Error : out std_logic;
	Bus2IP_Addr  : in  std_logic_vector(IPIF_AWIDTH - 1 downto 0);
	Bus2IP_Data  : in  std_logic_vector(IPIF_DWIDTH - 1 downto 0);
	Bus2IP_RNW   : in  std_logic;
	Bus2IP_BE    : in  std_logic_vector(IPIF_DWIDTH / 8 - 1 downto 0);
	Bus2IP_CS    : in  std_logic_vector(IPIF_NADDR - 1 downto 0);

	CS_CLK       : out std_logic;
	CS_VEC       : out std_logic_vector(20 downto 0)
);
end entity;

---
-- Provides basic metadata about a design or module.
-- Address space:
--  <address>   <access> <description>   <width> <default>
--  0x00000000  RO       device type id  16b     2
--  0x00000004  RO       device id       16b     generic ID
--  0x00000008  RO       device version  16b     generic VERSION
--  0x0000000C  RO       device name     32b     generic NAME
--  0x00000010  RW       negation        32b     0xDEADBEEF
---
architecture full of design_id is

	constant REG_COUNT : integer := 5;

	signal Bus2IP_Data_N      : std_logic_vector(IPIF_DWIDTH - 1 downto 0);

	signal ipif_cs     : std_logic_vector(REG_COUNT - 1 downto 0);
	signal ipif_data   : std_logic_vector(REG_COUNT * 32 - 1 downto 0);
	signal ipif_wrack  : std_logic_vector(REG_COUNT - 1 downto 0);
	signal ipif_rdack  : std_logic_vector(REG_COUNT - 1 downto 0);
	signal ipif_error  : std_logic_vector(REG_COUNT - 1 downto 0);
	signal ipif_gerror : std_logic;

	signal error_wrack : std_logic;
	signal error_rdack : std_logic;

	signal name_vec    : std_logic_vector(31 downto 0);
	signal id_vec      : std_logic_vector(15 downto 0);
	signal version_vec : std_logic_vector(15 downto 0);

begin

	Bus2IP_Data_N <= not Bus2IP_Data;

	------------------------

	devid_i : entity utils_v1_00_a.ipif_reg
	generic map (
		REG_DWIDTH  => 16,
		IPIF_DWIDTH => IPIF_DWIDTH,
		REG_DEFAULT => X"0002",
		IPIF_MODE   => IPIF_RO
	)
	port map (
		CLK          => CLK,
		RST          => RST,

		IP2Bus_Data  => ipif_data(31 downto 0),
		IP2Bus_WrAck => ipif_wrack(0),
		IP2Bus_RdAck => ipif_rdack(0),
		IP2Bus_Error => ipif_error(0),		
		Bus2IP_Data  => Bus2IP_Data,
		Bus2IP_BE    => Bus2IP_BE,
		Bus2IP_RNW   => Bus2IP_RNW,
		Bus2IP_CS    => ipif_cs(0),

		REG_DI       => (15 downto 0 => 'X'),
		REG_WE       => '0'
	);


	id_i : entity utils_v1_00_a.ipif_reg_logic
	generic map (
		REG_DWIDTH  => 16,
		IPIF_DWIDTH => IPIF_DWIDTH,
		IPIF_MODE   => IPIF_RO
	)
	port map (
		CLK          => CLK,
		RST          => RST,

		IP2Bus_Data  => ipif_data(63 downto 32),
		IP2Bus_WrAck => ipif_wrack(1),
		IP2Bus_RdAck => ipif_rdack(1),
		IP2Bus_Error => ipif_error(1),		
		Bus2IP_Data  => Bus2IP_Data,
		Bus2IP_BE    => Bus2IP_BE,
		Bus2IP_RNW   => Bus2IP_RNW,
		Bus2IP_CS    => ipif_cs(1),

		REG_DO       => id_vec
	);

	id_vec <= ID;

	version_i : entity utils_v1_00_a.ipif_reg_logic
	generic map (
		REG_DWIDTH  => 16,
		IPIF_DWIDTH => IPIF_DWIDTH,
		IPIF_MODE   => IPIF_RO
	)
	port map (
		CLK          => CLK,
		RST          => RST,

		IP2Bus_Data  => ipif_data(95 downto 64),
		IP2Bus_WrAck => ipif_wrack(2),
		IP2Bus_RdAck => ipif_rdack(2),
		IP2Bus_Error => ipif_error(2),		
		Bus2IP_Data  => Bus2IP_Data,
		Bus2IP_BE    => Bus2IP_BE,
		Bus2IP_RNW   => Bus2IP_RNW,
		Bus2IP_CS    => ipif_cs(2),

		REG_DO       => version_vec
	);

	version_vec <= VERSION;

	name_i : entity utils_v1_00_a.ipif_reg_logic
	generic map (
		REG_DWIDTH  => 32,
		IPIF_DWIDTH => IPIF_DWIDTH,
		IPIF_MODE   => IPIF_RO
	)
	port map (
		CLK          => CLK,
		RST          => RST,

		IP2Bus_Data  => ipif_data(127 downto 96),
		IP2Bus_WrAck => ipif_wrack(3),
		IP2Bus_RdAck => ipif_rdack(3),
		IP2Bus_Error => ipif_error(3),
		Bus2IP_Data  => Bus2IP_Data,
		Bus2IP_BE    => Bus2IP_BE,
		Bus2IP_RNW   => Bus2IP_RNW,
		Bus2IP_CS    => ipif_cs(3),

		REG_DO       => name_vec
	);

	name_vec( 7 downto  0) <= conv_std_logic_vector(character'pos(NAME(1)), 8);
	name_vec(15 downto  8) <= conv_std_logic_vector(character'pos(NAME(2)), 8);
	name_vec(23 downto 16) <= conv_std_logic_vector(character'pos(NAME(3)), 8);
	name_vec(31 downto 24) <= conv_std_logic_vector(character'pos(NAME(4)), 8);

	reg_negation : entity utils_v1_00_a.ipif_reg
	generic map (
		REG_DWIDTH  => 32,
		REG_DEFAULT => X"DEADBEEF",
		IPIF_DWIDTH => IPIF_DWIDTH,
		IPIF_MODE   => IPIF_RW
	)
	port map (
		CLK          => CLK,
		RST          => RST,

		IP2Bus_Data  => ipif_data(159 downto 128),
		IP2Bus_WrAck => ipif_wrack(4),
		IP2Bus_RdAck => ipif_rdack(4),
		IP2Bus_Error => ipif_error(4),
		Bus2IP_Data  => Bus2IP_Data_N,
		Bus2IP_BE    => Bus2IP_BE,
		Bus2IP_RNW   => Bus2IP_RNW,
		Bus2IP_CS    => ipif_cs(4),

		REG_DI       => (31 downto 0 => 'X'),
		REG_WE       => '0'
	);

	ipif_cs(0) <= Bus2IP_CS(0) when Bus2IP_Addr = X"00000000" else '0';
	ipif_cs(1) <= Bus2IP_CS(0) when Bus2IP_Addr = X"00000004" else '0';
	ipif_cs(2) <= Bus2IP_CS(0) when Bus2IP_Addr = X"00000008" else '0';
	ipif_cs(3) <= Bus2IP_CS(0) when Bus2IP_Addr = X"0000000C" else '0';
	ipif_cs(4) <= Bus2IP_CS(0) when Bus2IP_Addr = X"00000010" else '0';

	ipif_gerror <= Bus2IP_CS(0) when ipif_cs = "00000" else '0';

	error_rdack <= ipif_gerror when Bus2IP_CS(0) = '1' and Bus2IP_RNW = '1' else '0';
	error_wrack <= ipif_gerror when Bus2IP_CS(0) = '1' and Bus2IP_RNW = '0' else '0';

	IP2Bus_Data <= ipif_data(159 downto 128) when ipif_cs = "10000" else
	               ipif_data(127 downto  96) when ipif_cs = "01000" else
                       ipif_data( 95 downto  64) when ipif_cs = "00100" else
                       ipif_data( 63 downto  32) when ipif_cs = "00010" else
                       ipif_data( 31 downto   0);

	IP2Bus_WrAck <= ipif_wrack(0) or ipif_wrack(1) or ipif_wrack(2) or ipif_wrack(3) or ipif_wrack(4)
	             or error_wrack;
	IP2Bus_RdAck <= ipif_rdack(0) or ipif_rdack(1) or ipif_rdack(2) or ipif_rdack(3) or ipif_rdack(4)
	             or error_rdack;
	IP2Bus_Error <= ipif_error(0) or ipif_error(1) or ipif_error(2) or ipif_error(3) or ipif_error(4)
	             or ipif_gerror;

	------------------------

	CS_CLK <= CLK;
	CS_VEC( 4 downto  0) <= ipif_cs;
	CS_VEC( 9 downto  5) <= ipif_wrack;
	CS_VEC(14 downto 10) <= ipif_rdack;
	CS_VEC(19 downto 15) <= ipif_error;
	CS_VEC(20) <= ipif_gerror;

end architecture;
