// This routine synchronizes the 

module caravel_clocking(
`ifdef LVS
    input vdd1v8,
    input vss,
`endif
    input resetb, 	// Master (negative sense) reset
    input ext_clk_sel,	// 0=use PLL clock, 1=use external (pad) clock
    input ext_clk,	// External pad (slow) clock
    input pll_clk,	// Internal PLL (fast) clock
    input [2:0] sel,	// Select clock divider value (0=thru, 1=divide-by-2, etc.)
    input ext_reset,	// Positive sense reset from housekeeping SPI.
    output core_clk,	// Output core clock
    output resetb_sync	// Output propagated and buffered reset
);

    wire pll_clk_sel;
    reg  use_pll_first;
    reg  use_pll_second;
    reg	 ext_clk_syncd_pre;
    reg	 ext_clk_syncd;

    assign pll_clk_sel = ~ext_clk_sel;

    // Note that this implementation does not guard against switching to
    // the PLL clock if the PLL clock is not present.

    always @(posedge pll_clk or negedge resetb) begin
	if (resetb == 1'b0) begin
	    use_pll_first <= 1'b0;
	    use_pll_second <= 1'b0;
	    ext_clk_syncd <= 1'b0;
	end else begin
	    use_pll_first <= pll_clk_sel;
	    use_pll_second <= use_pll_first;
	    ext_clk_syncd_pre <= ext_clk;	// Sync ext_clk to pll_clk
	    ext_clk_syncd <= ext_clk_syncd_pre;	// Do this twice (resolve metastability)
	end
    end

    // Apply PLL clock divider

    clock_div #(
	.SIZE(3)
    ) divider (
	.in(pll_clk),
	.out(pll_clk_divided),
	.N(sel),
	.resetb(resetb)
    ); 

    // Multiplex the clock output

    assign core_ext_clk = (use_pll_first) ? ext_clk_syncd : ext_clk;
    assign core_clk = (use_pll_second) ? pll_clk_divided : core_ext_clk;

    // Reset assignment.  "reset" comes from POR, while "ext_reset"
    // comes from standalone SPI (and is normally zero unless
    // activated from the SPI).

    // Staged-delay reset
    reg [2:0] reset_delay;

    always @(posedge core_clk or negedge resetb) begin
        if (resetb == 1'b0) begin
        reset_delay <= 3'b111;
        end else begin
        reset_delay <= {1'b0, reset_delay[2:1]};
        end
    end

    assign resetb_sync = ~(reset_delay[0] | ext_reset);

endmodule
