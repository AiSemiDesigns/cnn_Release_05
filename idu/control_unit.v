// Code your design here
module control_unit #(parameter FIFO_IFU_WIDTH=64,INSTR_WIDTH=256,INT_WIDTH=192)(
  input		clk,rst						,
  input 	ifu2idu_fifo_empty			,
  input 	[FIFO_IFU_WIDTH-1:0]ifu2idu_rd_data ,
  input   	ifu2idu_rd_data_vld,
  input		load_full,comp_full,store_full,
 // input 	dfu2idu_load_done,
  //input 	dfu2idu_compute_done ,
  //input 	dfu2idu_store_done ,
  input dfu_lsc_done,
  output reg idu2ifu_rd_rqst			,
  output reg store_wr_en,load_wr_en,comp_wr_en,
  output reg [INSTR_WIDTH-1:0]load_data,store_data,comp_data,
  output reg  start_load,start_compute,start_store//newly added
); 
  
  reg [INT_WIDTH-1:0]internal_reg;
  reg [FIFO_IFU_WIDTH-1:0]int_reg;
  reg [2:0]state;
  reg [INSTR_WIDTH-1:0]load_reg,store_reg,comp_reg;
  integer i,count,temp,count_cop;//newly added
  
 
  localparam idle=0;
  localparam catch=1;
  localparam check=2;
  localparam transfer=3;
  localparam req_dummy=4;//newly added becasue ifu cant read the immediate read request
  
  always @(posedge clk)
    begin
      if(!rst)
        begin
          {load_reg,store_reg,comp_reg}<=0;
          internal_reg<=0;
          int_reg <= 0;
          state<=idle; 
          idu2ifu_rd_rqst<=0;
          load_wr_en <= 'b0;
          comp_wr_en <= 'b0;
          store_wr_en <= 'b0;
          i<=0;
          store_data <= 0;
          comp_data <= 0;
          load_data <= 0;
          count<=0;
          temp<=0;
         // count_cop<=0;
        end
      else
        case(state)
          idle:if(ifu2idu_fifo_empty==1)
            begin
            state<=idle;
            {store_wr_en,load_wr_en,comp_wr_en}<=0;
            end
          else
            begin
              state<=catch;
              idu2ifu_rd_rqst<=1;
              {store_wr_en,load_wr_en,comp_wr_en}<=0;
            end
       
          catch:begin
            if(ifu2idu_rd_data_vld) begin
              int_reg<=ifu2idu_rd_data;
              state<=check;
              idu2ifu_rd_rqst<=1;
            end
            else begin
            state<= catch;
              idu2ifu_rd_rqst<=0;
          end
          end  
          
          req_dummy: begin
            state<=check;            
            idu2ifu_rd_rqst<=1;
          end
          
          check: begin
            idu2ifu_rd_rqst<=0;
            case(int_reg[7:0])
            8'h01:begin 
              if(i==0 && ifu2idu_rd_data_vld)
                begin
                internal_reg[63:0]<=ifu2idu_rd_data;
              	i<=i+1;
              	state<=req_dummy;
                idu2ifu_rd_rqst<=0;
              end
              else if(i==1 && ifu2idu_rd_data_vld)
                begin
                  internal_reg[127:64]<=ifu2idu_rd_data;
                  i<=0;
                  state<=transfer;
                  idu2ifu_rd_rqst<=0;
                end
            end
              
            8'h10:begin
              if(i==0 && ifu2idu_rd_data_vld)
                begin
                internal_reg[63:0]<=ifu2idu_rd_data;
                 
              	i<=i+1;
              	state<=req_dummy;
                idu2ifu_rd_rqst<=0;
              end
              else if(i==1 && ifu2idu_rd_data_vld)
                begin
                  internal_reg[127:64]<=ifu2idu_rd_data;
                  i<=i+1;
                  state<=req_dummy;
                  idu2ifu_rd_rqst<=0;
                end
              else if(i==2 && ifu2idu_rd_data_vld)
                begin
                  internal_reg[191:128]<=ifu2idu_rd_data;
                  i<=0;
                  state<=transfer;
                  idu2ifu_rd_rqst<=0;
                end
            end
            8'h11:begin 
              if(i==0 && ifu2idu_rd_data_vld)
                begin
                internal_reg[63:0]<=ifu2idu_rd_data;
              	i<=i+1;
              	state<=req_dummy;
                idu2ifu_rd_rqst<=0;
              end
              else if(i==1 && ifu2idu_rd_data_vld)
                begin
                  internal_reg[127:64]<=ifu2idu_rd_data;
                  i<=0;
                  state<=transfer;
                  idu2ifu_rd_rqst<=0;
                end
            end
            default: state<=check;
          endcase
          end
          
          transfer:begin
            idu2ifu_rd_rqst<=0;
            case(int_reg[7:0])
            8'h01:begin
              if(load_full==1)
                begin
                load_reg<={internal_reg,int_reg};
                state<=transfer;
                 
                end
              else if(load_full==0)
                begin
                 if(load_reg!=0)
                   begin
                   load_wr_en<=1;
                   load_data<=load_reg;
                   state<=idle;
                   end
                 else
                   begin
                   load_wr_en<=1;
                     load_data<={internal_reg,int_reg};
                     temp<=1;
                  state<=idle;
                   end
                end
            end
            8'h10:begin 
              if(comp_full==1)
                begin
                comp_reg<={internal_reg,int_reg};
                state<=transfer;
                end
              else if(comp_full==0)
                begin
                  if(comp_reg!=0)
                   begin
                   comp_wr_en<=1;
                   comp_data<=comp_reg;
                   state<=idle;
                   end
                 else
                   begin
                   comp_wr_en<=1;
                   comp_data<= {internal_reg,int_reg};
                   state<=idle;
                   end
                end
            end
              
            8'h11:begin 
              if(store_full==1)
                begin
                store_reg<={internal_reg,int_reg};
                state<=transfer;
                end
              else if(store_full==0)
                begin
                  if(store_reg!=0)
                   begin
                   store_wr_en<=1;
                   store_data<=store_reg;
                   state<=idle;
                   end
                  else
                    begin
                    store_wr_en<=1;
                    store_data<={internal_reg,int_reg};
                    state<=idle;
                    end
                end
            end
              
            default: state<=transfer;
          endcase
          end
          default:state<=idle;
        endcase   
       
    end
  always @(posedge clk)begin   
  if(!rst)
  begin
  start_load<=1;
      start_compute<=1;
      start_store<=1;
      count_cop  <= 0;
  end 
    else if(count==1)begin
      start_load<=0;
      start_compute<=1;
      start_store<=1;
    end
    else if(count==2)begin
      start_compute<=1;
      start_store<=1;
      start_load<=1;
    end
    else if(count==3)begin
      
      if(count_cop<='d10)
        begin
         	start_compute<=0;
			start_store<=1;
			start_load<=1;
          count_cop<=count_cop+1;
        end
      
      else
        begin
         	start_compute<=1;
			start_store<=1;
			start_load<=1;
          count_cop<='d14;
        end
    end
    else if(count==4)begin
      start_store<=0;
      start_load<=1;
      start_compute<=1;
    end
      
  end
  always @(posedge clk)begin
  if(!rst)
  begin
  count <= 'b0;
  end
    else if(dfu_lsc_done||(temp==1&&count==0))begin      
      count<=count+1;end
    else if(count==5) begin
      count<=0;
    end
    else 
    count <= count;
      
  end
  
endmodule
