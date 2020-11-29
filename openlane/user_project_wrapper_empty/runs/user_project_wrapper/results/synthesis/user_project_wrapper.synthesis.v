/* Generated by Yosys 0.9+3621 (git sha1 84e9fa7, gcc 8.3.1 -fPIC -Os) */

module user_project_wrapper(wb_clk_i, wb_rst_i, wbs_stb_i, wbs_cyc_i, wbs_we_i, wbs_sel_i, wbs_dat_i, wbs_adr_i, wbs_ack_o, wbs_dat_o, la_data_in, la_data_out, la_oen, io_in, io_out, io_oeb, analog_io, user_clock2);
  inout [30:0] analog_io;
  input [37:0] io_in;
  output [37:0] io_oeb;
  output [37:0] io_out;
  input [127:0] la_data_in;
  output [127:0] la_data_out;
  input [127:0] la_oen;
  input user_clock2;
  wire vccd1;
  wire vccd2;
  wire vdda1;
  wire vdda2;
  wire vssa1;
  wire vssa2;
  wire vssd1;
  wire vssd2;
  input wb_clk_i;
  input wb_rst_i;
  output wbs_ack_o;
  input [31:0] wbs_adr_i;
  input wbs_cyc_i;
  input [31:0] wbs_dat_i;
  output [31:0] wbs_dat_o;
  input [3:0] wbs_sel_i;
  input wbs_stb_i;
  input wbs_we_i;
  user_proj_example mprj (
    .io_in(io_in),
    .io_oeb(io_oeb),
    .io_out(io_out),
    .la_data_in(la_data_in),
    .la_data_out(la_data_out),
    .la_oen(la_oen),
    .vccd1(vccd1),
    .vccd2(vccd2),
    .vdda1(vdda1),
    .vdda2(vdda2),
    .vssa1(vssa1),
    .vssa2(vssa2),
    .vssd1(vssd1),
    .vssd2(vssd2),
    .wb_clk_i(wb_clk_i),
    .wb_rst_i(wb_rst_i),
    .wbs_ack_o(wbs_ack_o),
    .wbs_adr_i(wbs_adr_i),
    .wbs_cyc_i(wbs_cyc_i),
    .wbs_dat_i(wbs_dat_i),
    .wbs_dat_o(wbs_dat_o),
    .wbs_sel_i(wbs_sel_i),
    .wbs_stb_i(wbs_stb_i),
    .wbs_we_i(wbs_we_i)
  );
endmodule
