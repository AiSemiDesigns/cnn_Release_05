module config_unit (
clk,
rstn,
apb2cu_data_in,
apb2cu_en,
apb2cu_addr,
cu2apb_data_out,
ar2cu_data_in,
ar2cu_data_in_valid,
ar2cu_addr,
ar2cu_addr_valid,
ar2cu_wr_rqst,
ar2cu_rd_rqst,
cu2ar_start_wl,
cu2ar_data_out,
cu2ar_data_out_valid,
//cu2ar_ifu_ack,
//cu2ar_dfu_ack,
cu2ar_busy,
cu2int_busy,
cu2ar_ack
);



//apb-cu-------------------------------------
input clk, rstn;

input [PDATA_WIDTH-1:0] apb2cu_data_in;
input apb2cu_en;
input [PADDR_WIDTH-1:0] apb2cu_addr;
output reg [PDATA_WIDTH-1:0] cu2apb_data_out;

output reg cu2int_busy;
//apb-cu-------------------------------------

//arbiter-cu---------------------------------
input [CU_DATA_WIDTH-1:0] ar2cu_data_in;
input ar2cu_data_in_valid;
input [ADDR_WIDTH-1:0] ar2cu_addr;
input ar2cu_addr_valid;
input ar2cu_wr_rqst, ar2cu_rd_rqst;
output cu2ar_start_wl;
output reg [CU_DATA_WIDTH-1:0] cu2ar_data_out;
output reg cu2ar_data_out_valid;
// output reg cu2ar_ifu_ack;
// output reg cu2ar_dfu_ack;
output reg cu2ar_busy;
output reg cu2ar_ack;
//arbiter-cu---------------------------------

reg [PDATA_WIDTH-1:0] cu_reg11, cu_reg12, cu_reg21, cu_reg22, cu_reg3;
reg [PDATA_WIDTH-1:0] dma_reg11, dma_reg12, dma_reg21, dma_reg22, dma_reg31, dma_reg32;
reg [PDATA_WIDTH-1:0] rsvd_reg11, rsvd_reg12, rsvd_reg21, rsvd_reg22, rsvd_reg31, rsvd_reg32, rsvd_reg41, rsvd_reg42;
reg [PDATA_WIDTH-1:0] rsvd_dfu_reg11, rsvd_dfu_reg12, rsvd_dfu_reg21, rsvd_dfu_reg22, rsvd_dfu_reg31, rsvd_dfu_reg32;
reg temp;

// write to config_unit----------------------------
always @(posedge clk or negedge rstn) begin
if (!rstn) begin

cu2ar_data_out_valid <= 0;

// cu2ar_ifu_ack <= 0;
//  cu2ar_dfu_ack <= 0;
//cu2ar_busy <= 0;
//cu2int_busy <= 0;
temp<=0;
//cu2ar_ack<=0;
{cu_reg11, cu_reg12, cu_reg21, cu_reg22, cu_reg3,
dma_reg11, dma_reg12, dma_reg21, dma_reg22, dma_reg31, dma_reg32,
rsvd_reg11, rsvd_reg12, rsvd_reg21, rsvd_reg22, rsvd_reg31, rsvd_reg32, rsvd_reg41, rsvd_reg42,
rsvd_dfu_reg11, rsvd_dfu_reg12, rsvd_dfu_reg21, rsvd_dfu_reg22, rsvd_dfu_reg31, rsvd_dfu_reg32} <= 0;
end else begin
if (apb2cu_en) begin // apb write
case (apb2cu_addr)
  'h3fe: cu_reg11 <= apb2cu_data_in;  // program_size(lsb)  
  'h3ff: cu_reg12 <= apb2cu_data_in;  // program_size(msb)
  'h400: cu_reg21 <= apb2cu_data_in;  // program_start_address(lsb)
  'h401: cu_reg22 <= apb2cu_data_in;  // program_start_address(msb)
  'h402: cu_reg3 <= apb2cu_data_in;   // start_work_load  
endcase
end

if (ar2cu_wr_rqst && ar2cu_addr_valid) begin // arbiter write
case (ar2cu_addr)
  'h403: {dma_reg12, dma_reg11} <= ar2cu_data_in;       // request_size
  'h405: {dma_reg22, dma_reg21} <= ar2cu_data_in;       // request_source_address(dram address)
  'h407:begin {dma_reg32, dma_reg31} <= ar2cu_data_in;temp<=1;  
  end 
  'h411: {rsvd_dfu_reg22, rsvd_dfu_reg21} <= ar2cu_data_in;
  'h413: {rsvd_dfu_reg32, rsvd_dfu_reg31} <= ar2cu_data_in;
  // request_destination_address(fifo_dummy_address)(lsb)
 /*'h409: {rsvd_reg12, rsvd_reg11} <= ar2cu_data_in;
  'h40b: {rsvd_reg22, rsvd_reg21} <= ar2cu_data_in;
  'h40d: begin{rsvd_reg32, rsvd_reg31} <= ar2cu_data_in;temp<=1;end
  'h40f: {rsvd_reg42, rsvd_reg41} <= ar2cu_data_in;
  'h411: {rsvd_dfu_reg12, rsvd_dfu_reg11} <= ar2cu_data_in;
  'h413: {rsvd_dfu_reg22, rsvd_dfu_reg21} <= ar2cu_data_in;
  'h415: {rsvd_dfu_reg32, rsvd_dfu_reg31} <= ar2cu_data_in;*/
endcase
end
end
end

// read logic ---------------------------------------------------
always @(posedge clk) begin
if(!rstn) begin
cu2apb_data_out <= 0;
    cu2ar_data_out <= 0;
    end
else if (!apb2cu_en || ar2cu_rd_rqst) begin
case (apb2cu_addr)
'h00000403: cu2apb_data_out <= dma_reg11;
'h00000404: cu2apb_data_out <= dma_reg12;
'h00000405: cu2apb_data_out <= dma_reg21;
'h00000406: cu2apb_data_out <= dma_reg22;
'h00000407: cu2apb_data_out <= dma_reg31;
'h00000408: cu2apb_data_out <= dma_reg32;
  'h00000411: cu2apb_data_out <= rsvd_dfu_reg21;
'h00000412: cu2apb_data_out <= rsvd_dfu_reg31;
/*  'h00000409: cu2apb_data_out <= rsvd_reg11;
'h0000040a: cu2apb_data_out <= rsvd_reg12;
'h0000040b: cu2apb_data_out <= rsvd_reg21;
'h0000040c: cu2apb_data_out <= rsvd_reg22;
'h0000040d: cu2apb_data_out <= rsvd_reg31;
'h0000040e: cu2apb_data_out <= rsvd_reg32;
'h0000040f: cu2apb_data_out <= rsvd_reg41;
'h00000410: cu2apb_data_out <= rsvd_reg42;
'h00000411: cu2apb_data_out <= rsvd_dfu_reg11;
'h00000412: cu2apb_data_out <= rsvd_dfu_reg12;
'h00000413: cu2apb_data_out <= rsvd_dfu_reg21;
'h00000414: cu2apb_data_out <= rsvd_dfu_reg22;
'h00000415: cu2apb_data_out <= rsvd_dfu_reg31;
'h00000416: cu2apb_data_out <= rsvd_dfu_reg32;*/
endcase

if (ar2cu_addr_valid) begin
case (ar2cu_addr)
  'h000003fe: cu2ar_data_out <= {cu_reg12, cu_reg11}; // program size
  'h00000400: cu2ar_data_out <= {cu_reg22, cu_reg21}; // program start address
endcase
end
end else begin
cu2ar_data_out <= cu2ar_data_out;
end
end

// send start_work_load --------------------
assign cu2ar_start_wl = cu_reg3[0];

always @(posedge clk) begin
cu2ar_data_out_valid <= ar2cu_rd_rqst ? 1 : 0;
end

// config2interface busy signal logic-----------------------------------------
always @(posedge clk) begin
if(!rstn)
cu2int_busy <= 0;
else if (ar2cu_wr_rqst)
cu2int_busy <= 1;
else 
cu2int_busy <= 0;
end

// config2arbiter busy signal logic -----------------------------------------
always @(posedge clk) begin
if(!rstn)
cu2ar_busy <= 0;
else if (apb2cu_en)
cu2ar_busy <= 1;
else 
cu2ar_busy <= 0;
end

/*always @(posedge clk) begin
if ((cu2int_busy == 1) && |{dma_reg32, dma_reg31} != 0)
cu2ar_ifu_ack <= 1;
else
cu2ar_ifu_ack <= 0;
end

always @(posedge clk) begin
if ((cu2int_busy == 1) && ((|{rsvd_reg32, rsvd_reg31} != 0) || (|{rsvd_dfu_reg22, rsvd_dfu_reg21} != 0)))
cu2ar_dfu_ack <= 1;
else
cu2ar_dfu_ack <= 0;
end
always @(posedge clk) begin
if ((cu2int_busy == 1) && (temp==1) || (|{rsvd_dfu_reg22, rsvd_dfu_reg21} != 0))
cu2ar_dfu_ack <= 1;
else
cu2ar_dfu_ack <= 0;
end*/
always @(posedge clk) begin
if(!rstn)
cu2ar_ack <= 0;
else if ((cu2int_busy == 1) && (temp==1))
cu2ar_ack <= 1;
else
cu2ar_ack <= 0;
end
endmodule

