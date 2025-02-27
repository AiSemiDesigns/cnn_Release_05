module ifu_fifo(clk,
			rstn,
            fifo_wr_en,
            fifo_rd_en,
            fifo_wr_data,
//             fifo_addr,
//             fifo_addr_valid,
            fifo_rd_valid,
            fifo_rd_data,
            fifo_empty,
            fifo_full, 
    //        fifo_overflow,
     //       fifo_underflow,
            threshold
           );
           

  
  input clk;
  input rstn;
  input fifo_wr_en;
  input fifo_rd_en;
  input [FIFO_WIDTH-1:0] fifo_wr_data;
//   input [ADDR_WIDTH-1:0] fifo_addr;
//   input fifo_addr_valid;
  output reg fifo_rd_valid;
  output reg [FIFO_WIDTH-1:0] fifo_rd_data;
  output  fifo_empty;
  output  fifo_full;
 // output reg fifo_overflow;
 // output reg fifo_underflow;
  output reg threshold;
  
  

//  parameter threshold_value = (FIFO_LENGTH)/4;
  
  reg [FIFO_WIDTH-1:0] memory[0:FIFO_LENGTH-1];
  reg [$clog2(FIFO_LENGTH)-1:0] wr_ptr,rd_ptr; 
  
  integer i;
  
  reg fifo_overflow;
  reg fifo_underflow;
  
      
  //Write pointer and write data logic-------------------------------------------
  
//   always@(posedge clk)
//     if(fifo_addr_valid)begin
//     rd_ptr<=fifo_addr;
//       wr_ptr<=fifo_addr;
//   end
      
  
  always @(posedge clk or negedge rstn)
  if(!rstn) begin
  for(i=0;i<FIFO_LENGTH;i=i+1)
          memory[i]<='b0;
  end
   else  if (fifo_wr_en && ~fifo_full) begin
      memory[wr_ptr] <= fifo_wr_data;
    end
  else memory[wr_ptr] <= memory[wr_ptr];
  
  
  always @(posedge clk or negedge rstn)
  if(!rstn)
  wr_ptr<=0;
   else if(fifo_wr_en && ~fifo_full)
       wr_ptr<=wr_ptr+1;
    else 
      wr_ptr<=wr_ptr;
    
  
  //read pointer and read data logic -------------------------------------------
  
  always @(posedge clk or negedge rstn)
  if(!rstn) begin
  fifo_rd_data<=0;
  fifo_rd_valid<=0;
  end
   else if(fifo_rd_en && ~fifo_empty) begin
      fifo_rd_data <= memory[rd_ptr];
//       $display("read_data");
        fifo_rd_valid<=1'b1;
    end
   else begin
     fifo_rd_valid<=0;
  end
  
  
  always@(posedge clk or negedge rstn)
  if(!rstn) rd_ptr<=0;
    else  if(fifo_rd_en  && ~fifo_empty)
        rd_ptr<=rd_ptr+1;
      else
        rd_ptr<=rd_ptr;
  
  
  // threshold logic-------------------------------------------------------------
  
  always@(posedge clk or negedge rstn)
  if(!rstn) threshold<=0;
  else  if(FIFO_LENGTH-(threshold_value) == rd_ptr)//1016 
            threshold <=1; 
     else
      		threshold <=0;
  
  // under_flow and fifo_overflow logic-------------------------------------------
      
  always@(posedge clk or negedge rstn)  
  if (!rstn)
  begin
  fifo_overflow <= 0;
        fifo_underflow <= 0;
  end
    begin
      fifo_overflow <= fifo_full & fifo_wr_en;
      fifo_underflow <= fifo_rd_en&fifo_empty;
    end
  
  //fifo full and  empty logic ----------------------------------------------------

  assign    fifo_full = (wr_ptr+1 == rd_ptr)?1:0;
  assign    fifo_empty =(rd_ptr == wr_ptr)?1:0;

  
endmodule 
