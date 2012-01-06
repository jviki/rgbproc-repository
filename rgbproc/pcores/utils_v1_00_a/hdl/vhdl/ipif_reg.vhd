-- ipif_reg.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

use work.utils_pkg.all;

entity ipif_reg is
generic (
	REG_DWIDTH  : integer := 32;
	REG_DEFAULT : integer := 0;
	IPIF_DWIDTH : integer := 32;
	IPIF_MODE   : integer := IPIF_RW
);
port (
	CLK          : in  std_logic;
	RST          : in  std_logic;

	---
	-- IPIF access to the register
	---
	IP2Bus_Data  : out std_logic_vector(IPIF_DWIDTH - 1 downto 0);
	IP2Bus_WrAck : out std_logic;
	IP2Bus_RdAck : out std_logic;
	IP2Bus_Error : out std_logic;
	Bus2IP_Data  : in  std_logic_vector(IPIF_DWIDTH - 1 downto 0);
	Bus2IP_BE    : in  std_logic_vector(IPIF_DWIDTH / 8 - 1 downto 0);
	Bus2IP_RNW   : in  std_logic;
	Bus2IP_CS    : in  std_logic;

	---
	-- IP access to the register
	---
	REG_DO       : out std_logic_vector(REG_DWIDTH - 1 downto 0);
	REG_WE       : in  std_logic;
	REG_DI       : in  std_logic_vector(REG_DWIDTH - 1 downto 0)
);
end entity;

architecture full of ipif_reg is

	signal reg_data_we : std_logic;
	signal reg_data_in : std_logic_vector(REG_DWIDTH - 1 downto 0);
	signal reg_data    : std_logic_vector(REG_DWIDTH - 1 downto 0);
	signal reg_data_be : std_logic_vector(width_of_be(REG_DWIDTH) - 1 downto 0);

	signal ipif_we     : std_logic;
	signal ipif_di     : std_logic_vector(REG_DWIDTH - 1 downto 0);
	signal ipif_be     : std_logic_vector(width_of_be(REG_DWIDTH) - 1 downto 0);

begin

	assert REG_DWIDTH > 0 and REG_DWIDTH <= IPIF_DWIDTH
		report "Invalid register width: " & integer'image(REG_DWIDTH)
		severity failure;

	-----------------------

	reg_datap : process(CLK, RST, reg_data_we, reg_data_be, reg_data_in)
		variable DBEG : integer;
		variable DEND : integer;
	begin
		if rising_edge(CLK) then
			if RST = '1' then
				reg_data <= conv_std_logic_vector(REG_DEFAULT, reg_data'length);
			elsif reg_data_we = '1' then
				for i in 0 to reg_data_be'length - 1 loop
					DBEG := (i + 1) * 8;
					DEND := i * 8;

					-- handle the case when REG_DWIDTH is not
					-- multiple of 8, so the last range must be
					-- shorted
					if i = reg_data_be'length - 1 then
						DBEG := DBEG - (REG_DWIDTH mod 8);
					end if;

					-- apply byte-enable
					if reg_data_be(i) = '1' then
						reg_data(DBEG - 1 downto DEND) <= reg_data_in(DBEG - 1 downto DEND);
					end if;
				end loop;
			end if;
		end if;
	end process;

	-----------------------

	reg_data_we <= REG_WE or ipif_we;
	reg_data_in <= ipif_di when ipif_we = '1' else
	               REG_DI  when REG_WE  = '1';
	reg_data_be <= ipif_be when ipif_we = '1' else
	               (others => '1');

	-----------------------

	ipif_access : entity work.ipif_reg_logic
	generic map (
		REG_DWIDTH  => REG_DWIDTH,
		IPIF_DWIDTH => IPIF_DWIDTH,
		IPIF_MODE   => IPIF_MODE
	)
	port map (
		CLK => CLK,
		RST => RST,

		IP2Bus_Data  => IP2Bus_Data,
		IP2Bus_WrAck => IP2Bus_WrAck,
		IP2Bus_RdAck => IP2Bus_RdAck,
		IP2Bus_Error => IP2Bus_Error,
		Bus2IP_Data  => Bus2IP_Data,
		Bus2IP_BE    => Bus2IP_BE,
		Bus2IP_RNW   => Bus2IP_RNW,
		Bus2IP_CS    => Bus2IP_CS,

		REG_DO       => reg_data,
		REG_BE       => ipif_be,
		REG_WE       => ipif_we,
		REG_DI       => ipif_di
	);

end architecture;
