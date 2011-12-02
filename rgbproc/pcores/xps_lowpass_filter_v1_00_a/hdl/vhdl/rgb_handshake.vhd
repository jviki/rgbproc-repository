-- rgb_handshake.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

---
-- The filter pipeline typically introduces a delay of several CLKs.
-- To solve the RGB handshaking there is a simple combinational logic
-- with input from shift register of valid flags (valid_vec).
--
--  IN_D   -> | data_line  | -> OUT_D
--  IN_VLD -> | valid_vec  | -> OUT_VLD
--                        |
--                     CE |
--                        |
--   IN_REQ <-- & --------+----<--- & -- neg -- OUT_VLD
--              |                   |
--             IN_VLD             OUT_REQ
--
-- (1) When data from the data_line are not valid (OLD_VLD is low)
--     the data_line pipeline accepts new data (even when they are invalid!)
--     until a valid output is available. The valid_vec stores the validity
--     information.
-- (2) If valid data are available the data_line is stopped until an OUT_REQ
--     comes.
-- (3) If OUT_REQ is asserted new data are put into the data_line from IN_*.
-- (4) IN_REQ is generated when IN_VLD is asserted and data_line is being shifted.
---
entity rgb_handshake is
generic (
	LINE_DEPTH : integer		
);
port (
	CLK     : in  std_logic
	
	IN_REQ  : out std_logic
	IN_VLD  : in  std_logic
	OUT_REQ : in  std_logic
	OUT_VLD : out std_logic

	LINE_CE : out std_logic
);
end entity;

architecture shreg_and_logic of rgb_handshake is

	signal valid_vec : std_logic_vector(LINE_DEPTH - 1 downto 0);
	signal valid_out : std_logic;

	signal ce        : std_logic;

begin

	---
	-- Shift register for validity flags.
	-- Vector valid_vec(max) represents valid
	-- flag of data coming from adder_tree.
	---
	valid_vecp : process(CLK, IN_VLD, ce)
	begin
		if rising_edge(CLK) then
			if ce = '1' then
				for i in valid_vec'range loop
					if i = 0 then
						valid_vec(0) <= IN_VLD;
					else
						valid_vec(i) <= valid_vec(i - 1);
					end if;
				end loop;
			end if;
		end if;
	end process;

	valid_out <= valid_vec(valid_vec'length - 1);

	---------------------------------

	ce      <= not valid_out or OUT_REQ; -- not safe when valid_out = '0' and OUT_REQ = '1'
	IN_REQ  <= IN_VLD and ce;
	OUT_VLD <= valid_out;
	LINE_CE <= ce;

end architecture;

