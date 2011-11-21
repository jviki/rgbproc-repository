-- buffer_if.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;

entity buffer_if is
generic (
	BUFF_CAP  : integer := 640 * 480 -- pixels
);
port map (
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
	IN_PTR    : out std_logic_vector(log2(BUFF_CAP) - 1 downto 0);

	---
	-- FIFO out
	---
	OUT_D     : out std_logic_vector(23 downto 0);
	OUT_RE    : in  std_logic;
	OUT_EMPTY : out std_logic;
	OUT_PTR   : out std_logic_vector(log2(BUFF_CAP) - 1 downto 0);

	---
	-- Random Access port 0
	---
	M0_A      : in  std_logic_vector(log2(BUFF_CAP) - 1 downto 0);
	M0_DO     : out std_logic_vector(23 downto 0);
	M0_WE     : in  std_logic;
	M0_DI     : in  std_logic_vector(23 downto 0);
	M0_RE     : in  std_logic;

	---
	-- Random Access port 1
	---
	M1_A      : in  std_logic_vector(log2(BUFF_CAP) - 1 downto 0);
	M1_DO     : out std_logic_vector(23 downto 0);
	M1_WE     : in  std_logic;
	M1_DI     : in  std_logic_vector(23 downto 0);
	M1_RE     : in  std_logic;

	MEM_SIZE  : out std_logic_vector(log2(BUFF_CAP) - 1 downto 0)
);
end entity;

architecture fsm_wrapper of buffer_if is

	constant UP        : std_logic := '1';
	constant DOWN      : std_logic := '0';

	type state_t is (s_in, s_mem, s_out);

	signal cnt_ptr_clr : std_logic;
	signal cnt_ptr_dir : std_logic;
	signal cnt_ptr_ce  : std_logic;
	signal cnt_ptr     : std_logic_vector(log2(BUFF_CAP) - 1 downto 0);

	signal state       : state_t;
	signal nstate      : state_t;

	signal m0_a        : std_logic_vector(log2(BUFF_CAP) - 1 downto 0);
	signal m0_dout     : std_logic_vector(23 downto 0);
	signal m0_we       : std_logic;
	signal m0_din      : std_logic_vector(23 downto 0);
	signal m0_re       : std_logic;

	signal m1_a        : std_logic_vector(log2(BUFF_CAP) - 1 downto 0);
	signal m1_dout     : std_logic_vector(23 downto 0);
	signal m1_we       : std_logic;
	signal m1_din      : std_logic_vector(23 downto 0);
	signal m1_re       : std_logic;

begin

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

	-------------------------------------

	IN_FULL   <= '1' when cnt_ptr = BUFF_CAP else RST;

	OUT_EMPTY <= '1' when cnt_ptr = 0 else RST;
	OUT_D     <= m1_dout;

	M0_DO     <= m0_dout;
	M1_DO     <= m1_dout;

	IN_PTR    <= cnt_ptr;
	OUT_PTR   <= cnt_ptr;
	MEM_SIZE  <= cnt_ptr;
	
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

	fsm_next(CLK, state, IN_DONE, MEM_DONE, OUT_DONE)
	begin
		nstate <= state;

		case state is
		when s_in  =>
			if IN_DONE = '1' then
				nstate <= s_mem;
			end if;

		when s_mem =>
			if MEM_DONE = '1' then
				nstate <= s_out;
			end if;

		when s_out =>
			if OUT_DONE = '1' then
				nstate <= s_in;
			end if;

		end case;
	end process;

	fsm_output(CLK, state, RST, IN_WE, OUT_DONE)
	begin
		IN_RDY  <= '0';
		OUT_RDY <= '0';
		MEM_RDY <= '0';

		cnt_ptr_dir <= UP;
		cnt_ptr_clr <= RST;
		cnt_ptr_ce  <= '0';

		m0_we <= '0';
		m0_re <= '0';
		m0_a    <= (others => 'X');
		m0_din  <= (others => 'X');

		m1_we <= '0';
		m1_re <= '0';
		m1_a    <= (others => 'X');
		m1_din  <= (others => 'X');

		case state is
		when s_in  =>
			cnt_ptr_dir <= UP;
			cnt_ptr_ce  <= IN_WE;

			m0_a    <= cnt_ptr;
			m0_din  <= IN_D;
			m0_we   <= IN_WE;
			m0_re   <= '0';

			IN_RDY  <= '1';

		when s_mem =>
			m0_a    <= M0_A;
			m0_din  <= M0_DI;
			m0_we   <= M0_WE;
			m0_re   <= M0_RE;

			m1_a    <= M1_A;
			m1_din  <= M1_DI;
			m1_we   <= M1_WE;
			m1_re   <= M1_RE;

			MEM_RDY <= '1';

		when s_out =>
			cnt_ptr_dir <= DOWN;
			cnt_ptr_ce  <= OUT_RE;
			cnt_ptr_clr <= OUT_DONE or RST;

			m1_a    <= cnt_ptr;
			m1_din  <= (others => 'X');
			m1_we   <= '0';
			m1_re   <= OUT_RE;

			OUT_RDY <= '1';

		end case;
	end process;

end architecture;
