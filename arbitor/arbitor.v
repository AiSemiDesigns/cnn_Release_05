module arbiter(  clk ,
         rstn ,
         ifu2ar_req,
         dfu2ar_req,
         ar2dfu_wr_data ,
         ar2dfu_wr_data_valid ,
         //ar2dfu_wr_addr ,
         //ar2dfu_wr_addr_valid ,
         ar2dfu_wr_done ,
         dfu2ar_rd_data    ,
               dfu2ar_rd_data_vld,
         axi2ar_rd_addr ,
         axi2ar_rd_addr_valid ,
         ar2dfu_ack ,
         dfu2ar_data_in ,
         dfu2ar_data_in_valid ,
         dfu2ar_addr ,
         dfu2ar_addr_valid ,
         dfu2ar_wr_rqst ,
         dfu2ar_write_interrupt ,//newly added
         dfu2ar_read_interrupt ,//newly added
         ar2ifu_wr_data ,
         ar2ifu_wr_data_valid ,
         ar2ifu_wr_done ,
         ar2ifu_ack ,
         ar2ifu_start_wl ,
         ar2ifu_data_out ,
         ar2ifu_data_out_valid ,
         ifu2ar_data_in ,
         ifu2ar_data_in_valid ,
         ifu2ar_addr ,
         ifu2ar_addr_valid ,
         ifu2ar_wr_rqst ,
         ifu2ar_rd_rqst ,
         ifu2ar_interrupt ,
         ifu2ar_maskable_interrupt ,
         ar2cu_data_out ,
         ar2cu_data_out_valid ,
         ar2cu_addr ,
         ar2cu_addr_valid ,
         ar2cu_wr_rqst ,
         ar2cu_rd_rqst ,
         cu2ar_start_wl ,
         cu2ar_data_in ,
         cu2ar_data_in_valid ,
         cu2ar_busy ,
        // cu2ar_dfu_ack ,
	// cu2ar_ifu_ack ,
       	 cu2ar_ack,
         axi2ar_wr_data ,
         axi2ar_wr_data_valid ,
         axi2ar_wr_addr ,
         axi2ar_wr_addr_valid ,
         axi2ar_wr_done ,
         ar2axi_rd_data ,
            ar2axi_rd_data_vld,   
         ar2dfu_rd_addr ,
         ar2dfu_rd_addr_valid ,
         ar2ifu_int_interrupt ,
         ar_maskable_interrupt,
         ar2dfu_int_write_interrupt,//newly added
       	 ar2dfu_int_read_interrupt,//newly added
      	 ar2ifu_grant,//newly added
       	 ar2dfu_grant//newly added
      );


parameter AXI_WIDTH=64;

input clk ;
input rstn ;
input ifu2ar_req;
input dfu2ar_req;

//Arbiter-DFU------------------------
output [AXI_WIDTH-1:0] ar2dfu_wr_data ;
output ar2dfu_wr_data_valid ;
// output [AXI_WIDTH-1:0] ar2dfu_wr_addr ;
//output ar2dfu_wr_addr_valid ;
output ar2dfu_wr_done ;
input [255-1:0] dfu2ar_rd_data ;//modified 
  input dfu2ar_rd_data_vld;
input [AXI_WIDTH-1:0] axi2ar_rd_addr ;
input axi2ar_rd_addr_valid ;
output ar2dfu_ack ;
input [AXI_WIDTH-1:0] dfu2ar_data_in ;
input dfu2ar_data_in_valid ;
input [AXI_WIDTH-1:0] dfu2ar_addr ;
input dfu2ar_addr_valid ;
input dfu2ar_wr_rqst ;

input dfu2ar_write_interrupt;
input dfu2ar_read_interrupt; 

output reg ar2dfu_grant ; //newly added 

//Arbiter-DFU------------------------

//Arbiter-IFU------------------------
output [AXI_WIDTH-1:0] ar2ifu_wr_data ;
output ar2ifu_wr_data_valid ;
output ar2ifu_wr_done ;
output ar2ifu_ack ;
output ar2ifu_start_wl ;
output [AXI_WIDTH-1:0] ar2ifu_data_out ;
output ar2ifu_data_out_valid ;
input [AXI_WIDTH-1:0] ifu2ar_data_in ;
input ifu2ar_data_in_valid ;
input [AXI_WIDTH-1:0] ifu2ar_addr ;
input ifu2ar_addr_valid ;
input ifu2ar_wr_rqst ;
input ifu2ar_rd_rqst ;
input ifu2ar_interrupt ;
input ifu2ar_maskable_interrupt ;
output reg ar2ifu_grant;//newly added  
//Arbiter-IFU------------------------

//Arbiter-CU-------------------------
output [AXI_WIDTH-1:0] ar2cu_data_out ;
output ar2cu_data_out_valid ;
output [AXI_WIDTH-1:0] ar2cu_addr ;
output ar2cu_addr_valid ;
output ar2cu_wr_rqst ;
output ar2cu_rd_rqst ;
input cu2ar_start_wl ;
input [AXI_WIDTH-1:0] cu2ar_data_in ;
input cu2ar_data_in_valid ;
input cu2ar_busy ;
//input cu2ar_dfu_ack ;
//input cu2ar_ifu_ack ;
input cu2ar_ack;
//Arbiter-CU-------------------------

//Arbiter-AXI------------------------
input [AXI_WIDTH-1:0] axi2ar_wr_data ;
input axi2ar_wr_data_valid ;
input [AXI_WIDTH-1:0] axi2ar_wr_addr ;
input axi2ar_wr_addr_valid ;
input axi2ar_wr_done ;
output [AXI_WIDTH-1:0] ar2axi_rd_data ;
  output ar2axi_rd_data_vld;
output [AXI_WIDTH-1:0] ar2dfu_rd_addr ;
output ar2dfu_rd_addr_valid ;
//Arbiter-AXI------------------------

//Arbiter-Interface------------------
output ar2ifu_int_interrupt ;//newly added--> arbitor to interface interrupt 
output ar_maskable_interrupt ;
output ar2dfu_int_write_interrupt;//newly added --> arbitor to interface interrupt 
output ar2dfu_int_read_interrupt;//newly added  --> arbitor to interface interrupt 

reg [AXI_WIDTH-1:0] ar2dfu_wr_addr;
reg ar2dfu_wr_addr_valid;

//Arbiter-Interface------------------

//AXI-Arbiter-DFU---------------------------------------------  
assign ar2dfu_wr_data = (ar2dfu_grant)? axi2ar_wr_data : 0;
assign ar2dfu_wr_data_valid = (ar2dfu_grant)? axi2ar_wr_data_valid : 0;
assign ar2dfu_wr_addr = (ar2dfu_grant)? axi2ar_wr_addr : 0;
assign ar2dfu_wr_addr_valid = (ar2dfu_grant)? axi2ar_wr_addr_valid: 0;
assign ar2dfu_wr_done = (ar2dfu_grant)? axi2ar_wr_done: 0;
assign ar2dfu_ack = (ar2dfu_grant)? cu2ar_ack: 0;
//AXI-Arbiter-DFU---------------------------------------------   

//AXI-Arbiter-IFU---------------------------------------------  
assign ar2ifu_wr_data =(ar2ifu_grant)? axi2ar_wr_data : 0;
assign ar2ifu_wr_data_valid =(ar2ifu_grant)? axi2ar_wr_data_valid : 0;
assign ar2ifu_wr_done =(ar2ifu_grant)? axi2ar_wr_done: 0;
assign ar2ifu_ack =(ar2ifu_grant)? cu2ar_ack: 0;
assign ar2ifu_start_wl =(ar2ifu_grant)? cu2ar_start_wl: 0;
assign ar2ifu_data_out =(ar2ifu_grant)? cu2ar_data_in: 0;
assign ar2ifu_data_out_valid=(ar2ifu_grant)? cu2ar_data_in_valid: 0;
//AXI-Arbiter-IFU---------------------------------------------  

//DFU/IFU-Arbiter-CU------------------------------------------------------------------
assign ar2cu_data_out =(cu2ar_busy)? 0:((ar2ifu_grant)? ifu2ar_data_in:((ar2dfu_grant)? dfu2ar_data_in:0));
assign ar2cu_data_out_valid =(cu2ar_busy)? 0:((ar2ifu_grant)? ifu2ar_data_in_valid:((ar2dfu_grant)? dfu2ar_data_in_valid:0));
assign ar2cu_addr =(cu2ar_busy)? 0:((ar2ifu_grant)? ifu2ar_addr:((ar2dfu_grant)? dfu2ar_addr:0));
assign ar2cu_addr_valid =(cu2ar_busy)? 0:((ar2ifu_grant)? ifu2ar_addr_valid:((ar2dfu_grant)? dfu2ar_addr_valid:0));
assign ar2cu_wr_rqst =(cu2ar_busy)? 0:((ar2ifu_grant)? ifu2ar_wr_rqst:((ar2dfu_grant)? dfu2ar_wr_rqst:0));
assign ar2cu_rd_rqst =(!ar2ifu_grant)? 0:((cu2ar_busy)? 0:ifu2ar_rd_rqst);
//DFU/IFU-Arbiter-CU------------------------------------------------------------------

//AXI-Arbiter-DFU-------------------------------------------------------------------
assign ar2axi_rd_data =(ar2dfu_grant)? dfu2ar_rd_data : 0;
  assign ar2axi_rd_data_vld= (ar2dfu_grant)? dfu2ar_rd_data_vld : 0;
assign ar2dfu_rd_addr =(ar2dfu_grant)? axi2ar_rd_addr : 0;
assign ar2dfu_rd_addr_valid =(ar2dfu_grant)? axi2ar_rd_addr_valid : 0;
//AXI-Arbiter-DFU-------------------------------------------------------------------

//Interface-Arbiter-----------------------------------------------------------------
assign ar2ifu_int_interrupt =(ar2ifu_grant)? ifu2ar_interrupt : 0;
assign ar_maskable_interrupt =(ar2ifu_grant)? ifu2ar_maskable_interrupt : 0;

assign ar2dfu_int_write_interrupt=(ar2dfu_grant)? dfu2ar_write_interrupt : 0;//newly added
assign ar2dfu_int_read_interrupt=(ar2dfu_grant)? dfu2ar_read_interrupt : 0;//newly added
//Interface-Arbiter-----------------------------------------------------------------

always@(posedge clk) begin
if (!rstn) begin
ar2ifu_grant <= 1'b0;
ar2dfu_grant <= 1'b0;
end

else//newly added
case({ifu2ar_req,dfu2ar_req})
2'b00:begin
  	ar2ifu_grant <= 1'b0;
	ar2dfu_grant<= 1'b0;
end
2'b01:begin
  ar2ifu_grant <= 1'b0;
  ar2dfu_grant<= 1'b1;
end
2'b10:begin
  ar2ifu_grant <= 1'b1;
  ar2dfu_grant<= 1'b0;
end
2'b11:begin
  ar2ifu_grant <= 1'b1;
  ar2dfu_grant<= 1'b0;
end
default: begin
  ar2ifu_grant <= 1'b1;
  ar2dfu_grant<= 1'b0;
end
endcase
end

endmodule
