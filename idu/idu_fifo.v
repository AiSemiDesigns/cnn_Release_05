// Code your design here
module idu_fifo(clk,rst,wr_en,rd_en,full,
//empty,
data_in,data_out,valid
//check_prev
);
  parameter INSTR_WIDTH=256,depth=3;
  
  input clk,rst,wr_en,rd_en;
  input [INSTR_WIDTH-1:0]data_in;
  output full;
  reg empty;
  output reg valid;
  output reg [INSTR_WIDTH-1:0]data_out;
  //input check_prev;//newly added
  
  reg [3:0]wr_addr,rd_addr;
  reg [3:0]count;
  reg [INSTR_WIDTH-1:0]mem[depth-1:0];
  integer i;
  
  always @(posedge clk)
    begin
    if(!rst)
      begin
        for(i=0;i<depth;i=i+1)
          mem[i]<=0;
       // data_out<=0;
        wr_addr<=0;
      end
        else if(wr_en && !full)
          begin
          mem[wr_addr]<=data_in;
            wr_addr<=wr_addr+1'b1;
          end
    end
  always @(posedge clk)
    begin
      if(!rst)
        begin
          data_out<=0;
          rd_addr<=0;
          valid<=0;
        end
      else if(rd_en&&!empty  )
        begin
          valid<=1;
          data_out<=mem[rd_addr];
          rd_addr<=rd_addr+1'b1;
        end
      else 
        valid<=0;
        data_out <= 0;
    end
  always @(posedge clk)
    begin
    if(!rst)
      count<=0;
  else if(wr_en)
    count<=count+1;
  else if(rd_en)
    count<=count-1;
    end
  assign full=(count==8)?1:0;
  assign empty=(count==0)?1:0;
endmodule

  
