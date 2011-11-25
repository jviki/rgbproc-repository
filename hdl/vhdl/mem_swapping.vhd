-- mem_swapping.vhd
-- Jan Viktorin <xvikto03@stud.fit.vutbr.cz>

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.log2;

---
-- Provides BRAM memory model that swaps
-- its contents to filesystem. This can
-- solve the issue with ISIM to not allocate
-- very huge amount of memory.
---
entity mem_swapping is
generic (
	MEM_CAP  : integer := 640 * 480;
	MEM_LINE : integer := 19200;
	DWIDTH   : integer := 8;
	PREFIX   : string  := "mem"
);
port (
	CLK       : in  std_logic;
	RST       : in  std_logic;

	MEM_A0    : in  std_logic_vector(log2(MEM_CAP) - 1 downto 0);
	MEM_DIN0  : in  std_logic_vector(DWIDTH - 1 downto 0);
	MEM_DOUT0 : out std_logic_vector(DWIDTH - 1 downto 0);
	MEM_WE0   : in  std_logic;
	MEM_RE0	  : in  std_logic;
	MEM_DRDY0 : out std_logic;

	MEM_A1    : in  std_logic_vector(log2(MEM_CAP) - 1 downto 0);
	MEM_DIN1  : in  std_logic_vector(DWIDTH - 1 downto 0);
	MEM_DOUT1 : out std_logic_vector(DWIDTH - 1 downto 0);
	MEM_WE1   : in  std_logic;
	MEM_RE1	  : in  std_logic;
	MEM_DRDY1 : out std_logic
);
end entity;

architecture full of mem_swapping is

	constant ADDRW : integer := log2(MEM_CAP);

	subtype memaddr_t is std_logic_vector(ADDRW  - 1 downto 0);
	subtype memcell_t is std_logic_vector(DWIDTH - 1 downto 0);
	type mempart_t is array(0 to MEM_LINE - 1) of memcell_t;
	type memfile_t is file of memcell_t;

	--------------------------------------------------------

	function get_memname(base : in integer) return string is
	begin
		assert base >= 0
			report "[MEM] Invalid base for access memory: " & integer'image(base)
			severity failure;

		return PREFIX & "/mem_" & integer'image(base);
	end function;

	function to_base(addr : in memaddr_t) return integer is
	begin
		return (conv_integer(addr) / MEM_LINE) * MEM_LINE;
	end function;

	--------------------------------------------------------

	procedure mem_load(base : in integer; mem : out mempart_t; dirty : out boolean) is
		file fd : memfile_t;
		variable fstat : file_open_status;
	begin
		file_open(fstat, fd, get_memname(base), READ_MODE);
		
		if fstat /= OPEN_OK then
			report "[MEM] Can not open file " & get_memname(base) & ", init to X";

			for i in mem'range loop
				mem(i) := (others => 'X');
			end loop;
		else
			for i in mem'range loop
				if endfile(fd) then
					report "[MEM] File is shorter then memory, finished at " & integer'image(i);
					exit;
				end if;

				read(fd, mem(i));
			end loop;

--			report "[MEM] Memory reloaded";
			dirty := false;
			file_close(fd);
		end if;
	end procedure;

	procedure mem_save(base : in integer; mem : in mempart_t; dirty : in boolean) is
		file fd : memfile_t;
		variable fstat : file_open_status;
	begin
		if base = -1 or dirty = false then
			return;
		end if;

		file_open(fstat, fd, get_memname(base), WRITE_MODE);
		
		assert fstat = OPEN_OK
			report "[MEM] Can not open file " & get_memname(base)
			severity failure;

		for i in mem'range loop
			write(fd, mem(i));
		end loop;
	end procedure;

	procedure mem_access(mem : inout mempart_t; base : inout integer;
	                     addr : in memaddr_t; dirty : inout boolean) is
		variable newbase : integer;
	begin
		newbase := to_base(addr);

		if newbase /= base then
			report "[MEM] Reloading memory block "
			     & integer'image(base)
			     & " => "
			     & integer'image(newbase)
			     & " ("
			     & integer'image(conv_integer(addr))
			     & ")";

			mem_save(base, mem, dirty);
			mem_load(newbase, mem, dirty);
			base := newbase;
		end if;
	end procedure;

	--------------------------------------------------------

	procedure mem_read(mem  : inout mempart_t; base : inout integer;
	                   addr : in memaddr_t;    data : out memcell_t;
	                   dirty : inout boolean) is

		variable addrbase : integer;
		variable addroff  : integer;
	begin
		addrbase := to_base(addr);
		addroff  := conv_integer(addr) - addrbase;

		mem_access(mem, base, addr, dirty);
		data := mem(addroff);
	end procedure;

	procedure mem_write(mem  : inout mempart_t; base : inout integer;
	                    addr : in memaddr_t;    data : in memcell_t;
	                    dirty : inout boolean) is
		variable addrbase : integer;
		variable addroff  : integer;
	begin
		addrbase := to_base(addr);
		addroff  := conv_integer(addr) - addrbase;

		mem_access(mem, base, addr, dirty);
		mem(addroff) := data;
		dirty := true;
	end procedure;

	--------------------------------------------------------

	shared variable mem  : mempart_t;
	shared variable dirty: boolean   := false;
	shared variable base : integer   := -1;

begin

	assert (MEM_CAP mod MEM_LINE) = 0
		report "MEM_LINE must be multiple of MEM_CAP"
		severity failure;

	--------------------------------------------------------

	mem_writep : process(CLK, MEM_WE0, MEM_A0, MEM_DIN0, MEM_WE1, MEM_A1, MEM_DIN1)
		variable addr : memaddr_t;
		variable din  : memcell_t;
	begin
		if rising_edge(CLK) then
			if MEM_WE0 = '1' then
				addr := MEM_A0;
				din  := MEM_DIN0;

				mem_write(mem, base, addr, din, dirty);
			end if;

			if MEM_WE1 = '1' then
				addr := MEM_A1;
				din  := MEM_DIN1;

				mem_write(mem, base, addr, din, dirty);
			end if;
		end if;
	end process;

	mem_readp : process(CLK, MEM_RE0, MEM_A0, MEM_RE1, MEM_A1)
		variable addr : memaddr_t;
		variable dout : memcell_t;
	begin
		if rising_edge(CLK) then
			if MEM_RE0 = '1' then
				addr := MEM_A0;

				mem_read(mem, base, addr, dout, dirty);
				MEM_DOUT0 <= dout;
			end if;

			if MEM_RE1 = '1' then
				addr := MEM_A1;

				mem_read(mem, base, addr, dout, dirty);
				MEM_DOUT1 <= dout;
			end if;
		end if;
	end process;

	mem_drdyp : process(CLK, MEM_RE0, MEM_RE1)
	begin
		if rising_edge(CLK) then
			if RST = '1' then
				MEM_DRDY0 <= '0';
				MEM_DRDY1 <= '0';
			else
				MEM_DRDY0 <= MEM_RE0;
				MEM_DRDY1 <= MEM_RE1;
			end if;
		end if;
	end process;

end architecture;

