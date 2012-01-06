all:
	ghdl -a --ieee=synopsys -fexplicit ../hdl/vhdl/utils_pkg.vhd ../hdl/vhdl/ipif*.vhd ../hdl/vhdl/a*.vhd *.vhd
	ghdl -e --ieee=synopsys -fexplicit ipif_reg_tb
	ghdl -r ipif_reg_tb --vcd=ipif_reg_tb.vcd
wave:
	gtkwave -A ipif_reg_tb.vcd

clean:
	ghdl --remove
