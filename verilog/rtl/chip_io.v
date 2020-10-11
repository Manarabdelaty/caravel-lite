module chip_io(
	// Package Pins
	inout  vddio,		// Common padframe/ESD supply
	inout  vssio,		// Common padframe/ESD ground
	inout  vccd,		// Common 1.8V supply
	inout  vssd,		// Common digital ground
	inout  vdda,		// Management analog 3.3V supply
	inout  vssa,		// Management analog ground
	inout  vdda1,		// User area 1 3.3V supply
	inout  vdda2,		// User area 2 3.3V supply
	inout  vssa1,		// User area 1 analog ground
	inout  vssa2,		// User area 2 analog ground
	inout  vccd1,		// User area 1 1.8V supply
	inout  vccd2,		// User area 2 1.8V supply
	inout  vssd1,		// User area 1 digital ground
	inout  vssd2,		// User area 2 digital ground

	inout  gpio,
	input  clock,
	input  resetb,
	output flash_csb,
	output flash_clk,
	inout  flash_io0,
	inout  flash_io1,
	// Chip Core Interface
	input  porb_h,
	output resetb_core_h,
	output clock_core,
	input  gpio_out_core,
    	output gpio_in_core,
    	input  gpio_mode0_core,
    	input  gpio_mode1_core,
    	input  gpio_outenb_core,
    	input  gpio_inenb_core,
	input  flash_csb_core,
	input  flash_clk_core,
	input  flash_csb_oeb_core,
	input  flash_clk_oeb_core,
	input  flash_io0_oeb_core,
	input  flash_io1_oeb_core,
	input  flash_csb_ieb_core,
	input  flash_clk_ieb_core,
	input  flash_io0_ieb_core,
	input  flash_io1_ieb_core,
	input  flash_io0_do_core,
	input  flash_io1_do_core,
	output flash_io0_di_core,
	output flash_io1_di_core,
	// porbh, returned to the I/O level shifted down and inverted
	input  por,
	// Mega-project IOs
	inout [`MPRJ_IO_PADS-1:0] mprj_io,
	input [`MPRJ_IO_PADS-1:0] mprj_io_out,
	input [`MPRJ_IO_PADS-1:0] mprj_io_oeb,
    	input [`MPRJ_IO_PADS-1:0] mprj_io_hldh_n,
	input [`MPRJ_IO_PADS-1:0] mprj_io_enh,
    	input [`MPRJ_IO_PADS-1:0] mprj_io_inp_dis,
    	input [`MPRJ_IO_PADS-1:0] mprj_io_ib_mode_sel,
    	input [`MPRJ_IO_PADS-1:0] mprj_io_vtrip_sel,
    	input [`MPRJ_IO_PADS-1:0] mprj_io_slow_sel,
    	input [`MPRJ_IO_PADS-1:0] mprj_io_holdover,
    	input [`MPRJ_IO_PADS-1:0] mprj_io_analog_en,
    	input [`MPRJ_IO_PADS-1:0] mprj_io_analog_sel,
    	input [`MPRJ_IO_PADS-1:0] mprj_io_analog_pol,
    	input [`MPRJ_IO_PADS*3-1:0] mprj_io_dm,
	output [`MPRJ_IO_PADS-1:0] mprj_io_in
);

	wire analog_a, analog_b;
	wire vddio_q, vssio_q;

	// Instantiate power and ground pads for management domain
	// 12 pads:  vddio, vssio, vdda, vssa, vccd, vssd
	// One each HV and LV clamp.

	// HV clamps connect between one HV power rail and one ground
	// LV clamps have two clamps connecting between any two LV power
	// rails and grounds, and one back-to-back diode which connects
	// between the first LV clamp ground and any other ground.

    	s8iom0_vddio_hvc_pad mgmt_vddio_hvclamp_pad [1:0] (
		`MGMT_ABUTMENT_PINS
		`HVCLAMP_PINS(vddio, vssio)
    	);

    	s8iom0_vdda_hvc_pad mgmt_vdda_hvclamp_pad (
		`MGMT_ABUTMENT_PINS
		`HVCLAMP_PINS(vdda, vssa)
    	);

    	s8iom0_vccd_lvc_pad mgmt_vccd_lvclamp_pad (
		`MGMT_ABUTMENT_PINS
		`LVCLAMP_PINS(vccd, vssio, vccd, vssd, vssa)
    	);

    	s8iom0_vssio_hvc_pad mgmt_vssio_hvclamp_pad [1:0] (
		`MGMT_ABUTMENT_PINS
		`HVCLAMP_PINS(vddio, vssio)
    	);

    	s8iom0_vssa_hvc_pad mgmt_vssa_hvclamp_pad (
		`MGMT_ABUTMENT_PINS
		`HVCLAMP_PINS(vdda, vssa)
    	);

    	s8iom0_vssd_lvc_pad mgmt_vssd_lvclmap_pad (
		`MGMT_ABUTMENT_PINS
		`LVCLAMP_PINS(vccd, vssio, vccd, vssd, vssa)
    	);

	// Instantiate power and ground pads for user 1 domain
	// 8 pads:  vdda, vssa, vccd, vssd;  One each HV and LV clamp.

    	s8iom0_vdda_hvc_pad user1_vdda_hvclamp_pad [1:0] (
		`USER1_ABUTMENT_PINS
		`HVCLAMP_PINS(vdda1, vssa1)
    	);

    	s8iom0_vccd_lvc_pad user1_vccd_lvclamp_pad (
		`USER1_ABUTMENT_PINS
		`LVCLAMP_PINS(vccd1, vssd1, vccd1, vssd, vssio)
    	);

    	s8iom0_vssa_hvc_pad user1_vssa_hvclamp_pad [1:0] (
		`USER1_ABUTMENT_PINS
		`HVCLAMP_PINS(vdda1, vssa1)
    	);

    	s8iom0_vssd_lvc_pad user1_vssd_lvclmap_pad (
		`USER1_ABUTMENT_PINS
		`LVCLAMP_PINS(vccd1, vssd1, vccd1, vssd, vssio)
    	);

	// Instantiate power and ground pads for user 2 domain
	// 8 pads:  vdda, vssa, vccd, vssd;  One each HV and LV clamp.

    	s8iom0_vdda_hvc_pad user2_vdda_hvclamp_pad (
		`USER2_ABUTMENT_PINS
		`HVCLAMP_PINS(vdda2, vssa2)
    	);

    	s8iom0_vccd_lvc_pad user2_vccd_lvclamp_pad (
		`USER2_ABUTMENT_PINS
		`LVCLAMP_PINS(vccd2, vssd2, vccd2, vssd, vssio)
    	);

    	s8iom0_vssa_hvc_pad user2_vssa_hvclamp_pad (
		`USER2_ABUTMENT_PINS
		`HVCLAMP_PINS(vdda2, vssa2)
    	);

    	s8iom0_vssd_lvc_pad user2_vssd_lvclmap_pad (
		`USER2_ABUTMENT_PINS
		`LVCLAMP_PINS(vccd2, vssd2, vccd2, vssd, vssio)
    	);

	wire [2:0] dm_all =
    		{gpio_mode1_core, gpio_mode1_core, gpio_mode0_core};
	wire[2:0] flash_io0_mode = 
		{flash_io0_ieb_core, flash_io0_ieb_core, flash_io0_oeb_core};
	wire[2:0] flash_io1_mode = 
		{flash_io1_ieb_core, flash_io1_ieb_core, flash_io1_oeb_core};

	// Management clock input pad
	`INPUT_PAD(clock, clock_core); 	    

    	// Management GPIO pad
	`INOUT_PAD(
		gpio, gpio_in_core, gpio_out_core,
		gpio_inenb_core, gpio_outenb_core, dm_all);
	
	// Management Flash SPI pads
	`INOUT_PAD(
		flash_io0, flash_io0_di_core, flash_io0_do_core,
		flash_io0_ieb_core, flash_io0_oeb_core, flash_io0_mode);
	`INOUT_PAD(
		flash_io1, flash_io1_di_core, flash_io1_do_core,
		flash_io1_ieb_core, flash_io1_oeb_core, flash_io1_mode);

	`OUTPUT_PAD(flash_csb, flash_csb_core, flash_csb_ieb_core, flash_csb_oeb_core);  
	`OUTPUT_PAD(flash_clk, flash_clk_core, flash_clk_ieb_core, flash_clk_oeb_core);

	// NOTE:  The analog_out pad from the raven chip has been replaced by
    	// the digital reset input resetb on caravel due to the lack of an on-board
    	// power-on-reset circuit.  The XRES pad is used for providing a glitch-
    	// free reset.

	s8iom0s8_top_xres4v2 resetb_pad (
		`MGMT_ABUTMENT_PINS 
		`ifndef	TOP_ROUTING
		    .pad(resetb),
		`endif
		.tie_weak_hi_h(xresloop),   // Loop-back connection to pad through pad_a_esd_h
		.tie_hi_esd(),
		.tie_lo_esd(),
		.pad_a_esd_h(xresloop),
		.xres_h_n(resetb_core_h),
		.disable_pullup_h(vssio),    // 0 = enable pull-up on reset pad
		.enable_h(porb_h),	    // Power-on-reset
		.en_vddio_sig_h(vssio),	    // No idea.
		.inp_sel_h(vssio),	    // 1 = use filt_in_h else filter the pad input
		.filt_in_h(vssio),	    // Alternate input for glitch filter
		.pullup_h(vssio),	    // Pullup connection for alternate filter input
		.enable_vddio(vccd)
    	);

	// Corner cells (These are overlay cells;  it is not clear what is normally
    	// supposed to go under them.)  

	`ifndef TOP_ROUTING   
	    s8iom0_corner_pad mgmt_corner [1:0] (
		.vssio(vssio),
		.vddio(vddio),
		.vddio_q(vddio_q),
		.vssio_q(vssio_q),
		.amuxbus_a(analog_a),
		.amuxbus_b(analog_b),
		.vssd(vssio),
		.vssa(vssio),
		.vswitch(vddio),
		.vdda(vdda),
		.vccd(vccd),
		.vcchib(vccd)
    	    );
	    s8iom0_corner_pad user1_corner (
		.vssio(vssio),
		.vddio(vddio),
		.vddio_q(vddio_q),
		.vssio_q(vssio_q),
		.amuxbus_a(analog_a),
		.amuxbus_b(analog_b),
		.vssd(vssd1),
		.vssa(vssa1),
		.vswitch(vddio),
		.vdda(vdda1),
		.vccd(vccd1),
		.vcchib(vccd)
    	    );
	    s8iom0_corner_pad user2_corner (
		.vssio(vssio),
		.vddio(vddio),
		.vddio_q(vddio_q),
		.vssio_q(vssio_q),
		.amuxbus_a(analog_a),
		.amuxbus_b(analog_b),
		.vssd(vssd2),
		.vssa(vssa2),
		.vswitch(vddio),
		.vdda(vdda2),
		.vccd(vccd2),
		.vcchib(vccd)
    	    );
	`endif

	mprj_io mprj_pads(
		.vddio(vddio),
		.vssio(vssio),
		.vccd(vccd),
		.vssd(vssd),
		.vdda1(vdda1),
		.vdda2(vdda2),
		.vssa1(vssa1),
		.vssa2(vssa2),
		.vccd1(vccd1),
		.vccd2(vccd2),
		.vssd1(vssd1),
		.vssd2(vssd2),
		.vddio_q(vddio_q),
		.vssio_q(vssio_q),
		.analog_a(analog_a),
		.analog_b(analog_b),
		.porb_h(porb_h),
		.por(por),
		.io(mprj_io),
		.io_out(mprj_io_out),
		.oeb(mprj_io_oeb),
		.hldh_n(mprj_io_hldh_n),
		.enh(mprj_io_enh),
		.inp_dis(mprj_io_inp_dis),
		.ib_mode_sel(mprj_io_ib_mode_sel),
		.vtrip_sel(mprj_io_vtrip_sel),
		.holdover(mprj_io_holdover),
		.slow_sel(mprj_io_slow_sel),
		.analog_en(mprj_io_analog_en),
		.analog_sel(mprj_io_analog_sel),
		.analog_pol(mprj_io_analog_pol),
		.dm(mprj_io_dm),
		.io_in(mprj_io_in)
	);

endmodule
