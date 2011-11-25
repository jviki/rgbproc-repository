-- buffer_mem.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.log2;

entity buffer_mem is
generic (
	CAPACITY : integer;
	DWIDTH   : integer := 8
);
port (
	ARST     : in  std_logic;

	CLKA     : in  std_logic;
	ADDRA    : in  std_logic_vector(log2(CAPACITY) - 1 downto 0);
	DINA     : in  std_logic_vector(DWIDTH - 1 downto 0);
	DOUTA    : out std_logic_vector(DWIDTH - 1 downto 0);
	WEA      : in  std_logic;
	REA      : in  std_logic;
	DRDYA    : out std_logic;

	CLKB     : in  std_logic;
	ADDRB    : in  std_logic_vector(log2(CAPACITY) - 1 downto 0);
	DINB     : in  std_logic_vector(DWIDTH - 1 downto 0);
	DOUTB    : out std_logic_vector(DWIDTH - 1 downto 0);
	WEB      : in  std_logic;
	REB      : in  std_logic;
	DRDYB    : out std_logic
);
end entity;

architecture wrap_rgb_mem of buffer_mem is
begin

	assert DWIDTH = 8
		report "The rgb_mem was generated for 8 bit data width, requested: "
		     & integer'image(DWIDTH)
		severity error;

	assert CAPACITY >= 256 and CAPACITY <= 640 * 480
		report "The rgb_mem was generated for 640 * 480 bytes at maximum, requested: "
		     & integer'image(CAPACITY)
		severity error;

	-------------------------------

	rgb_mem_i : entity work.rgb_mem
	port map (
		clka   => CLKA,
		wea(0) => WEA,
		addra  => ADDRA(log2(CAPACITY) - 1 downto 0),
		dina   => DINA,
		douta  => DOUTA,

		clkb   => CLKB,
		web(0) => WEB,
		addrb  => ADDRB(log2(CAPACITY) - 1 downto 0),
		dinb   => DINB,
		doutb  => DOUTB
	);

end architecture;

architecture bram_model of buffer_mem is

	type mem_t is array(0 to CAPACITY - 1) of std_logic_vector(DWIDTH - 1 downto 0);

	signal mem       : mem_t;

	signal mem_wea   : std_logic;
	signal mem_addra : std_logic_vector(log2(CAPACITY) - 1 downto 0);
	signal mem_dina  : std_logic_vector(7 downto 0);
	signal mem_douta : std_logic_vector(7 downto 0);

	signal mem_web   : std_logic;
	signal mem_addrb : std_logic_vector(log2(CAPACITY) - 1 downto 0);
	signal mem_dinb  : std_logic_vector(7 downto 0);
	signal mem_doutb : std_logic_vector(7 downto 0);

begin

	mem_doutap : process(CLKA, mem_addra)
	begin
		if rising_edge(CLKA) then
			mem_douta <= mem(conv_integer(mem_addra));
		end if;
	end process;
	
	mem_dinap : process(CLKA, mem_addra, mem_wea, mem_dina)
	begin
		if rising_edge(CLKA) then
			if mem_wea = '1' then
				mem(conv_integer(mem_addra)) <= mem_dina;
			end if;
		end if;
	end process;

	----------------------------------------

	mem_doutbp : process(CLKB, mem_addrb)
	begin
		if rising_edge(CLKB) then
			mem_doutb <= mem(conv_integer(mem_addrb));
		end if;
	end process;
	
	mem_dinbp : process(CLKB, mem_addrb, mem_web, mem_dinb)
	begin
		if rising_edge(CLKB) then
			if mem_web = '1' then
				mem(conv_integer(mem_addrb)) <= mem_dinb;
			end if;
		end if;
	end process;

	----------------------------------------

	mem_wea   <= WEA;
	mem_dina  <= DINA;
	mem_addra <= ADDRA;
	DOUTA     <= mem_douta;

	mem_web   <= WEB;
	mem_dinb  <= DINB;
	mem_addrb <= ADDRB;
	DOUTB     <= mem_doutb;

end architecture;

