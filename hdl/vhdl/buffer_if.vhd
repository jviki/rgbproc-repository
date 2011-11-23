-- buffer_if.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.log2;
use proc_common_v3_00_a.srl_fifo;

entity buffer_if is
generic (
	WIDTH  : integer := 640; -- pixels
	HEIGHT : integer := 480  -- lines
);
port (
	---
	-- Global clock domain
	---
	CLK       : in  std_logic;
	RST       : in  std_logic;

	---
	-- Control
	---
	IN_DONE   : in  std_logic;
	IN_RDY    : out std_logic;
	
	OUT_DONE  : in  std_logic;
	OUT_RDY   : out std_logic;

	MEM_DONE  : in  std_logic;
	MEM_RDY   : out std_logic;

	---
	-- FIFO in
	---
	IN_D      : in  std_logic_vector(23 downto 0);
	IN_WE     : in  std_logic;
	IN_FULL   : out std_logic;

	---
	-- FIFO out
	---
	OUT_D     : out std_logic_vector(23 downto 0);
	OUT_RE    : in  std_logic;
	OUT_EMPTY : out std_logic;

	---
	-- Random Access port 0
	---
	M0_A      : in  std_logic_vector(log2(WIDTH * HEIGHT) - 1 downto 0);
	M0_DO     : out std_logic_vector(23 downto 0);
	M0_WE     : in  std_logic;
	M0_DI     : in  std_logic_vector(23 downto 0);
	M0_RE     : in  std_logic;
	M0_DRDY   : out std_logic;

	---
	-- Random Access port 1
	---
	M1_A      : in  std_logic_vector(log2(WIDTH * HEIGHT) - 1 downto 0);
	M1_DO     : out std_logic_vector(23 downto 0);
	M1_WE     : in  std_logic;
	M1_DI     : in  std_logic_vector(23 downto 0);
	M1_RE     : in  std_logic;
	M1_DRDY   : out std_logic;

	MEM_SIZE  : out std_logic_vector(log2(WIDTH * HEIGHT) - 1 downto 0)
);
end entity;

architecture fsm_wrapper of buffer_if is

	constant BUFF_CAP  : integer   := WIDTH * HEIGHT;
	constant UP        : std_logic := '1';
	constant DOWN      : std_logic := '0';

	type state_t is (s_in, s_mem, s_out0, s_out1, s_out);

	signal cnt_ptr_clr : std_logic;
	signal cnt_ptr_dir : std_logic;
	signal cnt_ptr_ce  : std_logic;
	signal cnt_ptr     : std_logic_vector(log2(BUFF_CAP) - 1 downto 0);

	signal reg_ptr     : std_logic_vector(log2(BUFF_CAP) - 1 downto 0);
	signal reg_ptr_we  : std_logic;

	signal state       : state_t;
	signal nstate      : state_t;

	signal mem0_a        : std_logic_vector(log2(BUFF_CAP) - 1 downto 0);
	signal mem0_dout     : std_logic_vector(23 downto 0);
	signal mem0_we       : std_logic;
	signal mem0_din      : std_logic_vector(23 downto 0);
	signal mem0_re       : std_logic;
	signal mem0_drdy     : std_logic;

	signal mem1_a        : std_logic_vector(log2(BUFF_CAP) - 1 downto 0);
	signal mem1_dout     : std_logic_vector(23 downto 0);
	signal mem1_we       : std_logic;
	signal mem1_din      : std_logic_vector(23 downto 0);
	signal mem1_re       : std_logic;
	signal mem1_drdy     : std_logic;

	signal out_fifo_we   : std_logic;
	signal out_fifo_full : std_logic;
	signal out_fifo_re   : std_logic;
	signal out_fifo_not_empty : std_logic;
	signal out_fifo_rst  : std_logic;

begin

	assert BUFF_CAP = 640 * 480
		report "Current buffer_if implementation does not support memory size"
		     & " other then 640 * 480"
		severity error;

	-------------------------------------

	cnt_ptrp : process(CLK, cnt_ptr_clr, cnt_ptr_ce)
	begin
		if rising_edge(CLK) then
			if cnt_ptr_clr = '1' then
				cnt_ptr <= (others => '0');
			elsif cnt_ptr_ce = '1' then
				if cnt_ptr_dir = UP then
					cnt_ptr <= cnt_ptr + 1;
				else
					cnt_ptr <= cnt_ptr - 1;
				end if;
			end if;
		end if;
	end process;

	reg_ptrp : process(CLK, reg_ptr_we, cnt_ptr)
	begin
		if rising_edge(CLK) then
			if reg_ptr_we = '1' then
				reg_ptr <= cnt_ptr;
			end if;
		end if;
	end process;

	-------------------------------------

	IN_FULL   <= '1' when cnt_ptr = BUFF_CAP else RST;
	OUT_EMPTY <= not out_fifo_not_empty;

	M0_DO     <= mem0_dout;
	M0_DRDY   <= mem0_drdy;
	M1_DO     <= mem1_dout;
	M1_DRDY   <= mem1_drdy;

	MEM_SIZE  <= cnt_ptr;
	
	-------------------------------------

	mem_drdyp : process(CLK, mem0_re, mem1_re)
	begin
		if rising_edge(CLK) then
			mem0_drdy <= mem0_re;
			mem1_drdy <= mem1_re;
		end if;
	end process;

	-------------------------------------

	srl_fifo_i : entity proc_common_v3_00_a.srl_fifo
	generic map (
		C_DATA_BITS => 24,
		C_DEPTH     => 16
	)
	port map (
		CLK         => CLK,
		Reset       => out_fifo_rst,
		FIFO_Write  => out_fifo_we,
		Data_In     => mem1_dout,
		FIFO_Read   => out_fifo_re,
		Data_Out    => OUT_D,
		FIFO_Full   => out_fifo_full,
		Data_Exists => out_fifo_not_empty,
		Addr => open
	);

	-------------------------------------
	
	red_bram_i : entity work.rgb_mem
	port map (
		clka   => CLK,
		wea(0) => mem0_we,
		addra  => mem0_a,
		dina   => mem0_din(7 downto 0),
		douta  => mem0_dout(7 downto 0),

		clkb   => CLK,
		web(0) => mem1_we,
		addrb  => mem1_a,
		dinb   => mem1_din(7 downto 0),
		doutb  => mem1_dout(7 downto 0)
	);

	green_bram_i : entity work.rgb_mem
	port map (
		clka   => CLK,
		wea(0) => mem0_we,
		addra  => mem0_a,
		dina   => mem0_din(15 downto 8),
		douta  => mem0_dout(15 downto 8),

		clkb   => CLK,
		web(0) => mem1_we,
		addrb  => mem1_a,
		dinb   => mem1_din(15 downto 8),
		doutb  => mem1_dout(15 downto 8)
	);

	blue_bram_i : entity work.rgb_mem
	port map (
		clka   => CLK,
		wea(0) => mem0_we,
		addra  => mem0_a,
		dina   => mem0_din(23 downto 16),
		douta  => mem0_dout(23 downto 16),

		clkb   => CLK,
		web(0) => mem1_we,
		addrb  => mem1_a,
		dinb   => mem1_din(23 downto 16),
		doutb  => mem1_dout(23 downto 16)
	);
	
	-------------------------------------

	fsm_state : process(CLK, RST, nstate)
	begin
		if rising_edge(CLK) then
			if RST = '1' then
				state <= s_in;
			else
				state <= nstate;
			end if;
		end if;
	end process;

	fsm_next : process(CLK, state, IN_DONE, MEM_DONE, OUT_DONE)
	begin
		nstate <= state;

		case state is
		when s_in  =>
			if IN_DONE = '1' then
				nstate <= s_mem;
			end if;

		when s_mem =>
			if MEM_DONE = '1' then
				nstate <= s_out0;
			end if;

		when s_out0 =>
			if OUT_DONE = '1' then
				nstate <= s_in;
			else
				nstate <= s_out1;
			end if;

		when s_out1 =>
			if OUT_DONE = '1' then
				nstate <= s_in;
			elsif out_fifo_not_empty = '1' then
				nstate <= s_out;
			end if;

		when s_out =>
			if OUT_DONE = '1' then
				nstate <= s_in;
			end if;

		end case;
	end process;

	fsm_output : process(CLK, state, RST, cnt_ptr, reg_ptr,
	                     IN_D, IN_WE, OUT_RE, OUT_DONE,
	                     M0_A, M0_DI, M0_WE, M0_RE,
	                     M1_A, M1_DI, M1_WE, M1_RE)
	begin
		IN_RDY  <= '0';
		OUT_RDY <= '0';
		MEM_RDY <= '0';

		cnt_ptr_dir <= UP;
		cnt_ptr_clr <= RST;
		cnt_ptr_ce  <= '0';
		reg_ptr_we  <= '0';

		out_fifo_we  <= '0';
		out_fifo_re  <= '0';
		out_fifo_rst <= RST;

		mem0_we <= '0';
		mem0_re <= '0';
		mem0_a    <= (others => 'X');
		mem0_din  <= (others => 'X');

		mem1_we <= '0';
		mem1_re <= '0';
		mem1_a    <= (others => 'X');
		mem1_din  <= (others => 'X');

		case state is
		when s_in  =>
			cnt_ptr_dir <= UP;
			cnt_ptr_ce  <= IN_WE;
			reg_ptr_we  <= IN_DONE;

			mem0_a    <= cnt_ptr;
			mem0_din  <= IN_D;
			mem0_we   <= IN_WE;

			IN_RDY  <= '1';

		when s_mem =>
			mem0_a    <= M0_A;
			mem0_din  <= M0_DI;
			mem0_we   <= M0_WE;
			mem0_re   <= M0_RE;

			mem1_a    <= M1_A;
			mem1_din  <= M1_DI;
			mem1_we   <= M1_WE;
			mem1_re   <= M1_RE;

			MEM_RDY <= '1';

		when s_out0 =>
			if (reg_ptr - cnt_ptr) < reg_ptr then
				cnt_ptr_ce  <= not out_fifo_full;
			end if;

			cnt_ptr_dir <= DOWN;
			cnt_ptr_clr <= OUT_DONE or RST;
			out_fifo_rst <= OUT_DONE or RST;

			mem1_a    <= reg_ptr - cnt_ptr;
			mem1_din  <= (others => 'X');
			mem1_we   <= '0';

			OUT_RDY <= '0';

		when s_out1 =>
			if (reg_ptr - cnt_ptr) < reg_ptr then
				cnt_ptr_ce  <= not out_fifo_full;
				out_fifo_we  <= not out_fifo_full;
			end if;

			cnt_ptr_dir <= DOWN;
			cnt_ptr_clr <= OUT_DONE or RST;
			out_fifo_rst <= OUT_DONE or RST;

			mem1_a    <= reg_ptr - cnt_ptr;
			mem1_din  <= (others => 'X');
			mem1_we   <= '0';

			OUT_RDY <= '0';

		when s_out =>
			if (reg_ptr - cnt_ptr) < reg_ptr then
				cnt_ptr_ce  <= not out_fifo_full;
				out_fifo_we  <= not out_fifo_full;
			end if;

			cnt_ptr_dir <= DOWN;
			cnt_ptr_clr <= OUT_DONE or RST;

			out_fifo_re  <= OUT_RE;
			out_fifo_rst <= OUT_DONE or RST;

			mem1_a    <= reg_ptr - cnt_ptr;
			mem1_din  <= (others => 'X');
			mem1_we   <= '0';

			OUT_RDY <= '1';

		end case;
	end process;

end architecture;
