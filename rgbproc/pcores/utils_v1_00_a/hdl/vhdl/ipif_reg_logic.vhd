-- ipif_reg_logic.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

use work.utils_pkg.all;

entity ipif_reg_logic is
generic (
	REG_DWIDTH  : integer := 32;
	IPIF_DWIDTH : integer := 32;
	IPIF_MODE   : integer := IPIF_RO
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
	REG_DO       : in  std_logic_vector(REG_DWIDTH - 1 downto 0);
	REG_BE       : out std_logic_vector(width_of_be(REG_DWIDTH) - 1 downto 0);
	REG_WE       : out std_logic;
	REG_DI       : out std_logic_vector(REG_DWIDTH - 1 downto 0)
);
end entity;

architecture full of ipif_reg_logic is

	constant IPIF_WRITABLE : boolean := IPIF_MODE = IPIF_WO or IPIF_MODE = IPIF_RW;
	constant IPIF_READABLE : boolean := IPIF_MODE = IPIF_RO or IPIF_MODE = IPIF_RW;

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

gen_writable: if IPIF_WRITABLE
generate
	REG_WE <= ipif_we;
	REG_DI <= ipif_di;
	REG_BE <= Bus2IP_BE(REG_BE'range);
end generate;

gen_not_writable: if not IPIF_WRITABLE
generate
	REG_WE <= '0';
	REG_DI <= (others => 'X');
	REG_BE <= (others => 'X');
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

	IP2Bus_Data  <= REG_DO when IPIF_READABLE else (others => '1');

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

end architecture;
