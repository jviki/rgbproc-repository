-- rgb_reg.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity rgb_reg is
port (
	RGB_CLK     : in  std_logic;
	RGB_RST     : in  std_logic;

	---
	-- RGB input
	---
	RGB_IN_R    : in  std_logic_vector(7 downto 0);
	RGB_IN_G    : in  std_logic_vector(7 downto 0);
	RGB_IN_B    : in  std_logic_vector(7 downto 0);
	RGB_IN_EOL  : in  std_logic;
	RGB_IN_EOF  : in  std_logic;
	RGB_IN_VLD  : in  std_logic;
	RGB_IN_REQ  : out std_logic;

	---
	-- RGB output
	---
	RGB_OUT_R   : out std_logic_vector(7 downto 0);
	RGB_OUT_G   : out std_logic_vector(7 downto 0);
	RGB_OUT_B   : out std_logic_vector(7 downto 0);
	RGB_OUT_EOL : out std_logic;
	RGB_OUT_EOF : out std_logic;
	RGB_OUT_VLD : out std_logic;
	RGB_OUT_REQ : in  std_logic
);
end entity;

architecture full of rgb_reg is

	type state_t is (s_empty, s_full);

	signal state  : state_t;
	signal nstate : state_t;

	signal reg_d      : std_logic_vector(23 downto 0);
	signal reg_d_we   : std_logic;
	signal reg_end    : std_logic_vector(1 downto 0);
	signal reg_end_we : std_logic;

begin

	reg_dp : process(RGB_CLK, reg_d_we, RGB_IN_R, RGB_IN_G, RGB_IN_B)
	begin
		if rising_edge(RGB_CLK) then
			if reg_d_we = '1' then
				reg_d( 7 downto  0) <= RGB_IN_R;
				reg_d(15 downto  8) <= RGB_IN_G;
				reg_d(23 downto 16) <= RGB_IN_B;
			end if;
		end if;
	end process;

	reg_endp : process(RGB_CLK, reg_end_we, RGB_IN_EOL, RGB_IN_EOF)
	begin
		if rising_edge(RGB_CLK) then
			if reg_end_we = '1' then
				reg_end(0) <+ RGB_IN_EOL;
				reg_end(1) <+ RGB_IN_EOF;
			end if;
		end if;
	end process;

	---------------------------------------------

	fsm_state : process(RGB_CLK, RGB_RST, nstate)
	begin
		if rising_edge(RGB_CLK) then
			if RGB_RST = '1' then
				state <= s_empty;
			else
				state <= nstate;
			end if;
		end if;
	end process;

	fsm_next : process(RGB_CLK, state, RGB_IN_VLD, RGB_OUT_REQ)
	begin
		nstate <= state;

		case state is
			when s_empty =>
				if RGB_IN_VLD = '1' then
					nstate <= s_full;
				end if;

			when s_full  =>
				if RGB_IN_VLD = '0' and RGB_OUT_REQ = '1' then
					nstate <= s_empty;
				end if;
		end case;
	end process;

	fsm_output : process(RGB_CLK, state, RGB_IN_VLD)
	begin
		RGB_IN_REQ  <= '0';
		RGB_OUT_VLD <= '0';
		reg_d_we    <= '0';
		reg_end_we  <= '0';

		case state is
			when s_empty =>
				RGB_IN_REQ  <= RGB_IN_VLD;
				RGB_OUT_VLD <= '0';
				reg_d_we    <= RGB_IN_VLD;
				reg_end_we  <= RGB_IN_VLD;

			when s_full  =>
				RGB_IN_REQ  <= RGB_IN_VLD;
				RGB_OUT_VLD <= '1';
				reg_d_we    <= RGB_IN_VLD;
				reg_end_we  <= RGB_IN_VLD;
		end case;
	end process;

end architecture;

