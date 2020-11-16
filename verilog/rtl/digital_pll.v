`default_nettype none
// Digital PLL (ring oscillator + controller)
// Technically this is a frequency locked loop, not a phase locked loop.

`include "digital_pll_controller.v"
`include "ring_osc2x13.v"

module digital_pll(
`ifdef USE_POWER_PINS
    vdd,
    vss,
`endif
    resetb, enable, osc, clockp, div, dco, ext_trim);

`ifdef USE_POWER_PINS
    input vdd;
    input vss;
`endif

    input	 resetb;	// Sense negative reset
    input	 enable;	// Enable PLL
    input	 osc;		// Input oscillator to match
    input [4:0]	 div;		// PLL feedback division ratio
    input 	 dco;		// Run in DCO mode
    input [25:0] ext_trim;	// External trim for DCO mode

    output [1:0] clockp;	// Two 90 degree clock phases

    wire [25:0]  itrim;		// Internally generated trim bits
    wire [25:0]  otrim;		// Trim bits applied to the ring oscillator
    wire	 creset;	// Controller reset
    wire	 ireset;	// Internal reset (external reset OR disable)

    assign ireset = ~resetb | ~enable;

    // In DCO mode: Hold controller in reset and apply external trim value

    assign itrim = (dco == 1'b0) ? otrim : ext_trim;
    assign creset = (dco == 1'b0) ? ireset : 1'b1;

    ring_osc2x13 ringosc (
        .reset(ireset),
        .trim(itrim),
        .clockp(clockp)
    );

    digital_pll_controller pll_control (
        .reset(creset),
        .clock(clockp[0]),
        .osc(osc),
        .div(div),
        .trim(otrim)
    );

endmodule
