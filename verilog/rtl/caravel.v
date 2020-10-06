/*--------------------------------------------------------------*/
/* caravel, a project harness for the Google/SkyWater sky130	*/
/* fabrication process and open source PDK			*/
/*                                                          	*/
/* Copyright 2020 efabless, Inc.                            	*/
/* Written by Tim Edwards, December 2019                    	*/
/* and Mohamed Shalan, August 2020			    	*/
/* This file is open source hardware released under the     	*/
/* Apache 2.0 license.  See file LICENSE.                   	*/
/*                                                          	*/
/*--------------------------------------------------------------*/

`timescale 1 ns / 1 ps

`define USE_OPENRAM
`define USE_PG_PIN
`define functional
`define UNIT_DELAY #1

`define MPRJ_IO_PADS 32

`include "pads.v"

/* To be removed when sky130_fd_io is available */
// `include "/ef/tech/SW/EFS8A/libs.ref/verilog/s8iom0s8/s8iom0s8.v"
// `include "/ef/tech/SW/EFS8A/libs.ref/verilog/s8iom0s8/power_pads_lib.v"
// `include "/ef/tech/SW/sky130A/libs.ref/verilog/sky130_fd_sc_hd/sky130_fd_sc_hd.v"
// `include "/ef/tech/SW/sky130A/libs.ref/verilog/sky130_fd_sc_hvl/sky130_fd_sc_hvl.v"

/* Local only, please remove */
// `include "/home/tim/projects/efabless/tech/SW/sky130A/libs.ref/sky130_fd_io/verilog/sky130_fd_io.v"
// `include "/home/tim/projects/efabless/tech/SW/sky130A/libs.ref/sky130_fd_io/verilog/power_pads_lib.v"
`include "/home/tim/projects/efabless/tech/SW/EFS8A/libs.ref/s8iom0s8/verilog/s8iom0s8.v"
// `include "/home/tim/projects/efabless/tech/SW/EFS8A/libs.ref/s8iom0s8/verilog/power_pads_lib.v"
`include "/home/tim/projects/efabless/tech/SW/sky130A/libs.ref/sky130_fd_sc_hd/verilog/primitives.v"
`include "/home/tim/projects/efabless/tech/SW/sky130A/libs.ref/sky130_fd_sc_hd/verilog/sky130_fd_sc_hd.v"
`include "/home/tim/projects/efabless/tech/SW/sky130A/libs.ref/sky130_fd_sc_hvl/verilog/primitives.v"
`include "/home/tim/projects/efabless/tech/SW/sky130A/libs.ref/sky130_fd_sc_hvl/verilog/sky130_fd_sc_hvl.v"

`include "mgmt_soc.v"
`include "housekeeping_spi.v"
`include "digital_pll.v"
`include "caravel_clkrst.v"
`include "mgmt_core.v"
`include "mprj_io.v"
`include "chip_io.v"
`include "user_id_programming.v"
`include "gpio_control_block.v"
`include "simple_por.v"

/*------------------------------*/
/* Include user project here	*/
/*------------------------------*/
`include "user_proj_example.v"

`ifdef USE_OPENRAM
    `include "sram_1rw1r_32_8192_8_sky130.v"
`endif

module caravel (
    inout vdd3v3,
    inout vdd1v8,
    inout vss,
    inout gpio,			// Used for external LDO control
    inout [`MPRJ_IO_PADS-1:0] mprj_io,
    input clock,	    	// CMOS core clock input, not a crystal
    input resetb,

    // Note that only two pins are available on the flash so dual and
    // quad flash modes are not available.

    output flash_csb,
    output flash_clk,
    output flash_io0,
    output flash_io1
);

    //------------------------------------------------------------
    // This value is uniquely defined for each user project.
    //------------------------------------------------------------
    parameter USER_PROJECT_ID = 32'h0;

    // These pins are overlaid on mprj_io space.  They have the function
    // below when the management processor is in reset, or in the default
    // configuration.  They are assigned to uses in the user space by the
    // configuration program running off of the SPI flash.  Note that even
    // when the user has taken control of these pins, they can be restored
    // to the original use by setting the resetb pin low.  The SPI pins and
    // UART pins can be connected directly to an FTDI chip as long as the
    // FTDI chip sets these lines to high impedence (input function) at
    // all times except when holding the chip in reset.

    // JTAG      = mprj_io[0]		(inout)
    // SDO 	 = mprj_io[1]		(output)
    // SDI 	 = mprj_io[2]		(input)
    // CSB 	 = mprj_io[3]		(input)
    // SCK	 = mprj_io[4]		(input)
    // ser_rx    = mprj_io[5]		(input)
    // ser_tx    = mprj_io[6]		(output)
    // irq 	 = mprj_io[7]		(input)

    // These pins are reserved for any project that wants to incorporate
    // its own processor and flash controller.  While a user project can
    // technically use any available I/O pins for the purpose, these
    // four pins connect to a pass-through mode from the SPI slave (pins
    // 1-4 above) so that any SPI flash connected to these specific pins
    // can be accessed through the SPI slave even when the processor is in
    // reset.

    // user_flash_csb = mprj_io[8]
    // user_flash_sck = mprj_io[9]
    // user_flash_io0 = mprj_io[10]
    // user_flash_io1 = mprj_io[11]

    // One-bit GPIO dedicated to management SoC (outside of user control)
    wire gpio_out_core;
    wire gpio_in_core;
    wire gpio_mode0_core;
    wire gpio_mode1_core;
    wire gpio_outenb_core;
    wire gpio_inenb_core;

    // Mega-Project Control (pad-facing)
    wire mprj_io_loader_resetn;
    wire mprj_io_loader_clock;
    wire mprj_io_loader_data;

    wire [`MPRJ_IO_PADS-1:0] mprj_io_hldh_n;
    wire [`MPRJ_IO_PADS-1:0] mprj_io_enh;
    wire [`MPRJ_IO_PADS-1:0] mprj_io_inp_dis;
    wire [`MPRJ_IO_PADS-1:0] mprj_io_oeb;
    wire [`MPRJ_IO_PADS-1:0] mprj_io_ib_mode_sel;
    wire [`MPRJ_IO_PADS-1:0] mprj_io_vtrip_sel;
    wire [`MPRJ_IO_PADS-1:0] mprj_io_slow_sel;
    wire [`MPRJ_IO_PADS-1:0] mprj_io_holdover;
    wire [`MPRJ_IO_PADS-1:0] mprj_io_analog_en;
    wire [`MPRJ_IO_PADS-1:0] mprj_io_analog_sel;
    wire [`MPRJ_IO_PADS-1:0] mprj_io_analog_pol;
    wire [`MPRJ_IO_PADS*3-1:0] mprj_io_dm;
    wire [`MPRJ_IO_PADS-1:0] mprj_io_in;
    wire [`MPRJ_IO_PADS-1:0] mprj_io_out;

    // Mega-Project Control (user-facing)
    wire [`MPRJ_IO_PADS-1:0] user_io_oeb;
    wire [`MPRJ_IO_PADS-1:0] user_io_in;
    wire [`MPRJ_IO_PADS-1:0] user_io_out;

    /* Padframe control signals */
    wire [`MPRJ_IO_PADS-1:0] gpio_serial_link;
    wire mgmt_serial_clock;
    wire mgmt_serial_resetn;

    // Mega-Project Control management I/O
    // There are two types of GPIO connections:
    // (1) Full Bidirectional: Management connects to in, out, and oeb
    //     Uses:  JTAG and SDO
    // (2) Selectable bidirectional:  Management connects to in and out,
    //	   which are tied together.  oeb is grounded (oeb from the
    //	   configuration is used)

    // SDI 	 = mprj_io[2]		(input)
    // CSB 	 = mprj_io[3]		(input)
    // SCK	 = mprj_io[4]		(input)
    // ser_rx    = mprj_io[5]		(input)
    // ser_tx    = mprj_io[6]		(output)
    // irq 	 = mprj_io[7]		(input)

    wire [`MPRJ_IO_PADS-1:0] mgmt_io_in;
    wire jtag_out, sdo_out; 		
    wire jtag_outenb, sdo_outenb; 

    wire [`MPRJ_IO_PADS-3:0] mgmt_io_nc1;	/* no-connects */
    wire [`MPRJ_IO_PADS-3:0] mgmt_io_nc3;	/* no-connects */
    wire [1:0] mgmt_io_nc2;			/* no-connects */

    // Power-on-reset signal.  The reset pad generates the sense-inverted
    // reset at 3.3V.  The 1.8V signal and the inverted 1.8V signal are
    // derived.

    wire porb_h;
    wire porb_l;

    wire rstb_h;
    wire rstb_l;

    // To be considered:  Master hold signal on all user pads (?)
    // For now, set holdh_n to 1 (NOTE:  This is in the 3.3V domain)
    // and setting enh to porb_h.
    assign mprj_io_hldh_n = {`MPRJ_IO_PADS{vdd3v3}};
    assign mprj_io_enh = {`MPRJ_IO_PADS{porb_h}};

    chip_io padframe(
	// Package Pins
	.vdd3v3(vdd3v3),
	.vdd1v8(vdd1v8),
	.vss(vss),
	.gpio(gpio),
	.mprj_io(mprj_io),
	.clock(clock),
	.resetb(resetb),
	.flash_csb(flash_csb),
	.flash_clk(flash_clk),
	.flash_io0(flash_io0),
	.flash_io1(flash_io1),
	// SoC Core Interface
	.porb_h(porb_h),
	.resetb_core_h(rstb_h),
	.clock_core(clock_core),
	.gpio_out_core(gpio_out_core),
	.gpio_in_core(gpio_in_core),
	.gpio_mode0_core(gpio_mode0_core),
	.gpio_mode1_core(gpio_mode1_core),
	.gpio_outenb_core(gpio_outenb_core),
	.gpio_inenb_core(gpio_inenb_core),
	.flash_csb_core(flash_csb_core),
	.flash_clk_core(flash_clk_core),
	.flash_csb_oeb_core(flash_csb_oeb_core),
	.flash_clk_oeb_core(flash_clk_oeb_core),
	.flash_io0_oeb_core(flash_io0_oeb_core),
	.flash_io1_oeb_core(flash_io1_oeb_core),
	.flash_csb_ieb_core(flash_csb_ieb_core),
	.flash_clk_ieb_core(flash_clk_ieb_core),
	.flash_io0_ieb_core(flash_io0_ieb_core),
	.flash_io1_ieb_core(flash_io1_ieb_core),
	.flash_io0_do_core(flash_io0_do_core),
	.flash_io1_do_core(flash_io1_do_core),
	.flash_io0_di_core(flash_io0_di_core),
	.flash_io1_di_core(flash_io1_di_core),
	.por(~porb_l),
	.mprj_io_in(mprj_io_in),
	.mprj_io_out(mprj_io_out),
	.mprj_io_oeb(mprj_io_oeb),
        .mprj_io_hldh_n(mprj_io_hldh_n),
	.mprj_io_enh(mprj_io_enh),
        .mprj_io_inp_dis(mprj_io_inp_dis),
        .mprj_io_ib_mode_sel(mprj_io_ib_mode_sel),
        .mprj_io_vtrip_sel(mprj_io_vtrip_sel),
        .mprj_io_slow_sel(mprj_io_slow_sel),
        .mprj_io_holdover(mprj_io_holdover),
        .mprj_io_analog_en(mprj_io_analog_en),
        .mprj_io_analog_sel(mprj_io_analog_sel),
        .mprj_io_analog_pol(mprj_io_analog_pol),
        .mprj_io_dm(mprj_io_dm)
    );

    // SoC core
    wire caravel_clk;
    wire caravel_rstn;

    wire [7:0] spi_ro_config_core;

    // LA signals
    wire [127:0] la_output_core;   // From CPU to MPRJ
    wire [127:0] la_data_in_mprj;  // From CPU to MPRJ
    wire [127:0] la_data_out_mprj; // From CPU to MPRJ
    wire [127:0] la_output_mprj;   // From MPRJ to CPU
    wire [127:0] la_oen;           // LA output enable from CPU perspective (active-low) 
	
    // WB MI A (Mega Project)
    wire mprj_cyc_o_core;
    wire mprj_stb_o_core;
    wire mprj_we_o_core;
    wire [3:0] mprj_sel_o_core;
    wire [31:0] mprj_adr_o_core;
    wire [31:0] mprj_dat_o_core;
    wire mprj_ack_i_core;
    wire [31:0] mprj_dat_i_core;

    // WB MI B (xbar)
    wire xbar_cyc_o_core;
    wire xbar_stb_o_core;
    wire xbar_we_o_core;
    wire [3:0] xbar_sel_o_core;
    wire [31:0] xbar_adr_o_core;
    wire [31:0] xbar_dat_o_core;
    wire xbar_ack_i_core;
    wire [31:0] xbar_dat_i_core;

    // Mask revision
    wire [31:0] mask_rev;

    mgmt_core soc (
	`ifdef LVS
		.vdd1v8(vdd1v8),
		.vss(vss),
	`endif
		// GPIO (1 pin)
		.gpio_out_pad(gpio_out_core),
		.gpio_in_pad(gpio_in_core),
		.gpio_mode0_pad(gpio_mode0_core),
		.gpio_mode1_pad(gpio_mode1_core),
		.gpio_outenb_pad(gpio_outenb_core),
		.gpio_inenb_pad(gpio_inenb_core),
		// Primary SPI flash controller
		.flash_csb(flash_csb_core),
		.flash_clk(flash_clk_core),
		.flash_csb_oeb(flash_csb_oeb_core),
		.flash_clk_oeb(flash_clk_oeb_core),
		.flash_io0_oeb(flash_io0_oeb_core),
		.flash_io1_oeb(flash_io1_oeb_core),
		.flash_csb_ieb(flash_csb_ieb_core),
		.flash_clk_ieb(flash_clk_ieb_core),
		.flash_io0_ieb(flash_io0_ieb_core),
		.flash_io1_ieb(flash_io1_ieb_core),
		.flash_io0_do(flash_io0_do_core),
		.flash_io1_do(flash_io1_do_core),
		.flash_io0_di(flash_io0_di_core),
		.flash_io1_di(flash_io1_di_core),
		// Master Reset
		.resetb(rstb_l),
		.porb(porb_l),
		// Clocks and reset
		.clock(clock_core),
		.pll_clk16(pll_clk16),
        	.core_clk(caravel_clk),
        	.core_rstn(caravel_rstn),
		// Logic Analyzer 
		.la_input(la_data_out_mprj),
		.la_output(la_output_core),
		.la_oen(la_oen),
		// Mega Project IO Control
		.mprj_io_loader_resetn(mprj_io_loader_resetn),
		.mprj_io_loader_clock(mprj_io_loader_clock),
		.mprj_io_loader_data(mprj_io_loader_data),
		.mgmt_in_data(mgmt_io_in),
		.mgmt_out_data({mgmt_io_in[(`MPRJ_IO_PADS-1):2], mgmt_io_nc2}),
		.sdo_out(sdo_out),
		.sdo_outenb(sdo_outenb),
		.jtag_out(jtag_out),
		.jtag_outenb(jtag_outenb),
		// Mega Project Slave ports (WB MI A)
		.mprj_cyc_o(mprj_cyc_o_core),
		.mprj_stb_o(mprj_stb_o_core),
		.mprj_we_o(mprj_we_o_core),
		.mprj_sel_o(mprj_sel_o_core),
		.mprj_adr_o(mprj_adr_o_core),
		.mprj_dat_o(mprj_dat_o_core),
		.mprj_ack_i(mprj_ack_i_core),
		.mprj_dat_i(mprj_dat_i_core),
		// Xbar Switch (WB MI B)
        	.xbar_cyc_o(xbar_cyc_o_core),
        	.xbar_stb_o(xbar_stb_o_core),
        	.xbar_we_o (xbar_we_o_core),
        	.xbar_sel_o(xbar_sel_o_core),
        	.xbar_adr_o(xbar_adr_o_core),
        	.xbar_dat_o(xbar_dat_o_core),
        	.xbar_ack_i(xbar_ack_i_core),
        	.xbar_dat_i(xbar_dat_i_core),
		// mask data
		.mask_rev(mask_rev)
    	);

	sky130_fd_sc_hd__ebufn_8 la_buf [127:0] (
		.Z(la_data_in_mprj),
		.A(la_output_core),
		.TE_B(la_oen)
	);
	
	/*--------------------------------------*/
	/* User project is instantiated  here	*/
	/*--------------------------------------*/

	user_proj_example mprj ( 
    		.wb_clk_i(caravel_clk),
    		.wb_rst_i(!caravel_rstn),
		// MGMT SoC Wishbone Slave 
		.wbs_cyc_i(mprj_cyc_o_core),
		.wbs_stb_i(mprj_stb_o_core),
		.wbs_we_i(mprj_we_o_core),
		.wbs_sel_i(mprj_sel_o_core),
	    	.wbs_adr_i(mprj_adr_o_core),
		.wbs_dat_i(mprj_dat_o_core),
	    	.wbs_ack_o(mprj_ack_i_core),
		.wbs_dat_o(mprj_dat_i_core),
		// Logic Analyzer
		.la_data_in(la_data_in_mprj),
		.la_data_out(la_data_out_mprj),
		.la_oen (la_oen),
		// IO Pads
		.io_in (user_io_in),
    		.io_out(user_io_out)
	);

	/*--------------------------------------*/
	/* End user project instantiation	*/
	/*--------------------------------------*/

    wire [`MPRJ_IO_PADS-1:0] gpio_serial_link_shifted;

    assign gpio_serial_link_shifted = {gpio_serial_link[`MPRJ_IO_PADS-2:0], mprj_io_loader_data};

    // Each control block sits next to an I/O pad in the user area.
    // It gets input through a serial chain from the previous control
    // block and passes it to the next control block.  Due to the nature
    // of the shift register, bits are presented in reverse, as the first
    // bit in ends up as the last bit of the last I/O pad control block.

    // There are two types of block;  the first two are configured to be
    // full bidirectional under control of the management Soc (JTAG and
    // SDO).  The rest are configured to be default (input).

    gpio_control_block #(
	.DM_INIT(3'b110),	// Mode = output, strong up/down
	.OENB_INIT(1'b0)	// Enable output signaling from wire
    ) gpio_control_bidir [1:0] (

    	// Management Soc-facing signals

    	.resetn(mprj_io_loader_resetn),
    	.serial_clock(mprj_io_loader_clock),

    	.mgmt_gpio_in(mgmt_io_in[1:0]),
	.mgmt_gpio_out({sdo_out, jtag_out}),
	.mgmt_gpio_oeb({sdo_outenb, jtag_outenb}),

    	// Serial data chain for pad configuration
    	.serial_data_in(gpio_serial_link_shifted[1:0]),
    	.serial_data_out(gpio_serial_link[1:0]),

    	// User-facing signals
    	.user_gpio_out(user_io_out[1:0]),
    	.user_gpio_oeb(user_io_oeb[1:0]),
    	.user_gpio_in(user_io_in[1:0]),

    	// Pad-facing signals (Pad GPIOv2)
    	.pad_gpio_inenb(mprj_io_inp_dis[1:0]),
    	.pad_gpio_ib_mode_sel(mprj_io_ib_mode_sel[1:0]),
    	.pad_gpio_vtrip_sel(mprj_io_vtrip_sel[1:0]),
    	.pad_gpio_slow_sel(mprj_io_slow_sel[1:0]),
    	.pad_gpio_holdover(mprj_io_holdover[1:0]),
    	.pad_gpio_ana_en(mprj_io_analog_en[1:0]),
    	.pad_gpio_ana_sel(mprj_io_analog_sel[1:0]),
    	.pad_gpio_ana_pol(mprj_io_analog_pol[1:0]),
    	.pad_gpio_dm(mprj_io_dm[5:0]),
    	.pad_gpio_outenb(mprj_io_oeb[1:0]),
    	.pad_gpio_out(mprj_io_out[1:0]),
    	.pad_gpio_in(mprj_io_in[1:0])
    );

    gpio_control_block gpio_control_in [`MPRJ_IO_PADS-1:2] (

    	// Management Soc-facing signals

    	.resetn(mprj_io_loader_resetn),
    	.serial_clock(mprj_io_loader_clock),

	.mgmt_gpio_in(mgmt_io_in[(`MPRJ_IO_PADS-1):2]),
	.mgmt_gpio_out(mgmt_io_in[(`MPRJ_IO_PADS-1):2]),
	.mgmt_gpio_oeb(1'b1),

    	// Serial data chain for pad configuration
    	.serial_data_in(gpio_serial_link_shifted[(`MPRJ_IO_PADS-1):2]),
    	.serial_data_out(gpio_serial_link[(`MPRJ_IO_PADS-1):2]),

    	// User-facing signals
    	.user_gpio_out(user_io_out[(`MPRJ_IO_PADS-1):2]),
    	.user_gpio_oeb(user_io_oeb[(`MPRJ_IO_PADS-1):2]),
    	.user_gpio_in(user_io_in[(`MPRJ_IO_PADS-1):2]),

    	// Pad-facing signals (Pad GPIOv2)
    	.pad_gpio_inenb(mprj_io_inp_dis[(`MPRJ_IO_PADS-1):2]),
    	.pad_gpio_ib_mode_sel(mprj_io_ib_mode_sel[(`MPRJ_IO_PADS-1):2]),
    	.pad_gpio_vtrip_sel(mprj_io_vtrip_sel[(`MPRJ_IO_PADS-1):2]),
    	.pad_gpio_slow_sel(mprj_io_slow_sel[(`MPRJ_IO_PADS-1):2]),
    	.pad_gpio_holdover(mprj_io_holdover[(`MPRJ_IO_PADS-1):2]),
    	.pad_gpio_ana_en(mprj_io_analog_en[(`MPRJ_IO_PADS-1):2]),
    	.pad_gpio_ana_sel(mprj_io_analog_sel[(`MPRJ_IO_PADS-1):2]),
    	.pad_gpio_ana_pol(mprj_io_analog_pol[(`MPRJ_IO_PADS-1):2]),
    	.pad_gpio_dm(mprj_io_dm[(`MPRJ_IO_PADS*3-1):6]),
    	.pad_gpio_outenb(mprj_io_oeb[(`MPRJ_IO_PADS-1):2]),
    	.pad_gpio_out(mprj_io_out[(`MPRJ_IO_PADS-1):2]),
    	.pad_gpio_in(mprj_io_in[(`MPRJ_IO_PADS-1):2])
    );

    sky130_fd_sc_hvl__lsbufhv2lv porb_level (
	`ifdef LVS
		.vpwr(vdd3v3),
		.vpb(vdd3v3),
		.lvpwr(vdd1v8),
		.vnb(vss),
		.vgnd(vss),
	`endif
		.A(porb_h),
		.X(porb_l)
    );

    user_id_programming #(
	.USER_PROJECT_ID(USER_PROJECT_ID)
    ) user_id_value (
	.mask_rev(mask_rev)
    );

    // Power-on-reset circuit
    simple_por por (
		.vdd3v3(vdd3v3),
		.vss(vss),
		.porb_h(porb_h)
    );

    // XRES (chip input pin reset) reset level converter
    sky130_fd_sc_hvl__lsbufhv2lv rstb_level (
	`ifdef LVS
		.vpwr(vdd3v3),
		.vpb(vdd3v3),
		.lvpwr(vdd1v8),
		.vnb(vss),
		.vgnd(vss),
	`endif
		.A(rstb_h),
		.X(rstb_l)
    );

endmodule
