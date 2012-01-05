-- ipif_reg.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity ipif_reg is
generic (
	REG_DWIDTH  : integer := 32;
	REG_DEFAULT : integer := 0;
	IPIF_DWIDTH : integer := 32;
	IPIF_MODE   : integer := 2  -- 0: read-only, 1: write-only, 2: read-write
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

	constant IPIF_WRITABLE : boolean := IPIF_MODE = 1 or IPIF_MODE = 2;
	constant IPIF_READABLE : boolean := IPIF_MODE = 0 or IPIF_MODE = 2;

	signal reg_data_we : std_logic;
	signal reg_data_in : std_logic_vector(REG_DWIDTH - 1 downto 0);
	signal reg_data    : std_logic_vector(REG_DWIDTH - 1 downto 0);
	signal reg_data_be : std_logic_vector(REG_DWIDTH / 8 - 1 downto 0);

	signal ipif_we     : std_logic;
	signal ipif_re     : std_logic;
	signal ipif_sel    : std_logic;
	signal ipif_error  : std_logic;
	signal ipif_di     : std_logic_vector(REG_DWIDTH - 1 downto 0);

begin

	assert REG_DWIDTH > 0 and REG_DWIDTH <= IPIF_DWIDTH
		report "Invalid register width: " & integer'image(REG_DWIDTH)
		severity failure;

	-----------------------

	reg_datap : process(CLK, RST, reg_data_we, reg_data_be, reg_data_in)
	begin
		if rising_edge(CLK) then
			if RST = '1' then
				reg_data <= conv_std_logic_vector(REG_DEFAULT, reg_data'length);
			elsif reg_data_we = '1' then
				for i in 0 to DWIDTH / 8 - 1 loop
					if reg_data_be(i) = '1' then
						reg_data((i + 1) * 8 downto i * 8) <= reg_data_in((i + 1) * 8 downto i * 8);
					end if;
				end loop;

				---
				-- Write the rest when register is not modulo 8
				---
				if DWIDTH mod 8 = 1 and reg_data_be(DWIDTH / 8) = '1' then
					reg_data(DWIDTH - 1 downto (DWIDTH / 8) * 8) <= reg_data_in(DWIDTH - 1 downto (DWIDTH / 8) * 8);
				end if;
			end if;
		end if;
	end process;

	-----------------------

gen_writable: if IPIF_WRITABLE
generate
	reg_data_we <= REG_WE or ipif_we;
	reg_data_in <= ipif_di when ipif_we = '1' else
	               REG_DI  when REG_WE  = '1';
	reg_data_be <= ipif_be when ipif_we = '1' else
	               (others => '1');
end generate;

gen_not_writable: if not IPIF_WRITABLE
generate
	reg_data_we <= REG_WE;
	reg_data_in <= REG_DI;
	reg_data_be <= (others => '1');
end generate;

	-----------------------
	
	ipif_selp : process(CLK, RST, Bus2IP_CS)
	begin
		if rising_edge(CLK) then
			if RST = '1' then
				ipif_sel <= '0';
			else
				ipif_sel <= Bus2IP_CS;
			end if;
		end if;
	end process;
	
	-----------------------

	ipif_we <= ipif_sel and not Bus2IP_RNW;
	ipif_re <= ipif_sel and Bus2IP_RNW;
	ipif_di <= Bus2IP_Data(REG_DWIDTH - 1 downto 0);
	
	-----------------------

	IP2Bus_Data  <= reg_data when IPIF_READABLE else (others => '1');

	ipif_error <= '1' when not IPIF_WRITABLE and ipif_we = '1' else
	              '1' when not IPIF_READABLE and ipif_re = '1' else
	              '0';

	ackp : process(CLK, ipif_we, ipif_re, ipif_error)
	begin
		if rising_edge(CLK) then
			IP2Bus_WrAck <= ipif_we;
			IP2Bus_RdAck <= ipif_re;
			IP2Bus_Error <= ipif_error;
		end if;
	end process;

	-----------------------

	REG_DO <= reg_data;

end architecture;
