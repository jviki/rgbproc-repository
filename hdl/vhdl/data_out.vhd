-- data_out.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library unisim;
use unisim.vcomponents.all;

entity data_out is
port (
	CLK     : in  std_logic;
	RST     : in  std_logic;

	D0          : in  std_logic_vector(11 downto 0);
	D1          : in  std_logic_vector(11 downto 0);
	HS          : in  std_logic;
	VS          : in  std_logic;
	DE          : in  std_logic;

	OUT_XCLK_P  : out std_logic;
	OUT_XCLK_N  : out std_logic;
	OUT_RESET_N : out std_logic;
	OUT_D       : in  std_logic_vector(11 downto 0);
	OUT_DE      : out std_logic;
	OUT_HS      : out std_logic;
	OUT_VS      : out std_logic
);
end entity;

architecture ddr of data_out is

begin

	xclk_p_oddr_i : ODDR
	port map (
		Q  => OUT_XCLK_P,
		C  => CLK,
		CE => '1',
		R  => RST,
		D1 => '1',
		D2 => '0',
		S  => '0'
	);

	xclk_n_oddr_i : ODDR
	port map (
		Q  => OUT_XCLK_N,
		C  => CLK,
		CE => '1',
		R  => RST,
		D1 => '0',
		D2 => '1',
		S  => '0'
	);

	gen_oddr_data: for i in 0 to 11
	generate
		data_oddr_i : ODDR
		port map (
			Q  => OUT_D(i),
			C  => CLK,
			CE => '1',
			R  => RST,
			D1 => D0(i),
			D2 => D1(i),
			S  => '0'
		);
	end generate;

	out_regp : process(CLK)
	begin
		if rising_edge(CLK) then
			OUT_DE      <= DE;
			OUT_RESET_N <= not RST;
			OUT_HS      <= HS;
			OUT_VS      <= VS;
		end if;
	end process;

end architecture;


