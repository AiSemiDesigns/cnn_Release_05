// Code your design here
`include "idu_fifo.sv"
`include "control_unit.sv"
module idu(
    clk,
    rst,
    ifu2idu_fifo_empty,
    ifu2idu_rd_data,
    ifu2idu_rd_data_vld,
    idu2ifu_rd_rqst,
    idu2dfu_load_fifo_empty,
    idu2dfu_load_instr,
    idu2dfu_load_instr_vld,
    dfu2idu_load_done,
    idu2dfu_compute_fifo_empty,
    idu2dfu_compute_instr,
    idu2dfu_compute_instr_vld,
    dfu2idu_compute_done,
    idu2dfu_store_fifo_empty,
    idu2dfu_store_instr,
    idu2dfu_store_instr_vld,
    dfu2idu_store_done,
   // dfu_lsc_done,
  dfu2idu_load_instr_req,
  dfu2idu_compute_instr_req,
  dfu2idu_store_instr_req
  
  
);
 
  parameter INSTR_WIDTH=256,FIFO_IFU_WIDTH=64;
  wire [INSTR_WIDTH-1:0]data_w1,data_w2,data_w3;
  wire full_w1,full_w2,full_w3;
  wire en_w1,en_w2,en_w3;
  wire start_load,start_compute,start_store;//newly added
  
//ifu to idu---------------------------------------------
input clk;
input rst;  
input ifu2idu_fifo_empty ;
output idu2ifu_rd_rqst ;
  input [FIFO_IFU_WIDTH-1:0] ifu2idu_rd_data ;
input ifu2idu_rd_data_vld ;
  
//idu load to dfu ------------------------------------------
output idu2dfu_load_fifo_empty ;
input dfu2idu_load_instr_req ;
  output [INSTR_WIDTH-1:0] idu2dfu_load_instr ;
output idu2dfu_load_instr_vld ;
input dfu2idu_load_done ;
  
//idu compute to dfu ------------------------------------------

output idu2dfu_compute_fifo_empty ;
input dfu2idu_compute_instr_req ;
  output [INSTR_WIDTH-1:0] idu2dfu_compute_instr ;
output idu2dfu_compute_instr_vld ;
input dfu2idu_compute_done ;

//idu store to dfu ------------------------------------------

output idu2dfu_store_fifo_empty ;
input dfu2idu_store_instr_req ;
  output [INSTR_WIDTH-1:0] idu2dfu_store_instr ;
output idu2dfu_store_instr_vld ;
input dfu2idu_store_done ;
  
  input dfu_lsc_done;
  
    idu_fifo FIFO_LOAD(.clk(clk),
                 .rst(rst),
                 .wr_en(en_w1),
                 .rd_en(dfu2idu_load_instr_req),
                 .full(full_w1),
                // .empty(),
                 .data_in(data_w1),
                 .valid(idu2dfu_load_instr_vld),
                 .data_out(idu2dfu_load_instr));
    idu_fifo FIFO_COMP(.clk(clk),
                 .rst(rst),
                 .wr_en(en_w2),
                 .rd_en(dfu2idu_compute_instr_req),
                 .full(full_w2),
                // .empty(),
                 .data_in(data_w2),
                 .valid(idu2dfu_compute_instr_vld),
                 .data_out(idu2dfu_compute_instr));
    idu_fifo FIFO_STORE(.clk(clk),
                 .rst(rst),
                 .wr_en(en_w3),
                 .rd_en(dfu2idu_store_instr_req),
                 .full(full_w3),
                // .empty(),
                 .data_in(data_w3),
                 .valid(idu2dfu_store_instr_vld),
                 .data_out(idu2dfu_store_instr));
  
    control_unit CU(.clk(clk),
                  .rst(rst),
                  .ifu2idu_fifo_empty(ifu2idu_fifo_empty),
                  .ifu2idu_rd_data(ifu2idu_rd_data),
                  .ifu2idu_rd_data_vld(ifu2idu_rd_data_vld),
                  .load_full(full_w1),
                  .comp_full(full_w2),
                  .store_full(full_w3),
                  .idu2ifu_rd_rqst(idu2ifu_rd_rqst),
                  .load_wr_en(en_w1),
                  .comp_wr_en(en_w2),
                  .store_wr_en(en_w3),
                  .load_data(data_w1),
                  .comp_data(data_w2),
                  .store_data(data_w3),
                  .dfu2idu_load_done(dfu2idu_load_done),
                  .dfu2idu_compute_done(dfu2idu_compute_done),
                  .dfu2idu_store_done(dfu2idu_store_done),
                  //.dfu_lsc_done(dfu_lsc_done),
                  .start_load(start_load),
                  .start_compute(start_compute),
                  .start_store(start_store)
                    );
  assign idu2dfu_load_fifo_empty=start_load;
  assign idu2dfu_compute_fifo_empty=start_compute;
  assign idu2dfu_store_fifo_empty=start_store;
endmodule
