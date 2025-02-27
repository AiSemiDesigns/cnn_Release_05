`include "mux_fsm.v"
`include "dfu_output.v"
`include "sram_top.v"
`include "store_inst.v"

module dfu_op_top(
  input                       clk,
  input                       rst,
  input                       idu2dfu_compute_fifo_empty,
  output                   dfu2idu_compute_instr_req,
  input [INSTR_WIDTH-1:0]     idu2dfu_compute_instr,
  input                       idu2dfu_compute_instr_vld,

  output  [sram_addr-1:0]  dfu2ip_a_sram_rd_addr[0:no_of_sram_banks-1],
  output                   dfu2ip_a_sram_rd_en[0:no_of_sram_banks-1],
  output                   dfu2ip_b_sram_rd_en[0:no_of_sram_banks-1],
  output  [sram_addr-1:0]  dfu2ip_b_sram_rd_addr[0:no_of_sram_banks-1],

  input [Es-1:0]              dfu2op_a_sram_data_out[0:no_of_sram_banks-1],
  input [Es-1:0]              dfu2op_b_sram_data_out[0:no_of_sram_banks-1],
  input                       dfu2op_a_sram_data_out_vld[0:no_of_sram_banks-1],
  input                       dfu2op_b_sram_data_out_vld[0:no_of_sram_banks-1],

  output  [Es-1:0]         dfu2sys_data_out_a[0:no_of_sram_banks-1],
  output                   dfu2sys_data_vld_a[0:no_of_sram_banks-1],
  output  [Es-1:0]         dfu2sys_data_out_b[0:no_of_sram_banks-1],
  output                   dfu2sys_data_vld_b[0:no_of_sram_banks-1],

  input [(Es*3)-1:0]          sys2dfu_data_out_c[0:no_of_sram_banks-1],
  input                       sys2dfu_data_out_c_vld[0:no_of_sram_banks-1],

  input [sram_addr-1:0]       ar2dfu_axi_addr,
  input                       ar2dfu_axi_addr_vld,
  output  [AXI_DATA_WIDTH-1:0]          dfu2ar_axi_data_out,
  output                   dfu2ar_axi_data_out_vld,
  output                   dfu2ar_axi_rd_last,
  output                   dfu2idu_compute_done,

  input                       idu2dfu_store_fifo_empty,
  output                   dfu2idu_store_instr_req,
  input [INSTR_WIDTH-1:0]     idu2dfu_store_instr,
  input                       idu2dfu_store_instr_vld,
  output                   dfu2ar_grant_req,
  input                       ar2dfu_grant,
  output                   dfu2ar_rd_req,
  output  [FIFO_WIDTH-1:0]  dfu2ar_rd_addr,
  output                   dfu2ar_rd_addr_vld,
  output  [FIFO_WIDTH-1:0]  dfu2ar_rd_data_out,
  output                   dfu2ar_rd_data_out_vld,
  input                       ar2dfu_ack,

  output                   dfu2idu_store_done,
  output  					dfu2ar_read_interrupt
);



  //  [sel_sram_bank_bits-1:0] dfu2ip_a_sel_sram[0:no_of_sram_banks-1];
  //  [sel_sram_bank_bits-1:0] dfu2ip_b_sel_sram[0:no_of_sram_banks-1];
  reg ack_sram_c_rd;
  wire dfu2mux_rd_en;

  // Instantiate dfu_output module
  dfu_output DUT_ip (
    .clk(clk),
    .rst(rst),
    .idu2dfu_compute_fifo_empty(idu2dfu_compute_fifo_empty),
    .dfu2idu_compute_instr_req(dfu2idu_compute_instr_req),
    .idu2dfu_compute_instr(idu2dfu_compute_instr),
    .idu2dfu_compute_instr_vld(idu2dfu_compute_instr_vld),
    .dfu2ip_a_sram_rd_addr(dfu2ip_a_sram_rd_addr),
    .dfu2ip_a_sram_rd_en(dfu2ip_a_sram_rd_en),
    .dfu2ip_b_sram_rd_en(dfu2ip_b_sram_rd_en),
    .dfu2ip_b_sram_rd_addr(dfu2ip_b_sram_rd_addr),
    .dfu2mux_rd_en(dfu2mux_rd_en)
    //.dfu2ip_a_sel_sram(dfu2ip_a_sel_sram),
    //.dfu2ip_b_sel_sram(dfu2ip_b_sel_sram)
  );

  // Instantiate mux_fsm module
  mux_fsm DUT_mux (
    .clk(clk),
    .rst(rst),
    .dfu2op_a_sram_data_out(dfu2op_a_sram_data_out),
    .dfu2op_b_sram_data_out(dfu2op_b_sram_data_out),
    .dfu2op_a_sram_data_out_vld(dfu2op_a_sram_data_out_vld),
    .dfu2op_b_sram_data_out_vld(dfu2op_b_sram_data_out_vld),
    .dfu2sys_data_out_a(dfu2sys_data_out_a),
    .dfu2sys_data_vld_a(dfu2sys_data_vld_a),
    .dfu2sys_data_out_b(dfu2sys_data_out_b),
    .dfu2sys_data_vld_b(dfu2sys_data_vld_b),
    .dfu2mux_rd_en(dfu2mux_rd_en)

  );

  // Instantiate sram_top module
  sram_top DUT_sram_top (
    .clk(clk),
    .rst(rst),
    .sys2dfu_data_out_c(sys2dfu_data_out_c),
    .sys2dfu_data_out_c_vld(sys2dfu_data_out_c_vld),
    .ar2dfu_axi_addr(ar2dfu_axi_addr),
    .ar2dfu_axi_addr_vld(ar2dfu_axi_addr_vld),
    .dfu2ar_axi_data_out(dfu2ar_axi_data_out),
    .dfu2ar_axi_data_out_vld(dfu2ar_axi_data_out_vld),
    .dfu2idu_compute_done(dfu2idu_compute_done),
    .ack_sram_c_rd(ack_sram_c_rd),
    .dfu2ar_axi_rd_last(dfu2ar_axi_rd_last)
  );

  // Instantiate store_inst module
  store_inst DUT_store (
    .clk(clk),
    .rst(rst),
    .idu2dfu_store_fifo_empty(idu2dfu_store_fifo_empty),
    .dfu2idu_store_instr_req(dfu2idu_store_instr_req),
    .idu2dfu_store_instr(idu2dfu_store_instr),
    .idu2dfu_store_instr_vld(idu2dfu_store_instr_vld),
    .dfu2ar_grant_req(dfu2ar_grant_req),
    .ar2dfu_grant(ar2dfu_grant),
    .dfu2ar_rd_req(dfu2ar_rd_req),
    .dfu2ar_rd_addr(dfu2ar_rd_addr),
    .dfu2ar_rd_addr_vld(dfu2ar_rd_addr_vld),
    .dfu2ar_rd_data_out(dfu2ar_rd_data_out),
    .dfu2ar_rd_data_out_vld(dfu2ar_rd_data_out_vld),
    .ar2dfu_ack(ar2dfu_ack),
    .ack_sram_c_rd(ack_sram_c_rd),
    .dfu2idu_store_done(dfu2idu_store_done),
    .dfu2ar_read_interrupt(dfu2ar_read_interrupt)
  );
  /* always @(posedge clk) begin
    if (sys2dfu_data_out_c_vld[0]||sys2dfu_data_out_c_vld[ROW-1])
      for (integer i=0;i<ROW;i=i+1) begin
        $display($time,"| dfu_sys2dfu_data_out_c[%0d] =%0d | sys2dfu_data_out_c_vld[%0d]=%0d",i,sys2dfu_data_out_c[i],i,sys2dfu_data_out_c_vld[i]);
      end
      end
*/

endmodule

