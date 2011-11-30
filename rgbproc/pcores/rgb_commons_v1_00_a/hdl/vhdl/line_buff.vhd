-- line_buff.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.log2;

---
-- Buffer for one pixel line.
--
-- Writing and reading is done in two different clocks.
-- The clocks should be from the same domain and same
-- phase but can be of different speed (best are eg.
-- ratios 1/2 or 1/3). In that case assure that
-- IN_CLK'speed <= OUT_CLK'speed.
--
-- Read access to the buffer is allowed only when OUT_FULL
-- is asserted.
-- Write access to the buffer is allowed only when IN_FULL
-- is not asserted.
--
-- When the line is filled the *_FULL flags are asserted.
-- If the writer does not fill all the buffer but wants
-- to finish it asserts MARK_FULL. That forces *_FULL flags
-- to be set.
--
-- When all reading is done, MARK_EMPTY clears the *_FULL
-- flags. And reader can write again.
---
entity line_buff is
generic (
	LINE_WIDTH   : integer := 640;
	RATIO_OUT_IN : integer := 2 -- OUT_CLK is RATIO_OUT_IN times faster then IN_CLK
);
port (
	IN_CLK     : in  std_logic;
	IN_RST     : in  std_logic;

	IN_R       : in  std_logic_vector(7 downto 0);
	IN_G       : in  std_logic_vector(7 downto 0);
	IN_B       : in  std_logic_vector(7 downto 0);
	IN_WE      : in  std_logic;
	IN_FULL    : out std_logic;
	---
	-- Force the buffer to assert *_FULL flags.
	---
	MARK_FULL  : in  std_logic;

	OUT_CLK    : in  std_logic;
	OUT_RST    : in  std_logic;

	OUT_R      : out std_logic_vector(7 downto 0);
	OUT_G      : out std_logic_vector(7 downto 0);
	OUT_B      : out std_logic_vector(7 downto 0);
	OUT_ADDR   : in  std_logic_vector(log2(LINE_WIDTH) - 1 downto 0);
	OUT_FULL   : out std_logic;
	---
	-- Let the buffer to deassert *_FULL flags.
	---
	MARK_EMPTY : in  std_logic
);
end entity;

architecture bram of line_buff is

	signal reg_full         : std_logic;
	signal reg_full_set     : std_logic;
	signal reg_full_clr     : std_logic;

	signal reg_out_full     : std_logic_vector(RATIO_OUT_IN downto 0);
	signal fast_out_full    : std_logic;

	signal reg_mark_empty   : std_logic_vector(RATIO_OUT_IN downto 0);
	signal slow_mark_empty  : std_logic;

	signal cnt_in_addr      : std_logic_vector(log2(LINE_WIDTH) - 1 downto 0);
	signal cnt_in_addr_clr  : std_logic;
	signal cnt_in_addr_ce   : std_logic;

	---
	-- Behavioral dual port BlockRAM
	---
	type mem_t is array(0 to LINE_WIDTH - 1) of std_logic_vector(23 downto 0);
	shared variable rgb_mem : mem_t;

begin

	mem_port0 : process(IN_CLK, IN_WE, IN_R, IN_G, IN_B, cnt_in_addr)
		variable data : std_logic_vector(23 downto 0);
	begin
		if rising_edge(IN_CLK) then
			if reg_full = '0' then
				if IN_WE = '1' then
					data( 7 downto  0) := IN_R;
					data(15 downto  8) := IN_G;
					data(23 downto 16) := IN_B;
					rgb_mem(conv_integer(cnt_in_addr)) := data;
				end if;
			end if;
		end if;
	end process;

	mem_port1 : process(OUT_CLK, OUT_ADDR)
		variable data : std_logic_vector(23 downto 0);
	begin
		if rising_edge(OUT_CLK) then
			if fast_out_full = '1' then
				data := rgb_mem(conv_integer(OUT_ADDR));
				OUT_R <= data( 7 downto  0);
				OUT_G <= data(15 downto  8);
				OUT_B <= data(23 downto 16);
			end if;
		end if;
	end process;

	---------------------------------------------

	cnt_in_addrp : process(IN_CLK, IN_RST, cnt_in_addr_clr, cnt_in_addr_ce)
	begin
		if rising_edge(IN_CLK) then
			if IN_RST = '1' or cnt_in_addr_clr = '1' then
				cnt_in_addr <= (others => '0');
			elsif cnt_in_addr_ce = '1' then
				cnt_in_addr <= cnt_in_addr + 1;
			end if;
		end if;
	end process;

	cnt_in_addr_ce  <= IN_WE;
	cnt_in_addr_clr <= reg_full;

	---------------------------------------------

	reg_fullp : process(IN_CLK, reg_full_set, reg_full_clr)
	begin
		if rising_edge(IN_CLK) then
			if reg_full_clr = '1' or IN_RST = '1' then
				reg_full <= '0';
			elsif reg_full_set = '1' then
				reg_full <= '1';
			end if;
		end if;
	end process;

	reg_full_set <= IN_WE or MARK_FULL when cnt_in_addr = LINE_WIDTH else MARK_FULL;
	reg_full_clr <= slow_mark_empty;
	IN_FULL      <= reg_full;

	---------------------------------------------

	reg_out_fullp : process(OUT_CLK, reg_full)
	begin
		if rising_edge(OUT_CLK) then
			for i in reg_out_full'range loop
				if i = 0 then
					reg_out_full(i) <= reg_full;
				else
					reg_out_full(i) <= reg_out_full(i - 1);
				end if;
			end loop;
		end if;
	end process;

	fast_out_full <= reg_out_full(reg_out_full'length - 1);
	OUT_FULL      <= fast_out_full;

	---------------------------------------------

	reg_mark_emptyp : process(IN_CLK, MARK_EMPTY)
	begin
		if rising_edge(IN_CLK) then
			for i in reg_mark_empty'range loop
				if i = 0 then
					reg_mark_empty(i) <= MARK_EMPTY;
				else
					reg_mark_empty(i) <= reg_mark_empty(i - 1);
				end if;
			end loop;
		end if;
	end process;

	slow_mark_empty <= reg_mark_empty(reg_mark_empty'length - 1);

end architecture;

