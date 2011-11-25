-- vga_gen_rows.vhd
-- TODO: reference URL

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity vga_gen_stripes is
    port(clk, reset : in std_logic;   --clk:A9, reset:P143
			VGAout: out std_logic_vector(7 downto 0); --r(P35),r1(P33), g,g1, b,b1, hsyncO(P26), vsyncO(P25)
			LED: out std_logic -- P92
			);
end entity;

architecture synt of vga_gen_stripes is

signal videoon, videov, videoh,hsync, vsync : std_logic:='0';
signal VGA : std_logic_vector(5 downto 0);
signal hcount, vcount : integer range 0 to 1000:=0;
signal count:integer range 0 to 60:=0;	

begin
hcounter: process (clk, reset)
begin
    if reset='1' then 
        hcount <= 0;
    else 
        if (clk'event and clk='1') then 
            if hcount=799 then 
                hcount <= 0;
            else 
                hcount <= hcount + 1;
            end if;
        end if;
    end if;
end process;

process (hcount)
begin
    videoh <= '1';
    --column <= hcount;
    if hcount>639 then 
        videoh <= '0';
        --column <= (others => '0');
    end if;
end process;


vcounter: process (clk, reset)
begin
    if reset='1'then 
        vcount <= 0;
    else 
        if (clk'event and clk='1') then 
            if hcount=699 then 
                if vcount=524 then 
                    vcount <= 0;
                    count<=count+1;
                else 
                    vcount <= vcount + 1;
                end if;
					 if count>59 then
						count<=0;
						LED<='0';
					 elsif count>29 then
						LED<='1';
					 end if;
            end if;
        end if;
    end if;
end process;

process (vcount)
begin
    videov <= '1';
    --row <= vcount(8 downto 0);
    if vcount>479 then 
        videov <= '0';
        --row <= (others => '0');
    end if;
end process;

sync: process (clk, reset)
begin
    if reset='1'  then 
        hsync <= '0';
        vsync <= '0';
    else 
        if (clk'event and clk='1') then 
            if (hcount<=751 and hcount>=655) then 
                hsync <= '0';
            else 
                hsync <= '1';
            end if;
            if (vcount<=494 and vcount>=493) then 
            vsync <= '0';
            else 
            vsync <= '1';
            end if;
        end if;
end if;
end process;

videoon <= videoh and videov;

colors: process (clk, reset)
begin
    if reset='1' then 
		VGA<= 	"000000";
    elsif (clk'event and clk='1') then 
		case hcount is	
				when   0 to 39=>  VGA<= "000000";
				when  40 to 79=>  VGA<= "110000";
				when  80 to 119=> VGA<= "001100";
				when 120 to 159=> VGA<= "000011";
				when 160 to 199=> VGA<= "111100";
				when 200 to 239=> VGA<= "001111";
				when 240 to 279=> VGA<= "110011";
				when 280 to 319=> VGA<= "100000";
				when 320 to 359=> VGA<= "001000";
				when 360 to 399=> VGA<= "000010";
				when 400 to 439=> VGA<= "101000";
				when 440 to 479=> VGA<= "001010";
				when 480 to 519=> VGA<= "100010";
				when 520 to 559=> VGA<= "101010";
				when 560 to 599=> VGA<= "010101";
				when 600 to 639=> VGA<= "111111";
			   	when others=> NULL;
		end case;
    end if;
end process;
	VGAout(7 downto 2) <= VGA and videoon&videoon&videoon&videoon&videoon&videoon;
	VGAout(1 downto 0) <= hsync &  vsync;
end synt;
