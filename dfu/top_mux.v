`include "mux.v"

module top_mux(
  input  wire                      clk,
  input  wire                      rst,
  input  wire [Es-1:0]             dfu2op_a_sram_data_out [0:no_of_sram_banks-1] ,
  input  wire [no_of_sel_ln-1:0]   top_mux_a_sel           [0:no_of_sram_banks-1],
  output   [Es-1:0]             dfu2sys_data_out_a      [0:no_of_sram_banks-1],
  output                        dfu2sys_data_vld_a      [0:no_of_sram_banks-1],
  input  wire [Es-1:0]             dfu2op_b_sram_data_out [0:no_of_sram_banks-1] ,
//   input wire dfu2op_b_sram_data_out_vld [0:no_of_sram_banks-1],
//   input wire dfu2op_a_sram_data_out_vld [0:no_of_sram_banks-1],
  input  wire [no_of_sel_ln-1:0]   top_mux_b_sel           [0:no_of_sram_banks-1],
  output   [Es-1:0]             dfu2sys_data_out_b      [0:no_of_sram_banks-1],
  output                        dfu2sys_data_vld_b      [0:no_of_sram_banks-1],
  input ack_start_sys_a[0:no_of_sram_banks-1],
  input ack_start_sys_b[0:no_of_sram_banks-1]
);


  //........................testing purpose.......................,.....
  
//   wire  dfu2op_a_sram_data_out_vld_temp;
//   assign dfu2op_a_sram_data_out_vld_temp = dfu2op_a_sram_data_out_vld [0];

  //........................testing purpose.......................,.....


  // Generate instances for A-side multiplexers
  generate
    genvar i;
    for (i = 0; i < no_of_sram_banks; i = i + 1) begin: mux_a_gen
      mux inst_a_mux (
        .clk(clk),
        .rst(rst),
        .mux_in(dfu2op_a_sram_data_out),
       // .mux_in_vld(dfu2op_a_sram_data_out_vld[i]),
        .mux_sel(top_mux_a_sel[i]),
        .mux_out(dfu2sys_data_out_a[i]),
        .out_vld(dfu2sys_data_vld_a[i]),
        .ack_start_sys(ack_start_sys_a[i])
      );
    end
  endgenerate

  // Generate instances for B-side multiplexers
  generate
    genvar j;
    for (j = 0; j < no_of_sram_banks; j = j + 1) begin: mux_b_gen
      mux inst_b_mux (
        .clk(clk),
        .rst(rst),
        .mux_in(dfu2op_b_sram_data_out),
      //  .mux_in_vld(dfu2op_b_sram_data_out_vld[j]),
        .mux_sel(top_mux_b_sel[j]),
        .mux_out(dfu2sys_data_out_b[j]),
        .out_vld(dfu2sys_data_vld_b[j]),
        .ack_start_sys(ack_start_sys_b[j])
      );
    end
  endgenerate

endmodule

