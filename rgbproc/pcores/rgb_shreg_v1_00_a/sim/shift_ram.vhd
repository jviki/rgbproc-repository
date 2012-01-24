--------------------------------------------------------------------------------
--     (c) Copyright 1995 - 2010 Xilinx, Inc. All rights reserved.            --
--                                                                            --
--     This file contains confidential and proprietary information            --
--     of Xilinx, Inc. and is protected under U.S. and                        --
--     international copyright and other intellectual property                --
--     laws.                                                                  --
--                                                                            --
--     DISCLAIMER                                                             --
--     This disclaimer is not a license and does not grant any                --
--     rights to the materials distributed herewith. Except as                --
--     otherwise provided in a valid license issued to you by                 --
--     Xilinx, and to the maximum extent permitted by applicable              --
--     law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND                --
--     WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES            --
--     AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING              --
--     BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-                 --
--     INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and               --
--     (2) Xilinx shall not be liable (whether in contract or tort,           --
--     including negligence, or under any other theory of                     --
--     liability) for any loss or damage of any kind or nature                --
--     related to, arising under or in connection with these                  --
--     materials, including for any direct, or any indirect,                  --
--     special, incidental, or consequential loss or damage                   --
--     (including loss of data, profits, goodwill, or any type of             --
--     loss or damage suffered as a result of any action brought              --
--     by a third party) even if such damage or loss was                      --
--     reasonably foreseeable or Xilinx had been advised of the               --
--     possibility of the same.                                               --
--                                                                            --
--     CRITICAL APPLICATIONS                                                  --
--     Xilinx products are not designed or intended to be fail-               --
--     safe, or for use in any application requiring fail-safe                --
--     performance, such as life-support or safety devices or                 --
--     systems, Class III medical devices, nuclear facilities,                --
--     applications related to the deployment of airbags, or any              --
--     other applications that could lead to death, personal                  --
--     injury, or severe property or environmental damage                     --
--     (individually and collectively, "Critical                              --
--     Applications"). Customer assumes the sole risk and                     --
--     liability of any use of Xilinx products in Critical                    --
--     Applications, subject only to applicable laws and                      --
--     regulations governing limitations on product liability.                --
--                                                                            --
--     THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS               --
--     PART OF THIS FILE AT ALL TIMES.                                        --
--------------------------------------------------------------------------------
-- You must compile the wrapper file shift_ram.vhd when simulating
-- the core, shift_ram. When compiling the wrapper file, be sure to
-- reference the XilinxCoreLib VHDL simulation library. For detailed
-- instructions, please refer to the "CORE Generator Help".

-- The synthesis directives "translate_off/translate_on" specified
-- below are supported by Xilinx, Mentor Graphics and Synplicity
-- synthesis tools. Ensure they are correct for your synthesis tool(s).

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
-- synthesis translate_off
Library XilinxCoreLib;
-- synthesis translate_on
ENTITY shift_ram IS
	port (
	d: in std_logic_vector(26 downto 0);
	clk: in std_logic;
	ce: in std_logic;
	q: out std_logic_vector(26 downto 0));
END shift_ram;

ARCHITECTURE shift_ram_a OF shift_ram IS
-- synthesis translate_off
component wrapped_shift_ram
	port (
	d: in std_logic_vector(26 downto 0);
	clk: in std_logic;
	ce: in std_logic;
	q: out std_logic_vector(26 downto 0));
end component;

-- Configuration specification 
	for all : wrapped_shift_ram use entity XilinxCoreLib.c_shift_ram_v11_0(behavioral)
		generic map(
			c_parser_type => 0,
			c_read_mif => 0,
			c_has_a => 0,
			c_sync_priority => 1,
			c_opt_goal => 0,
			c_has_sclr => 0,
			c_width => 27,
			c_verbosity => 0,
			c_ainit_val => "000000000000000000000000000",
			c_has_ce => 1,
			c_sync_enable => 0,
			c_depth => 797,
			c_sinit_val => "000000000000000000000000000",
			c_has_sset => 0,
			c_has_sinit => 0,
			c_mem_init_file => "no_coe_file_loaded",
			c_shift_type => 0,
			c_default_data => "000000000000000000000000000",
			c_reg_last_bit => 1,
			c_xdevicefamily => "virtex5",
			c_addr_width => 4);
-- synthesis translate_on
BEGIN
-- synthesis translate_off
U0 : wrapped_shift_ram
		port map (
			d => d,
			clk => clk,
			ce => ce,
			q => q);
-- synthesis translate_on

END shift_ram_a;

