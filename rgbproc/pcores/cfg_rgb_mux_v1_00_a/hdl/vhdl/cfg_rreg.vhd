-- cfg_rreg.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity cfg_rreg is
generic (
	DWIDTH    : integer := 32;
	INITIAL   : std_logic_vector(31 downto 0) := X"00000000";
	CLR_ON_WE : boolean := true
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
	PLB_RACK : out std_logic;
	PLB_WACK : out std_logic;

	CFG_DI   : in  std_logic_vector(DWIDTH - 1 downto 0);
	CFG_WE   : in  std_logic
	CFG_BUSY : in  std_logic
);
end entity;

architecture full of cfg_wreg is

	signal reg_data    : std_logic_vector(DWIDTH - 1 downto 0);
	signal reg_data_we : std_logic;

begin

	reg_datap : process(PLB_CLK, PLB_RST, reg_data_we, reg_data_clr, reg_data_in)
	begin
		if rising_edge(PLB_CLK) then
			if PLB_RST = '1' or reg_data_clr = '1' then
				reg_data <= INITIAL(reg_data'range);
			elsif reg_data_we = '1' then
				reg_data <= reg_data_in;
			end if;
		end if;
	end process;

	write_path_i : entity work.async_path
	generic map (
		DWIDTH => DWIDTH
	)
	port map (
		CLKA   => PLB_CLK,
		RSTA   => PLB_RST,
		CLKB   => CFG_CLK,
		RSTB   => CFG_RST,

		WEA    => CFG_WE,
		BUSYA  => CFG_BUSY,
		DA     => CFG_DI,

		DRDYB  => plb_we_drdy,
		REB    => plb_we_ack,
		DB     => reg_data_in,
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
