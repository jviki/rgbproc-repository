-- rgb_filter.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

use work.rgb_filter_pkg.all;

library utils_v1_00_a;
use utils_v1_00_a.ipif_reg;
use utils_v1_00_a.utils_pkg.all;

entity rgb_filter is
generic (
	IPIF_AWIDTH : integer := 32;
	IPIF_DWIDTH : integer := 32;
	IPIF_NADDR  : integer := 1;
	OPERATION   : integer := OP_AND;
	DEFAULT_R   : std_logic_vector := X"00";
	DEFAULT_G   : std_logic_vector := X"00";
	DEFAULT_B   : std_logic_vector := X"00"
);
port (
	CLK    : in  std_logic;
	RST    : in  std_logic;
	CE     : in  std_logic;

	IN_R   : in  std_logic_vector(7 downto 0);
	IN_G   : in  std_logic_vector(7 downto 0);
	IN_B   : in  std_logic_vector(7 downto 0);
	IN_DE  : in  std_logic;
	IN_HS  : in  std_logic;
	IN_VS  : in  std_logic;

	OUT_R  : out std_logic_vector(7 downto 0);
	OUT_G  : out std_logic_vector(7 downto 0);
	OUT_B  : out std_logic_vector(7 downto 0);
	OUT_DE : out std_logic;
	OUT_HS : out std_logic;
	OUT_VS : out std_logic;

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

architecture full of rgb_filter is

	signal filtered_r : std_logic_vector(7 downto 0);
	signal filtered_g : std_logic_vector(7 downto 0);
	signal filtered_b : std_logic_vector(7 downto 0);

	signal reg_red    : std_logic_vector(7 downto 0);
	signal reg_green  : std_logic_vector(7 downto 0);
	signal reg_blue   : std_logic_vector(7 downto 0);

	signal ipif_cs     : std_logic_vector(3 downto 0);
	signal ipif_data   : std_logic_vector(127 downto 0);
	signal ipif_wrack  : std_logic_vector(3 downto 0);
	signal ipif_rdack  : std_logic_vector(3 downto 0);
	signal ipif_error  : std_logic_vector(3 downto 0);
	signal ipif_gerror : std_logic;
	signal ipif_werror : std_logic;
	signal ipif_rerror : std_logic;

begin

	output_regp : process(CLK, CE, filtered_r, filtered_g, filtered_b)
	begin
		if rising_edge(CLK) then
			if CE = '1' then
				OUT_R  <= filtered_r;
				OUT_G  <= filtered_g;
				OUT_B  <= filtered_b;
				OUT_DE <= IN_DE;
				OUT_HS <= IN_HS;
				OUT_VS <= IN_VS;
			end if;
		end if;
	end process;

gen_and: if OPERATION = OP_AND
generate
	filtered_r <= IN_R and reg_red;
	filtered_g <= IN_G and reg_green;
	filtered_b <= IN_B and reg_blue;
end generate;

gen_or: if OPERATION = OP_OR
generate
	filtered_r <= IN_R or reg_red;
	filtered_g <= IN_G or reg_green;
	filtered_b <= IN_B or reg_blue;
end generate;

gen_xor: if OPERATION = OP_XOR
generate
	filtered_r <= IN_R xor reg_red;
	filtered_g <= IN_G xor reg_green;
	filtered_b <= IN_B xor reg_blue;
end generate;

	---
	-- Device ID register
	---
	reg_id : entity utils_v1_00_a.ipif_reg
	generic map (
		REG_DWIDTH  => 16,
		REG_DEFAULT => X"0003",
		IPIF_DWIDTH => IPIF_DWIDTH,
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

	reg_red_i : entity utils_v1_00_a.ipif_reg
	generic map (
		REG_DWIDTH  => 8,
		REG_DEFAULT => DEFAULT_R,
		IPIF_DWIDTH => IPIF_DWIDTH,
		IPIF_MODE   => IPIF_RW
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

		REG_DI       => (7 downto 0 => 'X'),
		REG_WE       => '0',
		REG_DO       => reg_red
	);

	reg_green_i : entity utils_v1_00_a.ipif_reg
	generic map (
		REG_DWIDTH  => 8,
		REG_DEFAULT => DEFAULT_G,
		IPIF_DWIDTH => IPIF_DWIDTH,
		IPIF_MODE   => IPIF_RW
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

		REG_DI       => (7 downto 0 => 'X'),
		REG_WE       => '0',
		REG_DO       => reg_green
	);

	reg_blue_i : entity utils_v1_00_a.ipif_reg
	generic map (
		REG_DWIDTH  => 8,
		REG_DEFAULT => DEFAULT_B,
		IPIF_DWIDTH => IPIF_DWIDTH,
		IPIF_MODE   => IPIF_RW
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

		REG_DI       => (7 downto 0 => 'X'),
		REG_WE       => '0',
		REG_DO       => reg_blue
	);

	ipif_cs(0) <= Bus2IP_CS(0) when Bus2IP_Addr = X"00000000" else '0';
	ipif_cs(1) <= Bus2IP_CS(0) when Bus2IP_Addr = X"00000004" else '0';
	ipif_cs(2) <= Bus2IP_CS(0) when Bus2IP_Addr = X"00000008" else '0';
	ipif_cs(3) <= Bus2IP_CS(0) when Bus2IP_Addr = X"0000000C" else '0';

	ipif_gerror <= Bus2IP_CS(0) when ipif_cs = "0000" else '0';

	ipif_rerror <= ipif_gerror when Bus2IP_CS(0) = '1' and Bus2IP_RNW = '1' else '0';
	ipif_werror <= ipif_gerror when Bus2IP_CS(0) = '1' and Bus2IP_RNW = '0' else '0';

	IP2Bus_Data <= ipif_data(127 downto 96) when ipif_cs = "1000" else
	               ipif_data( 95 downto 64) when ipif_cs = "0100" else
	               ipif_data( 63 downto 32) when ipif_cs = "0010" else
	               ipif_data( 31 downto  0);

	IP2Bus_WrAck <= ipif_wrack(0) or ipif_wrack(1) or ipif_wrack(2) or ipif_wrack(3) or ipif_werror;
	IP2Bus_RdAck <= ipif_rdack(0) or ipif_rdack(1) or ipif_rdack(2) or ipif_rdack(3) or ipif_rerror;
	IP2Bus_Error <= ipif_error(0) or ipif_error(1) or ipif_error(2) or ipif_error(3) or ipif_gerror;

end architecture;

