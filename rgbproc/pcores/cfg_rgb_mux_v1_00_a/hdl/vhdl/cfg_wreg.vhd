-- cfg_wreg.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity cfg_wreg is
generic (
	DWIDTH  : integer := 32;
	INITIAL : std_logic_vector(31 downto 0) := X"00000000"
);
port (
	PLB_CLK : in  std_logic;
	PLB_RST : in  std_logic;
	CFG_CLK : in  std_logic;
	CFG_RST : in  std_logic;

	PLB_DI   : out std_logic_vector(31 downto 0);
	PLB_DO   : out std_logic_vector(31 downto 0);
	PLB_WE   : in  std_logic;
	PLB_RE   : in  std_logic;
	PLB_BE   : in  std_logic_vector(3 downto 0);
	PLB_RACK : out std_logic;
	PLB_WACK : out std_logic;

	CFG_DO   : out std_logic_vector(DWIDTH - 1 downto 0)
);
end entity;

architecture full of cfg_wreg is

	signal reg_data    : std_logic_vector(DWIDTH - 1 downto 0);
	signal reg_data_we : std_logic;

begin

	CFG_DO <= reg_data;

	--------------------------

	reg_datap : process(CFG_CLK, CFG_RST, reg_data_we, reg_data_in)
	begin
		if rising_edge(CFG_CLK) then
			if CFG_RST = '1' then
				reg_data <= INITIAL(reg_data'range);
			elsif reg_data_we = '1' then
				reg_data <= reg_data_in;
			end if;
		end if;
	end process;

	write_path_i : entity work.async_path
	generic map (
		DWIDTH => DWIDTH + 4
	)
	port map (
		CLKA   => PLB_CLK,
		RSTA   => PLB_RST,
		CLKB   => CFG_CLK,
		RSTB   => CFG_RST,

		WEA    => PLB_WE,
		BUSYA  => plb_we_busy,
		DA(DWIDTH - 1 downto 0)      => PLB_DO(reg_data'range),
		DA(DWIDTH + 3 downto DWIDTH) => PLB_BE,

		DRDYB  => cfg_we_drdy,
		REB    => cfg_we_ack,
		DB(DWIDTH - 1 downto 0)      => reg_data_in,
		DB(DWIDTH + 3 downto DWIDTH) => reg_data_be
	);

	--------------------------

	read_datap : process(PLB_CLK, reg_data, PLB_RE)
	begin
		if rising_edge(PLB_CLK) then
			if PLB_RE = '1' then
				PLB_DO(reg_data'range) <= reg_data
				PLB_RACK <= '1';
			end if;
		end if;
	end process;

gen_rest_plb_do: if reg_data'length < 32
generate
	PLB_DO(31 downto reg_data'length) <= (others => '0');
end generate;

end architecture;
