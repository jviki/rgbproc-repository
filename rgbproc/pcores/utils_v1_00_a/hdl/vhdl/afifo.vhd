-- afifo.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>
-- Copyright (C) 2011, 2012 Jan Viktorin

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity afifo is
generic (
	DWIDTH : integer := 8;
	DEPTH  : integer := 16
);
port (
	WCLK  : in  std_logic;
	RCLK  : in  std_logic;
	RESET : in  std_logic;

	WE    : in  std_logic;
	FULL  : out std_logic;
	DI    : in  std_logic_vector(DWIDTH - 1 downto 0);

	RE    : in  std_logic;
	EMPTY : out std_logic;
	DO    : out std_logic_vector(DWIDTH - 1 downto 0)
);
end entity;

architecture full of afifo is
	COMPONENT afifo_27b_16
	  PORT (
	    rst : IN STD_LOGIC;
	    wr_clk : IN STD_LOGIC;
	    rd_clk : IN STD_LOGIC;
	    din : IN STD_LOGIC_VECTOR(26 DOWNTO 0);
	    wr_en : IN STD_LOGIC;
	    rd_en : IN STD_LOGIC;
	    dout : OUT STD_LOGIC_VECTOR(26 DOWNTO 0);
	    full : OUT STD_LOGIC;
	    empty : OUT STD_LOGIC
	  );
	END COMPONENT;

	COMPONENT afifo_35b_16
	  PORT (
	    rst : IN STD_LOGIC;
	    wr_clk : IN STD_LOGIC;
	    rd_clk : IN STD_LOGIC;
	    din : IN STD_LOGIC_VECTOR(34 DOWNTO 0);
	    wr_en : IN STD_LOGIC;
	    rd_en : IN STD_LOGIC;
	    dout : OUT STD_LOGIC_VECTOR(34 DOWNTO 0);
	    full : OUT STD_LOGIC;
	    empty : OUT STD_LOGIC
	  );
	END COMPONENT;

	COMPONENT afifo_70b_16
	  PORT (
	    rst : IN STD_LOGIC;
	    wr_clk : IN STD_LOGIC;
	    rd_clk : IN STD_LOGIC;
	    din : IN STD_LOGIC_VECTOR(69 DOWNTO 0);
	    wr_en : IN STD_LOGIC;
	    rd_en : IN STD_LOGIC;
	    dout : OUT STD_LOGIC_VECTOR(69 DOWNTO 0);
	    full : OUT STD_LOGIC;
	    empty : OUT STD_LOGIC
	  );
	END COMPONENT;
begin

	assert (DWIDTH = 35 and DEPTH = 16)
	    or (DWIDTH = 27 and DEPTH = 16)
	    or (DWIDTH = 70 and DEPTH = 16)
		report "Invalid generic configuration: "
		     & integer'image(DWIDTH) & ", "
		     & integer'image(DEPTH)
		severity failure;

	--------------------------------------

gen_27b_16_afifo: if DWIDTH = 27 and DEPTH = 16
generate

	impl_i : afifo_27b_16
	port map (
		rst    => RESET,
		wr_clk => WCLK,
		rd_clk => RCLK,
		din    => DI,
		wr_en  => WE,
		full   => FULL,
		dout   => DO,
		rd_en  => RE,
		empty  => EMPTY
	);

end generate;
	--------------------------------------

gen_35b_16_afifo: if DWIDTH = 35 and DEPTH = 16
generate

	impl_i : afifo_35b_16
	port map (
		rst    => RESET,
		wr_clk => WCLK,
		rd_clk => RCLK,
		din    => DI,
		wr_en  => WE,
		full   => FULL,
		dout   => DO,
		rd_en  => RE,
		empty  => EMPTY
	);

end generate;

	--------------------------------------

gen_70b_16_afifo: if DWIDTH = 70 and DEPTH = 16
generate

	impl_i : afifo_70b_16
	port map (
		rst    => RESET,
		wr_clk => WCLK,
		rd_clk => RCLK,
		din    => DI,
		wr_en  => WE,
		full   => FULL,
		dout   => DO,
		rd_en  => RE,
		empty  => EMPTY
	);

end generate;

end architecture;
