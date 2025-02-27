`include "sram_c.v"

module sram_top (
input clk,
input rst,
input [(Es*3)-1:0] sys2dfu_data_out_c [0:no_of_sram_banks-1],
input sys2dfu_data_out_c_vld [0:no_of_sram_banks-1],
input [sram_addr-1:0] ar2dfu_axi_addr,
input ar2dfu_axi_addr_vld,
output reg [AXI_RDATA_WIDTH-1:0] dfu2ar_axi_data_out,
output reg dfu2ar_axi_data_out_vld,
output reg dfu2idu_compute_done,
output reg ack_sram_c_rd,
output reg dfu2ar_axi_rd_last
);
 // wire [(Es*3)-1:0] dgsffgs;
reg [sram_addr-1:0] wr_c_addr;
reg wr_en;
reg [(Es*3)-1:0] data_out [0:no_of_sram_banks-1];
reg data_out_vld [0:no_of_sram_banks-1];
  
  
// reg [255:0]temp_data;

// Instantiate SRAM modules
  //  assign dgsffgs = sys2dfu_data_out_c[1]; // tesing purpose  added
generate
genvar i;
for (i = 0; i < no_of_sram_banks; i = i + 1) begin : sram_inst
sram_c DUT_sram (
.clk(clk),
.rst(rst),
.wr_en(wr_en),
.wr_c_addr(wr_c_addr),
.bank_data_c_in(sys2dfu_data_out_c[i]),
// .bank_data_c_in_vld(sys2dfu_data_out_c_vld[i]),
.rd_en(ar2dfu_axi_addr_vld),
.rd_addr(ar2dfu_axi_addr),
.data_out(data_out[i]),
.data_out_vld(data_out_vld[i])
);        
end
endgenerate

always @(posedge clk or negedge rst) begin
if (!rst) begin
//  dfu2ar_axi_data_out <= 0;
wr_c_addr <= 0;
dfu2idu_compute_done <= 0;
//wr_en <= 0;
//ack_sram_c_rd <= 0;
//dfu2ar_axi_rd_last <= 0;
end 
else 
begin
// Write Operation
if (sys2dfu_data_out_c_vld[0]) begin
// wr_en <= 1;
if (wr_c_addr + 1 == no_of_sram_banks) begin
dfu2idu_compute_done <= 1;
end
else begin
//wr_en <= 0;
dfu2idu_compute_done <= 0;
end
end
else 
dfu2idu_compute_done <= 0;

if (sys2dfu_data_out_c_vld[0]) begin
if (wr_c_addr < no_of_sram_banks - 1) begin
wr_c_addr <= wr_c_addr + 1'b1;
end
else
wr_c_addr <= wr_c_addr;
end
else 
wr_c_addr <= wr_c_addr;
end
end

// Output Data
//  dfu2ar_axi_data_out  <= {64'b0, data_out[7], data_out[6], data_out[5], data_out[4], data_out[3], data_out[2], data_out[1], data_out[0]};

//   dfu2ar_axi_data_out_vld <= (data_out_vld[0] || data_out_vld[1] || data_out_vld[2] || data_out_vld[3] || data_out_vld[4] || data_out_vld[5] || data_out_vld[6] || data_out_vld[7]);


// Acknowledgment and Last Read
/*  if (dfu2ar_axi_data_out_vld) begin
dfu2ar_axi_rd_last <= 1;
ack_sram_c_rd <= 1;
end else begin
dfu2ar_axi_rd_last <= 0;
ack_sram_c_rd <= 0;
end
end
end*/
/*always @(posedge clk) 
begin
if(data_out_vld[0]||temp)
begin
temp<=1;
if(i<ROW)
begin
dfu2ar_axi_data_out<=data_out_vld[i];
dfu2ar_axi_data_out_vld<=1;
i<=i+1;
end
else begin
i<=0;
dfu2ar_axi_data_out<=0;
dfu2ar_axi_data_out_vld<=0;
end
end
end*/
integer k;
parameter idel=0,c_transfer=1;
reg state;
always @(posedge clk) 
if (!rst) begin
state<=idel;
dfu2ar_axi_data_out<=0;
dfu2ar_axi_data_out_vld<=0;
end
else
case(state)
idel: begin
k<=0;
dfu2ar_axi_rd_last <= 0;
ack_sram_c_rd <= 0;
  if(data_out_vld[0] && ar2dfu_axi_addr_vld) begin
	state<=c_transfer;
dfu2ar_axi_data_out<=data_out[0];
dfu2ar_axi_data_out_vld<=1;
k<=1;
end
else begin
dfu2ar_axi_data_out<=0;
dfu2ar_axi_data_out_vld<=0;
end
end
c_transfer: begin
	k<=k+1;
  if(k==ROW-1)
	begin
	state<=idel;
	dfu2ar_axi_data_out<=data_out[k];
	dfu2ar_axi_data_out_vld<=1;
	dfu2ar_axi_rd_last <= 1;
	ack_sram_c_rd <= 1;
	end		

else 	 
begin
dfu2ar_axi_rd_last <= 0;
dfu2ar_axi_data_out<=data_out[k];
dfu2ar_axi_data_out_vld<=1;
end
end
default:state<=idel;
endcase

assign wr_en = sys2dfu_data_out_c_vld[0]?1:0;
endmodule

