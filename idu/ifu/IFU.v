// Code your design here
//`include "parameter.sv"
`include "ifu_fifo.sv"
`include "ifu_fsm.sv"

module IFU(clk,
		   rstn,
           ar2ifu_data_in,
           ar2ifu_data_in_valid,
           ar2ifu_start_wl,
           ar2ifu_ack,
           ifu2ar_addr,
           ifu2ar_addr_valid,
           ifu2ar_wr_rqst,
           ifu2ar_rd_rqst,
           ifu2ar_interrupt,
           ifu2ar_maskable_interrupt,
           ifu2ar_data_out,
           ifu2ar_data_out_valid,
		   ar2ifu_wr_avalid,
		   ar2ifu_wr_adata,
//            ar2ifu_aaddr,
//            ar2ifu_aaddr_valid,
		   ar2ifu_wr_adone,
           ifu2ar_grant_rqst,
           ar2ifu_grant,//newly added
		   idu2ifu_rd_rqst,
		   ifu2idu_fifo_empty,
		   ifu2idu_rdata,
		   ifu2idu_rdata_valid
		   );
  
  input clk,rstn;
  
  input [DATA_WIDTH-1:0]ar2ifu_data_in;
  input ar2ifu_data_in_valid;
  input ar2ifu_start_wl;
  input ar2ifu_ack;
  output  ifu2ar_rd_rqst;
  output  ifu2ar_wr_rqst;
  output  [DATA_WIDTH-1:0]ifu2ar_data_out;
  output  ifu2ar_data_out_valid;
  output  [ADDR_WIDTH-1:0] ifu2ar_addr;
  output  ifu2ar_addr_valid;
  
  
  /////////////////////// from axi via arbiter //////////////////
  
  input ar2ifu_wr_avalid;
  input [FIFO_WIDTH-1:0]ar2ifu_wr_adata;
//   input [ADDR_WIDTH-1:0] ar2ifu_aaddr;
//   input ar2ifu_aaddr_valid;
  input ar2ifu_wr_adone;
  output  ifu2ar_grant_rqst;
  input ar2ifu_grant;//newly added
  
  /////////////////////////// idu ////////////////////
  
  input idu2ifu_rd_rqst;
  output  ifu2idu_fifo_empty;
  output  [FIFO_WIDTH-1:0] ifu2idu_rdata;
  output ifu2idu_rdata_valid;
  
  //////////////////////////// interrupt ////////////////
  
  output  ifu2ar_interrupt;
  output reg ifu2ar_maskable_interrupt;
  
  wire fifo_wr_en;
  wire fifo_rd_en;
  wire [FIFO_WIDTH-1:0] fifo_wr_data;
  wire fifo_full;
  wire fifo_empty;
 // wire fifo_overflow;
 // wire fifo_underflow;
  wire threshold; 
  
  ifu_fifo f1(.clk(clk),
          .rstn(rstn),
          .fifo_wr_en(fifo_wr_en),
          .fifo_rd_en(fifo_rd_en),
		  .fifo_wr_data(fifo_wr_data),
//           .fifo_addr(ar2ifu_aaddr),
//           .fifo_addr_valid(ar2ifu_aaddr_valid),
          .fifo_rd_valid(ifu2idu_rdata_valid),
          .fifo_rd_data(ifu2idu_rdata),
          .fifo_empty(fifo_empty),
          .fifo_full(fifo_full), 
       //   .fifo_overflow(fifo_overflow),
       //   .fifo_underflow(fifo_underflow),
          .threshold(threshold)
           );
  
  ifu_fsm fsm1(.clk(clk),
               .rstn(rstn),
                .ar2ifu_data_in(ar2ifu_data_in),
                .ar2ifu_data_in_valid(ar2ifu_data_in_valid),
                .ar2ifu_start_wl(ar2ifu_start_wl),
                .ar2ifu_ack(ar2ifu_ack),
                .ifu2ar_addr(ifu2ar_addr),
                .ifu2ar_addr_valid(ifu2ar_addr_valid),
                .ifu2ar_wr_rqst(ifu2ar_wr_rqst),
                .ifu2ar_rd_rqst(ifu2ar_rd_rqst),
                .ifu2ar_interrupt(ifu2ar_interrupt),
                .ifu2ar_maskable_interrupt(ifu2ar_maskable_interrupt),
                .ifu2ar_data_out(ifu2ar_data_out),
                .ifu2ar_data_out_valid(ifu2ar_data_out_valid),
                .ar2ifu_wr_adata(ar2ifu_wr_adata),
                .ar2ifu_wr_avalid(ar2ifu_wr_avalid),
                .ar2ifu_wr_adone(ar2ifu_wr_adone),
                .ifu2ar_grant_rqst(ifu2ar_grant_rqst),
                .ar2ifu_grant(ar2ifu_grant),
                .idu2ifu_rd_rqst(idu2ifu_rd_rqst),
                .fifo_wr_data(fifo_wr_data),
                .fifo_full(fifo_full),
                .fifo_empty(fifo_empty),
                .fifo_wr_en(fifo_wr_en),
                .fifo_rd_en(fifo_rd_en),
                .threshold(threshold)
            );
  assign ifu2idu_fifo_empty=fifo_empty;
endmodule
