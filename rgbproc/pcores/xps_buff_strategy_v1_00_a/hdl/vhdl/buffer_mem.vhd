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
	CAPACITY  : integer;
	DWIDTH    : integer := 8;
	ID        : string  := "mem";
	SWAP_LINE : integer := 1024
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

	drdyap : process(CLKA, REA)
	begin 
		if rising_edge(CLKA) then
			DRDYA <= REA;
		end if;
	end process;

	drdybp : process(CLKB, REB)
	begin 
		if rising_edge(CLKB) then
			DRDYB <= REB;
		end if;
	end process;

end architecture;

architecture swapping_model of buffer_mem is
begin

	impl_i : entity work.mem_swapping
	generic map (
		MEM_CAP   => CAPACITY,
		MEM_LINE  => SWAP_LINE,
		DWIDTH    => DWIDTH,
		PREFIX    => ID
	)
	port map (
		CLK       => CLKA,
		RST       => ARST,

		MEM_A0    => ADDRA,
		MEM_DIN0  => DINA,
		MEM_DOUT0 => DOUTA,
		MEM_WE0   => WEA,
		MEM_RE0   => REA,
		MEM_DRDY0 => DRDYA,

		MEM_A1    => ADDRB,
		MEM_DIN1  => DINB,
		MEM_DOUT1 => DOUTB,
		MEM_WE1   => WEB,
		MEM_RE1   => REB,
		MEM_DRDY1 => DRDYB
	);

end architecture;

