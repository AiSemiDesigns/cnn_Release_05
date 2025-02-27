//`include "parameter.sv"
`include "dfu_ip_top.v"
`include "dfu_op_top.v"


module DFU_TOP(
    input wire                    clk,
    input wire                    rst,
    input wire                    idu2dfu_load_fifo_empty,
    input wire [INSTR_WIDTH-1:0]  idu2dfu_load_instr,
    input wire                    idu2dfu_load_instr_vld,
    input wire                    ar2dfu_ack,
    input wire [AXI_DATA_WIDTH-1:0] ar2dfu_data_in,
    input wire                    ar2dfu_data_in_vld,
    input wire                    ar2dfu_ack_data_done,

    output                     dfu2idu_load_instr_req,
    output                     dfu2ar_grant_req,
    input wire                    ar2dfu_grant,
    output                     dfu2ar_wr_req,
    output  [FIFO_WIDTH-1:0]   dfu2ar_addr,
    output                     dfu2ar_addr_vld,
    output  [DATA_WIDTH-1:0]   dfu2ar_data_out,
    output                     dfu2ar_data_out_vld,
    output                     dfu2idu_load_instr_done,
    
    input wire                    idu2dfu_compute_fifo_empty,
    output                     dfu2idu_compute_instr_req,
    input wire [INSTR_WIDTH-1:0]  idu2dfu_compute_instr,
    input wire                    idu2dfu_compute_instr_vld,

    output  [Es-1:0]           dfu2sys_data_out_a[0:no_of_sram_banks-1],
    output                     dfu2sys_data_vld_a[0:no_of_sram_banks-1],
    output  [Es-1:0]           dfu2sys_data_out_b[0:no_of_sram_banks-1],
    output                     dfu2sys_data_vld_b[0:no_of_sram_banks-1],
    input wire [(Es*3)-1:0]       sys2dfu_data_out_c[0:no_of_sram_banks-1],
    input wire                    sys2dfu_data_out_c_vld[0:no_of_sram_banks-1],

    input wire [sram_addr-1:0]    ar2dfu_axi_addr,
    input wire                    ar2dfu_axi_addr_vld,
    output  [AXI_DATA_WIDTH-1:0]            dfu2ar_axi_data_out,
    output                     dfu2ar_axi_data_out_vld,
  // output                     dfu2ar_axi_rd_last,
    output                     dfu2idu_compute_done,

    input wire                    idu2dfu_store_fifo_empty,
    output                     dfu2idu_store_instr_req,
    input wire [INSTR_WIDTH-1:0]  idu2dfu_store_instr,
    input wire                    idu2dfu_store_instr_vld,

    output                     dfu2idu_store_done,
  	output  					  dfu2ar_read_interrupt,
 	output 					  dfu2ar_write_interrupt

);
  

    wire                          dfu2ip_a_sram_rd_en[0:no_of_sram_banks-1];
 	wire [sram_addr-1:0]       	  dfu2ip_a_sram_rd_addr[0:no_of_sram_banks-1];
    wire                          dfu2ip_b_sram_rd_en[0:no_of_sram_banks-1];
  	wire [sram_addr-1:0]          dfu2ip_b_sram_rd_addr[0:no_of_sram_banks-1];
    wire  [Es-1:0]           	  dfu2op_bank_a_sram_data_out[0:no_of_sram_banks-1];
    wire                     	  dfu2op_bank_a_sram_data_out_vld[0:no_of_sram_banks-1];
    wire  [Es-1:0]           	  dfu2op_bank_b_sram_data_out[0:no_of_sram_banks-1];
    wire                     	  dfu2op_bank_b_sram_data_out_vld[0:no_of_sram_banks-1];
    wire 						  grant_req1;
    wire						  	  wr_req1;
  	wire [FIFO_WIDTH-1:0]		  addr1;
    wire 						  addr_vld1;
  	wire [DATA_WIDTH-1:0]		  data_out1;
  	wire						  	  data_out_vld1;
 //    						  grant_req2;
    wire						  	  wr_req2;
  	wire [FIFO_WIDTH-1:0]		  addr2;
    wire 						  addr_vld2;
  	wire [DATA_WIDTH-1:0]		  data_out2;
  	wire						  	  data_out_vld2;
  
    dfu_ip_top DUT_ip (
        .clk                     (clk),
        .rst                     (rst),
        .idu2dfu_load_fifo_empty (idu2dfu_load_fifo_empty),
        .dfu2idu_load_instr_req  (dfu2idu_load_instr_req),
        .idu2dfu_load_instr      (idu2dfu_load_instr),
        .idu2dfu_load_instr_vld  (idu2dfu_load_instr_vld),
        .dfu2ar_grant_req        (grant_req1),
        .ar2dfu_grant            (ar2dfu_grant),
        .dfu2ar_wr_req           (wr_req1),
        .dfu2ar_addr             (addr1),
        .dfu2ar_addr_vld         (addr_vld1),
        .dfu2ar_data_out         (data_out1),
        .dfu2ar_data_out_vld     (data_out_vld1),
        .ar2dfu_ack              (ar2dfu_ack),
        .ar2dfu_data_in          (ar2dfu_data_in),
        .ar2dfu_data_in_vld      (ar2dfu_data_in_vld),
        .ar2dfu_ack_data_done    (ar2dfu_ack_data_done),
        .dfu2idu_load_instr_done (dfu2idu_load_instr_done),
        .dfu2ip_a_sram_rd_en     (dfu2ip_a_sram_rd_en),
        .dfu2ip_a_sram_rd_addr   (dfu2ip_a_sram_rd_addr),
        .dfu2ip_b_sram_rd_en     (dfu2ip_b_sram_rd_en),
        .dfu2ip_b_sram_rd_addr   (dfu2ip_b_sram_rd_addr),
        .dfu2op_bank_a_sram_data_out  (dfu2op_bank_a_sram_data_out),
        .dfu2op_bank_a_sram_data_out_vld (dfu2op_bank_a_sram_data_out_vld),
        .dfu2op_bank_b_sram_data_out  (dfu2op_bank_b_sram_data_out),
        .dfu2op_bank_b_sram_data_out_vld (dfu2op_bank_b_sram_data_out_vld),
        .dfu2ar_write_interrupt          (dfu2ar_write_interrupt)
    );

    dfu_op_top DUT_op (
        .clk                     (clk),
        .rst                     (rst),
        .idu2dfu_compute_fifo_empty (idu2dfu_compute_fifo_empty),
        .dfu2idu_compute_instr_req  (dfu2idu_compute_instr_req),
        .idu2dfu_compute_instr      (idu2dfu_compute_instr),
        .idu2dfu_compute_instr_vld  (idu2dfu_compute_instr_vld),
        .dfu2ip_a_sram_rd_addr   (dfu2ip_a_sram_rd_addr),
        .dfu2ip_a_sram_rd_en     (dfu2ip_a_sram_rd_en),
        .dfu2ip_b_sram_rd_en     (dfu2ip_b_sram_rd_en),
        .dfu2ip_b_sram_rd_addr   (dfu2ip_b_sram_rd_addr),
        .dfu2op_a_sram_data_out  (dfu2op_bank_a_sram_data_out),
        .dfu2op_b_sram_data_out  (dfu2op_bank_b_sram_data_out),
        .dfu2op_a_sram_data_out_vld (dfu2op_bank_a_sram_data_out_vld),
        .dfu2op_b_sram_data_out_vld (dfu2op_bank_b_sram_data_out_vld),
        .dfu2sys_data_out_a      (dfu2sys_data_out_a),
        .dfu2sys_data_vld_a      (dfu2sys_data_vld_a),
        .dfu2sys_data_out_b      (dfu2sys_data_out_b),
        .dfu2sys_data_vld_b      (dfu2sys_data_vld_b),
        .sys2dfu_data_out_c      (sys2dfu_data_out_c),
        .sys2dfu_data_out_c_vld  (sys2dfu_data_out_c_vld),
        .ar2dfu_axi_addr         (ar2dfu_axi_addr),
        .ar2dfu_axi_addr_vld     (ar2dfu_axi_addr_vld),
        .dfu2ar_axi_data_out     (dfu2ar_axi_data_out),
        .dfu2ar_axi_data_out_vld (dfu2ar_axi_data_out_vld),
        .dfu2ar_axi_rd_last      (dfu2ar_axi_rd_last),
        .dfu2idu_compute_done    (dfu2idu_compute_done),
        .idu2dfu_store_fifo_empty (idu2dfu_store_fifo_empty),
        .dfu2idu_store_instr_req (dfu2idu_store_instr_req),
        .idu2dfu_store_instr     (idu2dfu_store_instr),
        .idu2dfu_store_instr_vld (idu2dfu_store_instr_vld),
        .dfu2ar_grant_req        (grant_req2),
        .ar2dfu_grant            (ar2dfu_grant),
        .dfu2ar_rd_req           (wr_req2),
        .dfu2ar_rd_addr          (addr2),
        .dfu2ar_rd_addr_vld      (addr_vld2),
        .dfu2ar_rd_data_out      (data_out2),
        .dfu2ar_rd_data_out_vld  (data_out_vld2),
        .ar2dfu_ack              (ar2dfu_ack),
        .dfu2idu_store_done      (dfu2idu_store_done),
        .dfu2ar_read_interrupt   (dfu2ar_read_interrupt)
    );
  
  assign dfu2ar_grant_req   =(grant_req1||grant_req2)?1:0;
  assign dfu2ar_wr_req      =(grant_req1)?wr_req1:((grant_req2)?wr_req2:0);
  assign dfu2ar_addr        =(grant_req1)?addr1:((grant_req2)?addr2:0);   
  assign dfu2ar_addr_vld    =(grant_req1)?addr_vld1:((grant_req2)?addr_vld2:0);   
  assign dfu2ar_data_out    =(grant_req1)?data_out1:((grant_req2)?data_out2:0);    
  assign dfu2ar_data_out_vld=(grant_req1)?data_out_vld1:((grant_req2)?data_out_vld2:0);   

endmodule

