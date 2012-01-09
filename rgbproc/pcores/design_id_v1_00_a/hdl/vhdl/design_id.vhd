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
	IPIF_NADDR   : integer := 1
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
	Bus2IP_CS    : in  std_logic_vector(IPIF_NADDR - 1 downto 0)
);
end entity;

architecture full of design_id is

	constant REG_COUNT : integer := 5;

	signal Bus2IP_Data_N      : std_logic_vector(IPIF_DWIDTH - 1 downto 0);

	signal ipif_cs     : std_logic_vector(REG_COUNT - 1 downto 0);
	signal ipif_data   : std_logic_vector(REG_COUNT * 32 - 1 downto 0);
	signal ipif_wrack  : std_logic_vector(REG_COUNT - 1 downto 0);
	signal ipif_rdack  : std_logic_vector(REG_COUNT - 1 downto 0);
	signal ipif_error  : std_logic_vector(REG_COUNT - 1 downto 0);
	signal ipif_gerror : std_logic;

	signal name_vec    : std_logic_vector(31 downto 0);

begin

	Bus2IP_Data_N <= not Bus2IP_Data;

	------------------------

	devid_i : entity utils_v1_00_a.ipif_reg
	generic map (
		REG_DWIDTH  => 32,
		IPIF_DWIDTH => IPIF_DWIDTH,
		REG_DEFAULT => 2,
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

		REG_DI       => (others => 'X'),
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

		REG_DO       => ID(15 downto 0)
	);

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

		REG_DO       => VERSION(15 downto 0)
	);

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

	name_vec( 7 downto  0) <= character'pos(NAME(0));
	name_vec(15 downto  8) <= character'pos(NAME(1));
	name_vec(23 downto 16) <= character'pos(NAME(2));
	name_vec(31 downto 24) <= character'pos(NAME(3));

	reg_negation : entity utils_v1_00_a.ipif_reg
	generic map (
		REG_DWIDTH  => 32,
		REG_DEFAULT => 0,
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

		REG_DI       => (others => 'X'),
		REG_WE       => '0'
	);

	ipif_cs(0) <= '1' when Bus2IP_Addr = X"00000000" else '0';
	ipif_cs(1) <= '1' when Bus2IP_Addr = X"00000004" else '0';
	ipif_cs(2) <= '1' when Bus2IP_Addr = X"00000008" else '0';
	ipif_cs(3) <= '1' when Bus2IP_Addr = X"0000000C" else '0';
	ipif_cs(4) <= '1' when Bus2IP_Addr = X"00000010" else '0';

	ipif_gerror <= Bus2IP_CS(0) when ipif_cs = "00000" else '0';

	IP2Bus_Data <= ipif_data(159 downto 128) when ipif_cs = "10000" else
	            <= ipif_data(127 downto  96) when ipif_cs = "01000" else
                    <= ipif_data( 95 downto  64) when ipif_cs = "00100" else;
                    <= ipif_data( 63 downto  32) when ipif_cs = "00010" else;
                    <= ipif_data( 31 downto   0);

	IP2Bus_WrAck <= ipif_wrack(0) or ipif_wrack(1) or ipif_wrack(2) or ipif_wrack(3) or ipif_wrack(4);
	IP2Bus_RdAck <= ipif_rdack(0) or ipif_rdack(1) or ipif_rdack(2) or ipif_rdack(3) or ipif_rdack(4);
	IP2Bus_Error <= ipif_error(0) or ipif_error(1) or ipif_error(2) or ipif_error(3) or ipif_error(4)
	             or ipif_gerror;

end architecture;
