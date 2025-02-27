module APB_TARGET ( P_clk,
                       P_rstn,
                       P_addr,
                       P_selx,
                       P_enable,
                       P_write,
                       P_wdata,
                       P_ready,
                       P_slverr,
                       P_rdata,
                       wr_en,
                       data_out, 
                       addr, 
                       data_in);
  
  input P_clk,P_rstn,P_selx,P_enable,P_write;
  input [PADDR_WIDTH-1:0]P_addr;
  input [PDATA_WIDTH-1:0]P_wdata;
  output  [PDATA_WIDTH-1:0]P_rdata;
  output reg P_ready,P_slverr;
  output reg [PDATA_WIDTH-1:0] data_out;
  output reg wr_en;
  output wire [PADDR_WIDTH-1:0] addr;
  output wire [PDATA_WIDTH-1:0] data_in;
  
//    assign wr_en = (P_selx && P_enable && P_write );
//    assign data_out = P_wdata;
  assign addr= P_addr;
//   assign P_rdata=(P_selx && P_enable && !P_write )?data_in:P_rdata;
  assign P_rdata=(|data_in)?data_in:0;
  
  
  reg [1:0]APB_FSM;
parameter IDLE=2'd0,SETUP=2'd1,ACCESS_P=2'd2;
  
  
  always @ (posedge P_clk)
    if (!P_rstn)
      begin
      //  P_slverr<=0;
        P_ready<=0;
        APB_FSM<=IDLE;
        wr_en <= 'b0;
        data_out <= 'b0;
       // P_rdata<=0;
      end
  else 
    case (APB_FSM)
      
      IDLE : begin
        if (P_selx==1 && P_enable==0)
          begin
           APB_FSM<=SETUP;
          end
        wr_en<=1'b0;
       // P_rdata<=0;
      end
      
      SETUP : begin
        if (P_selx && P_enable)
            APB_FSM<=ACCESS_P;
        else if (P_selx && !P_enable)
          begin
            APB_FSM<=SETUP;
            P_ready<=0;
          end
        else 
          begin
            APB_FSM <= IDLE;
            P_ready<=0;
          end
        wr_en<=1'b0;
       // P_rdata<=0;
      end
      
      ACCESS_P : begin
        if (P_selx && P_enable)
          begin
            if (P_write)
              begin
                P_ready<=1;
                wr_en<=1;
                data_out<=P_wdata;
              end
            else if(!P_write)
              begin
                P_ready<=1;
                wr_en<=0;
               // P_rdata<=data_in;
              end
          end
        else if (P_selx && !P_enable)
          APB_FSM<=SETUP;
        else if (!P_selx && !P_enable)
          APB_FSM<=IDLE;
      end
      default : APB_FSM<=IDLE;
    endcase
  
  
   always @ (posedge P_clk)
        begin
        if(!P_rstn)
        P_slverr <= 0;
          else if (P_addr<'h3fe || P_addr>'h416)
            P_slverr<=1;
          else 
             P_slverr<=0;
        end
endmodule 
