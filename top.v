// Code your design here
`include "parameter.v"
`include "APB_TARGET.v"
`include "config_unit.v"
`include "arbitor.v"
`include "IFU.v"
`include "AXI_TARGET.v"
`include "idu.v"
`include "DFU_TOP.v"
`include "systollic_array.v"
`include "dfu_lsc_done.v"
module TOP(
  				input 							clk,
 				input 							rst,
 				input 						 P_selx,
 				input						 P_enable,
 				input						 P_write,
 				input         [PADDR_WIDTH-1:0]P_addr,
 				input         [PDATA_WIDTH-1:0]P_wdata,
 				output        [PDATA_WIDTH-1:0]P_rdata,
 				output reg    P_ready,P_slverr,
 // 				 output 		ar2ifu_int_interrupt ,//newly added--> arbitor to interface interrupt 
 				 output reg		ar_maskable_interrupt ,
 	//			 output 		ar2dfu_int_write_interrupt,//newly added --> arbitor to interface interrupt 
 	//			 output 		ar2dfu_int_read_interrupt,//newly added  --> arbitor to interface interrupt 
  output interrupt,
  				output 			cu2int_busy,
				input	[AXI_ADDR_WIDTH-1:0]			AWADDR,
				input	[AXI_LEN_WIDTH-1:0]			AWLEN,
				input	[AXI_SIZE_WIDTH-1:0]			AWSIZE,
				input	[AXI_RESP_WIDTH-1:0]			AWBURST,
				input					AWVALID,
				output					AWREADY,
				input	[AXI_DATA_WIDTH-1:0]			WDATA,
				input					WLAST,
				input					WVALID,
				output					WREADY,
				output	[AXI_RESP_WIDTH-1:0]			BRESP,
				output					BVALID,
				input					BREADY,
				input	[AXI_ADDR_WIDTH-1:0]			ARADDR,
				input	[AXI_LEN_WIDTH-1:0]			ARLEN,
				input	[AXI_SIZE_WIDTH-1:0]			ARSIZE,
				input	[AXI_RESP_WIDTH-1:0]			ARBURST,
				input					ARVALID,
				output					ARREADY,
				output	[AXI_DATA_WIDTH-1:0]			RDATA,
				output					RLAST,
				output					RVALID,
				output	[AXI_RESP_WIDTH-1:0]			RRESP,
				input					RREADY,
  input  [AXI_ID_WIDTH-1:0]        AWID,
  input  [AXI_ID_WIDTH-1:0]        WID,
  input  [AXI_ID_WIDTH-1:0]        ARID,
  output [AXI_ID_WIDTH-1:0]        BID
 // input  [AXI_STROBE_WIDTH-1:0]    WSTRB,
 // input               			   AWLOCK,
//  input  [AXI_STROBE_WIDTH-1:0]    AWCACHE,
 // input  [AXI_SIZE_WIDTH-1:0]      AWPROT,
  //input  [AXI_RESP_WIDTH-1:0]      AWQOS
  				
 );
  //-----arbitor to cu and vice varsa---//
  wire   [CU_DATA_WIDTH-1:0] ar2cu_data_out ;
	wire   ar2cu_data_out_valid ;
  wire   [ADDR_WIDTH-1:0] ar2cu_addr ;
	wire   ar2cu_addr_valid ;
	wire   ar2cu_wr_rqst ;
	wire   ar2cu_rd_rqst ;
	wire   cu2ar_start_wl ;
  wire   [CU_DATA_WIDTH-1:0] cu2ar_data_in ;
	wire   cu2ar_data_in_valid ;
	wire   cu2ar_busy ;
	wire   cu2ar_dfu_ack ;
	wire   cu2ar_ifu_ack ;

  
  //--------apb to cu and vice varsa--------//
	wire  [PDATA_WIDTH-1:0] cu2apb_data_out;
	wire apb2cu_en;
	wire [PADDR_WIDTH-1:0] apb2cu_addr  ;
	wire [PDATA_WIDTH-1:0] apb2cu_data_in;
  
   //-------Arbiter-IFU-and vice varsa------------//
  wire   [AXI_DATA_WIDTH-1:0] ar2ifu_wr_data ;
 wire   ar2ifu_wr_data_valid ;

 wire   ar2ifu_wr_done ;
 wire   ar2ifu_ack ;
 wire   ar2ifu_start_wl ;
  wire   [AXI_DATA_WIDTH-1:0] ar2ifu_data_out ;
 wire   ar2ifu_data_out_valid ;
  wire   [AXI_DATA_WIDTH-1:0] ifu2ar_data_in ;
 wire   ifu2ar_data_in_valid ;
  wire   [AXI_DATA_WIDTH-1:0] ifu2ar_addr ;
 wire   ifu2ar_addr_valid ;
 wire   ifu2ar_wr_rqst ;
 wire   ifu2ar_rd_rqst ;
 wire   ifu2ar_interrupt ;
 wire   ifu2ar_maskable_interrupt ;
 wire   ifu2ar_req;
 wire   ar2ifu_grant;  
  wire	ar2dfu_grant;//dfu

  
 //----------- arbiter to axi and vice varsa ------//
  wire[AXI_DATA_WIDTH-1:0] ar2axi_rd_data;
  wire [AXI_ADDR_WIDTH-1:0] axi2ar_wr_addr,axi2ar_rd_addr;
  wire axi2ar_wr_addr_valid,axi2ar_rd_addr_valid,axi2ar_wr_done;
  wire [AXI_DATA_WIDTH-1:0] axi2ar_wr_data;
  wire axi2ar_wr_data_valid;
  wire	ar2dfu_wr_done;
  wire	ar2dfu_ack;
  
  /////-------idu to ifu-------//
  wire ifu2idu_rdata_valid;
  reg [FIFO_IFU_WIDTH-1:0] ifu2idu_rdata;
  wire idu2ifu_rd_rqst;
  wire ifu2idu_fifo_empty;
  
  ///////DFU to arbiter&idu&sys ////
  wire	dfu2idu_load_instr_req;
  wire	dfu2ar_grant_req;
  wire	dfu2ar_wr_req;
  wire	[FIFO_WIDTH-1:0]dfu2ar_addr;
  wire	dfu2ar_addr_vld;
  wire	[DATA_WIDTH-1:0]dfu2ar_data_out;
  wire	dfu2ar_data_out_vld;
  wire	dfu2idu_load_instr_done;
  wire	dfu2idu_compute_instr_req;
  wire	[AXI_RDATA_WIDTH-1:0]dfu2ar_axi_data_out;
  wire	dfu2ar_axi_data_out_vld;
  wire ar2axi_rd_data_vld;
 // wire	dfu2ar_axi_rd_last;
  wire	dfu2idu_compute_done;
  wire	dfu2idu_store_instr_req;
  wire	dfu2idu_store_done;
  wire	dfu2ar_read_interrupt;
  wire	dfu2ar_write_interrupt;
  wire	ar2dfu_wr_data_valid;
  wire	[AXI_DATA_WIDTH-1:0]	ar2dfu_wr_data;
  wire	ar2dfu_rd_addr_valid;
  wire	[AXI_WIDTH-1:0]	ar2dfu_rd_addr;
  wire [INSTR_WIDTH-1:0]  idu2dfu_compute_instr;
  wire	idu2dfu_compute_instr_vld;
  wire	[Es-1:0]           dfu2sys_data_out_a[0:no_of_sram_banks-1];
  wire	[Es-1:0]           dfu2sys_data_out_b[0:no_of_sram_banks-1];
  wire	dfu2sys_data_vld_b[0:no_of_sram_banks-1];
  wire	 dfu2sys_data_vld_a[0:no_of_sram_banks-1];
  wire                    sys2dfu_data_out_c_vld[0:no_of_sram_banks-1];
  wire [(Es*3)-1:0]       sys2dfu_data_out_c[0:no_of_sram_banks-1];
  wire	idu2dfu_load_fifo_empty;
  wire                    idu2dfu_load_instr_vld;
  wire [INSTR_WIDTH-1:0]  idu2dfu_load_instr;
  wire	idu2dfu_compute_fifo_empty;
  wire	idu2dfu_store_fifo_empty;
  wire	[INSTR_WIDTH-1:0]	idu2dfu_store_instr;
  wire	idu2dfu_store_instr_vld;
  
  
  APB_TARGET APB_SLAVE( 	  .P_clk(clk),
                      			  .P_rstn(rst),
                      			  .P_addr(P_addr),
                      			  .P_selx(P_selx),
                      			  .P_enable(P_enable),
                      			  .P_write(P_write),
                      			  .P_wdata(P_wdata),
                      			  .P_ready(P_ready),
                      			  .P_slverr(P_slverr),
                      			  .P_rdata(P_rdata),
                      			  .wr_en(apb2cu_en),
                      			  .data_out(cu2apb_data_out), 
                      			  .addr(apb2cu_addr), 
                      			  .data_in(apb2cu_data_in)
                               );
  
  
  
 		 config_unit CU_DUT (
 							   .clk(clk),
 							   .rstn(rst),
 							   .apb2cu_data_in(cu2apb_data_out),
 							   .apb2cu_en(apb2cu_en),
 							   .apb2cu_addr(apb2cu_addr),
 							   .cu2apb_data_out(apb2cu_data_in),
 							   .ar2cu_data_in(ar2cu_data_out),
 						       .ar2cu_data_in_valid(ar2cu_data_out_valid),
 							   .ar2cu_addr(ar2cu_addr),
 							   .ar2cu_addr_valid(ar2cu_addr_valid),
 							   .ar2cu_wr_rqst(ar2cu_wr_rqst),
 							   .ar2cu_rd_rqst(ar2cu_rd_rqst),
 							   .cu2ar_start_wl(cu2ar_start_wl),
 							   .cu2ar_data_out(cu2ar_data_in),
 							   .cu2ar_data_out_valid(cu2ar_data_in_valid),
 							  // .cu2ar_ifu_ack(cu2ar_ifu_ack),
 							   .cu2ar_ack(cu2ar_ack),
 							   .cu2ar_busy(cu2ar_busy),
 							   .cu2int_busy(cu2int_busy)
							);
  
  arbiter ARBITOR_DUT(  	.clk(clk) ,
                			.rstn(rst) ,
                			.ifu2ar_req(ifu2ar_req),
                			.dfu2ar_req(dfu2ar_grant_req),
                			.ar2dfu_wr_data(ar2dfu_wr_data) ,
                			.ar2dfu_wr_data_valid(ar2dfu_wr_data_valid) ,
                			//.ar2dfu_wr_addr() ,
                			//.ar2dfu_wr_addr_valid() ,
                			.ar2dfu_wr_done(ar2dfu_wr_done) ,
                      		.dfu2ar_rd_data(dfu2ar_axi_data_out)    ,//read data valid and last need to add
                      .dfu2ar_rd_data_vld(dfu2ar_axi_data_out_vld),
                			.axi2ar_rd_addr(axi2ar_rd_addr) ,
                			.axi2ar_rd_addr_valid(axi2ar_rd_addr_valid) ,
                			.ar2dfu_ack(ar2dfu_ack) ,
                			.dfu2ar_data_in(dfu2ar_data_out) ,
                			.dfu2ar_data_in_valid(dfu2ar_data_out_vld) ,
                			.dfu2ar_addr(dfu2ar_addr) ,
                			.dfu2ar_addr_valid(dfu2ar_addr_vld) ,
                			.dfu2ar_wr_rqst(dfu2ar_wr_req) ,
                			.dfu2ar_write_interrupt(dfu2ar_write_interrupt) ,//newly added
                			.dfu2ar_read_interrupt(dfu2ar_read_interrupt) ,//newly added
                			.ar2ifu_wr_data(ar2ifu_wr_data) ,
                			.ar2ifu_wr_data_valid(ar2ifu_wr_data_valid) ,
                			.ar2ifu_wr_done(ar2ifu_wr_done) ,
                			.ar2ifu_ack(ar2ifu_ack) ,
                			.ar2ifu_start_wl(ar2ifu_start_wl) ,
                			.ar2ifu_data_out(ar2ifu_data_out) ,
                			.ar2ifu_data_out_valid(ar2ifu_data_out_valid) ,
                			.ifu2ar_data_in(ifu2ar_data_in) ,
                			.ifu2ar_data_in_valid(ifu2ar_data_in_valid) ,
                			.ifu2ar_addr(ifu2ar_addr) ,
                			.ifu2ar_addr_valid(ifu2ar_addr_valid) ,
                			.ifu2ar_wr_rqst(ifu2ar_wr_rqst) ,
                			.ifu2ar_rd_rqst(ifu2ar_rd_rqst) ,
                			.ifu2ar_interrupt(ifu2ar_interrupt) ,
                			.ifu2ar_maskable_interrupt(ifu2ar_maskable_interrupt) ,
                			.ar2cu_data_out(ar2cu_data_out) ,
                			.ar2cu_data_out_valid(ar2cu_data_out_valid) ,
                			.ar2cu_addr(ar2cu_addr) ,
                			.ar2cu_addr_valid(ar2cu_addr_valid) ,
                			.ar2cu_wr_rqst(ar2cu_wr_rqst) ,
                			.ar2cu_rd_rqst(ar2cu_rd_rqst) ,
                			.cu2ar_start_wl(cu2ar_start_wl) ,
                			.cu2ar_data_in(cu2ar_data_in) ,
                			.cu2ar_data_in_valid(cu2ar_data_in_valid) ,
                			.cu2ar_busy(cu2ar_busy) ,
                			//.cu2ar_dfu_ack(cu2ar_dfu_ack) ,
							//.cu2ar_ifu_ack(cu2ar_ifu_ack) ,
                      .cu2ar_ack(cu2ar_ack),
                			.axi2ar_wr_data(axi2ar_wr_data) ,
                			.axi2ar_wr_data_valid(axi2ar_wr_data_valid) ,
                			.axi2ar_wr_addr(axi2ar_wr_addr) ,
                			.axi2ar_wr_addr_valid(axi2ar_wr_addr_valid) ,
                			.axi2ar_wr_done(axi2ar_wr_done) ,
                			.ar2axi_rd_data(ar2axi_rd_data) ,
                      .ar2axi_rd_data_vld(ar2axi_rd_data_vld),
                			.ar2dfu_rd_addr(ar2dfu_rd_addr) ,
                			.ar2dfu_rd_addr_valid(ar2dfu_rd_addr_valid) ,
                      		.ar2ifu_int_interrupt(ar2ifu_int_interrupt) ,// it goes to interface 
                			.ar_maskable_interrupt(ifu2ar_maskable_interrupt),
                			.ar2dfu_int_write_interrupt(ar2dfu_int_write_interrupt),//newly added
               				.ar2dfu_int_read_interrupt(ar2dfu_int_read_interrupt),//newly added
              				.ar2ifu_grant(ar2ifu_grant),//newly added
               				.ar2dfu_grant(ar2dfu_grant)//newly added
              
              );
  
  
  IFU  IFU_DUT(		 .clk(clk),
 					 .rstn(rst),
 					 .ar2ifu_data_in(ar2ifu_data_out),
 					 .ar2ifu_data_in_valid(ar2ifu_data_out_valid),
 					 .ar2ifu_start_wl(ar2ifu_start_wl),
 					 .ar2ifu_ack(ar2ifu_ack),
 					 .ifu2ar_addr(ifu2ar_addr),
 					 .ifu2ar_addr_valid(ifu2ar_addr_valid),
 					 .ifu2ar_wr_rqst(ifu2ar_wr_rqst),
 					 .ifu2ar_rd_rqst(ifu2ar_rd_rqst),
 					 .ifu2ar_interrupt(ifu2ar_interrupt),
 					 .ifu2ar_maskable_interrupt(ifu2ar_maskable_interrupt),
 					 .ifu2ar_data_out(ifu2ar_data_in),
 					 .ifu2ar_data_out_valid(ifu2ar_data_in_valid),
 					 .ar2ifu_wr_avalid(ar2ifu_wr_data_valid),
 					 .ar2ifu_wr_adata(ar2ifu_wr_data),
 					 .ar2ifu_wr_adone(ar2ifu_wr_done),
 					 .ifu2ar_grant_rqst(ifu2ar_req),
 					 .ar2ifu_grant(ar2ifu_grant),//newly added
 					 .idu2ifu_rd_rqst(idu2ifu_rd_rqst),
 					 .ifu2idu_fifo_empty(ifu2idu_fifo_empty),
 					 .ifu2idu_rdata(ifu2idu_rdata),
 					 .ifu2idu_rdata_valid(ifu2idu_rdata_valid)
		  				 	);
  
  AXI_TARGET AXI_SLAVE_DUT(	.ACLK(clk), 
  							.ARESETn(rst), 
                          	.AWID(AWID),
  							.AWADDR(AWADDR),
  							.AWLEN(AWLEN),
  							.AWSIZE(AWSIZE),
  							.AWBURST(AWBURST),                     
  							.AWVALID(AWVALID),
  							.AWREADY(AWREADY),                         
  							.WDATA(WDATA),                         
  							.WLAST(WLAST), 
  							.WVALID(WVALID),
  							.WREADY(WREADY),                          
  							.BRESP(BRESP),
  							.BVALID(BVALID),
  							.BREADY(BREADY),                         
  							.ARADDR(ARADDR),
  							.ARLEN(ARLEN),
  							.ARSIZE(ARSIZE),
  							.ARBURST(ARBURST),                     
  							.ARVALID(ARVALID),
  							.ARREADY(ARREADY),                        
  							.RDATA(RDATA),
  							.RLAST(RLAST),
  							.RVALID(RVALID),
  							.RRESP(RRESP),
  							.RREADY(RREADY),
                          	.WID(WID),
                          	.BID(BID),
                         	.ARID(ARID),
                          	//.WSTRB(WSTRB),
                         	//.AWCACHE(AWCACHE),
                         	//.AWLOCK(AWLOCK),
                          	//.AWQOS(AWQOS),
                          	//.AWPROT(AWPROT),
  							.ar2axi_rd_data(ar2axi_rd_data), 
                           .ar2axi_rd_data_vld(ar2axi_rd_data_vld),
  							.axi2ar_wr_addr(axi2ar_wr_addr),
  							.axi2ar_wr_addr_valid(axi2ar_wr_addr_valid),
  							.axi2ar_wr_data(axi2ar_wr_data),
  							.axi2ar_wr_data_valid(axi2ar_wr_data_valid),
  							.axi2ar_rd_addr(axi2ar_rd_addr),
  							.axi2ar_rd_addr_valid(axi2ar_rd_addr_valid),
  							.axi2ar_wr_done(axi2ar_wr_done)
                         );
  
  wire dfu2ar_lsc_done;
  
  idu IDU_DUT					(.clk(clk),
 								 .rst(rst),
 								 .ifu2idu_fifo_empty(ifu2idu_fifo_empty),
 								 .ifu2idu_rd_data(ifu2idu_rdata),
 								 .ifu2idu_rd_data_vld(ifu2idu_rdata_valid),
 								 .idu2ifu_rd_rqst(idu2ifu_rd_rqst),
 								 .idu2dfu_load_fifo_empty(idu2dfu_load_fifo_empty),
 								 .dfu2idu_load_instr_req(dfu2idu_load_instr_req),
 								 .idu2dfu_load_instr(idu2dfu_load_instr),
 								 .idu2dfu_load_instr_vld(idu2dfu_load_instr_vld),
 								 //.dfu2idu_load_done(dfu2idu_load_instr_done),
 								 .idu2dfu_compute_fifo_empty(idu2dfu_compute_fifo_empty),
 								 .dfu2idu_compute_instr_req(dfu2idu_compute_instr_req),
 								 .idu2dfu_compute_instr(idu2dfu_compute_instr),
 								 .idu2dfu_compute_instr_vld(idu2dfu_compute_instr_vld),
 								 //.dfu2idu_compute_done(dfu2idu_compute_done),
 								 .idu2dfu_store_fifo_empty(idu2dfu_store_fifo_empty),
 								
 								 .dfu2idu_store_instr_req(dfu2idu_store_instr_req),
 								 .idu2dfu_store_instr(idu2dfu_store_instr),
 								 .idu2dfu_store_instr_vld(idu2dfu_store_instr_vld),
 								 //.dfu2idu_store_done(dfu2idu_store_done)
                                 .dfu_lsc_done(dfu_lsc_done)
                                );
  
  dfu_lsc dfu_lsc_done1(.clk(clk),
                        .rst(rst),
                        .dfu2idu_load_instr_done(dfu2idu_load_instr_done),
                        .dfu2idu_compute_done(dfu2idu_compute_done),
                        .dfu2idu_store_done(dfu2idu_store_done),
                        .dfu_lsc_done(dfu_lsc_done)
                       );
  
			 DFU_TOP DFU_DUT (
   								 .clk                            (clk),
   								 .rst                            (rst),
   								 .idu2dfu_load_fifo_empty        (idu2dfu_load_fifo_empty),
   								 .idu2dfu_load_instr             (idu2dfu_load_instr),
   								 .idu2dfu_load_instr_vld         (idu2dfu_load_instr_vld),
   								 .ar2dfu_ack                     (ar2dfu_ack),
   								 .ar2dfu_data_in                 (ar2dfu_wr_data),
   								 .ar2dfu_data_in_vld             (ar2dfu_wr_data_valid),
   								 .ar2dfu_ack_data_done           (ar2dfu_wr_done),
								
   								 .dfu2idu_load_instr_req         (dfu2idu_load_instr_req),
   								 .dfu2ar_grant_req               (dfu2ar_grant_req),
   								 .ar2dfu_grant                   (ar2dfu_grant),
   								 .dfu2ar_wr_req                  (dfu2ar_wr_req),
   								 .dfu2ar_addr                    (dfu2ar_addr),
   								 .dfu2ar_addr_vld                (dfu2ar_addr_vld),
   								 .dfu2ar_data_out                (dfu2ar_data_out),
   								 .dfu2ar_data_out_vld            (dfu2ar_data_out_vld),
   								 .dfu2idu_load_instr_done        (dfu2idu_load_instr_done),
								
   								 .idu2dfu_compute_fifo_empty     (idu2dfu_compute_fifo_empty),
   								 .dfu2idu_compute_instr_req      (dfu2idu_compute_instr_req),
   								 .idu2dfu_compute_instr          (idu2dfu_compute_instr),
   								 .idu2dfu_compute_instr_vld      (idu2dfu_compute_instr_vld),
								
   								 .dfu2sys_data_out_a             (dfu2sys_data_out_a),
   								 .dfu2sys_data_vld_a             (dfu2sys_data_vld_a),
   								 .dfu2sys_data_out_b             (dfu2sys_data_out_b),
   								 .dfu2sys_data_vld_b             (dfu2sys_data_vld_b),
   								 .sys2dfu_data_out_c             (sys2dfu_data_out_c),
   								 .sys2dfu_data_out_c_vld         (sys2dfu_data_out_c_vld),
								
   								 .ar2dfu_axi_addr                (ar2dfu_rd_addr),
   								 .ar2dfu_axi_addr_vld            (ar2dfu_rd_addr_valid),
   								 .dfu2ar_axi_data_out            (dfu2ar_axi_data_out),
   								 .dfu2ar_axi_data_out_vld        (dfu2ar_axi_data_out_vld),
   								// .dfu2ar_axi_rd_last             (dfu2ar_axi_rd_last),
   								 .dfu2idu_compute_done           (dfu2idu_compute_done),
								
   								 .idu2dfu_store_fifo_empty       (idu2dfu_store_fifo_empty),
   								 .dfu2idu_store_instr_req        (dfu2idu_store_instr_req),
   								 .idu2dfu_store_instr            (idu2dfu_store_instr),
   								 .idu2dfu_store_instr_vld        (idu2dfu_store_instr_vld),
								
   								 .dfu2idu_store_done             (dfu2idu_store_done),
   								 .dfu2ar_read_interrupt          (dfu2ar_read_interrupt),
   								 .dfu2ar_write_interrupt         (dfu2ar_write_interrupt)
								);								
  systolic_array DUT_SYS( 	.clk(clk),
                         	.rst_n(rst),
                         	.dfu2sys_a_data_in_vld(dfu2sys_data_vld_a),
                        	.dfu2sys_a_data_in(dfu2sys_data_out_a),    
                        	.dfu2sys_b_data_in_vld(dfu2sys_data_vld_b),
                         	.dfu2sys_b_data_in(dfu2sys_data_out_b), 
                         	.sys2dfu_c_data_out(sys2dfu_data_out_c),
                         	.sys2dfu_c_data_out_vld(sys2dfu_data_out_c_vld)
                        );

  assign interrupt = (ar2ifu_int_interrupt || ar2dfu_int_read_interrupt || ar2dfu_int_write_interrupt)?1:0;
  
          wire [(Es*3)-1:0] temp ;
  assign temp = sys2dfu_data_out_c[0];
  wire temp1 ;
  assign temp1 = sys2dfu_data_out_c_vld[0];
  
endmodule


