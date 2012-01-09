-- ipif_monitor.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity ipif_monitor is
generic (
	DWIDTH : integer := 32
);
port (
	CLK          : in  std_logic;
	RST          : in  std_logic;
	IP2Bus_Data  : in  std_logic_vector(DWIDTH - 1 downto 0);
	IP2Bus_WrAck : in  std_logic;
	IP2Bus_RdAck : in  std_logic;
	IP2Bus_Error : in  std_logic;

	IPIF_BUSY    : in  std_logic;
	IPIF_DONE    : out std_logic
);
end entity;

architecture full of ipif_monitor is

	signal ack_active : std_logic;

begin

	ack_active <= IP2Bus_WrAck or IP2Bus_RdAck;
	IPIF_DONE  <= ack_active;

	assert (ack_active = '1' and IP2Bus_Error = '0') or ack_active = '0'
		report "Error is asserted durning Ack"
		severity warning;

	checkp : process(CLK, RST)
	begin
		if rising_edge(CLK) then
			if RST = '0' then
				if IP2Bus_WrAck = '1' then
					assert IPIF_BUSY = '1'
						report "WrAck asserted when no transaction is active"
						severity failure;
				end if;

				if IP2Bus_RdAck = '1' then
					assert IPIF_BUSY = '1'
						report "RdAck asserted when no transaction is active"
						severity failure;
				end if;

				if IP2Bus_WrAck = IP2Bus_RdAck and ack_active = '1' then
					assert false
						report "WrAck and RdAck are asserted at once"
						severity failure;
				end if;
			end if;
		end if;
	end process;

	writep : process(CLK, RST, IP2Bus_RdAck, IP2Bus_Error, IP2Bus_Data)
		variable i : integer := 0;
	begin
		if rising_edge(CLK) then
			if RST = '0' then
				if IP2Bus_RdAck = '1' and IP2Bus_Error = '0' then
					report "Data (OK): "
						& integer'image(conv_integer(IP2Bus_Data(31 downto 16))) & " "
						& integer'image(conv_integer(IP2Bus_Data(15 downto 0)));
				elsif IP2Bus_RdAck = '1' and IP2Bus_Error = '1' then
					report "Data (ER): "
						& integer'image(conv_integer(IP2Bus_Data(31 downto 16))) & " "
						& integer'image(conv_integer(IP2Bus_Data(15 downto  0)));
				end if;
			end if;
		end if;
	end process;

end architecture;
