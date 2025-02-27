module ifu_fsm(clk,
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
           ar2ifu_wr_adata,
		   ar2ifu_wr_avalid,
		   ar2ifu_wr_adone,
           ifu2ar_grant_rqst,
           ar2ifu_grant,//newly added
		   idu2ifu_rd_rqst,
           fifo_wr_data,
           fifo_full,
           fifo_empty,
           fifo_wr_en,
           fifo_rd_en,
           threshold
		   );
  
  

  

  
  input clk,rstn;
  
  //////////////////////////// to cu via arbiter/////////////
  
  input [DATA_WIDTH-1:0]ar2ifu_data_in;
  input ar2ifu_data_in_valid;
  input ar2ifu_start_wl;
  input ar2ifu_ack;
  output reg ifu2ar_rd_rqst;
  output reg  ifu2ar_wr_rqst;
  output reg [DATA_WIDTH-1:0]ifu2ar_data_out;
  output reg ifu2ar_data_out_valid;
  output reg [ADDR_WIDTH-1:0] ifu2ar_addr;
  output reg ifu2ar_addr_valid;
  
  
  /////////////////////// from axi via arbiter //////////////////
  input [FIFO_WIDTH-1:0] ar2ifu_wr_adata;
  input ar2ifu_wr_avalid;
  input ar2ifu_wr_adone;
  output reg ifu2ar_grant_rqst;
  input ar2ifu_grant;//newly added
  
  /////////////////////////// idu ////////////////////
  input idu2ifu_rd_rqst;  
  //////////////////////////// interrupt ////////////////
  
  output reg ifu2ar_interrupt;
  output reg ifu2ar_maskable_interrupt;
  
  
  input fifo_full;
  input fifo_empty;
  output reg fifo_wr_en,fifo_rd_en;
  input threshold;
  output reg [FIFO_WIDTH-1:0]fifo_wr_data;
  
  reg [31:0]threshold_value=(FIFO_LENGTH/4);  
  reg [5:0]state;
  
  reg [DATA_WIDTH-1:0] prog_size;
  reg [ADDR_WIDTH-1:0] prog_start_addr;
  
  reg [ADDR_WIDTH-1:0] rqst_size;
  reg [ADDR_WIDTH-1:0] rqst_source_addr;
  reg [ADDR_WIDTH-1:0] rqst_dest_addr;
  
  
  reg [10:0]total_rqst;
  reg [10:0]loop_counter;
  
  integer i;

  parameter IDLE=6'd1,CONFIG_READ=6'd2,CONFIG_OPERATION=6'd3,CONFIG_WRITE=6'd4,FIFO_WRITE=6'd5,FIFO_READ=6'd6;
  
  always@(posedge clk)
    if(!rstn) begin
      ifu2ar_rd_rqst<=0;
      ifu2ar_wr_rqst<=0;
      ifu2ar_data_out<=0;
      ifu2ar_data_out_valid<=0;
      ifu2ar_addr<=0;
      ifu2ar_addr_valid<=0;
      ifu2ar_grant_rqst<=1;
      ifu2ar_interrupt<=0;
      ifu2ar_maskable_interrupt<=0;
      prog_size<=0;
      prog_start_addr<=0;
      rqst_size<=0;
      rqst_source_addr<=0;
      rqst_dest_addr<=0;
      total_rqst<=0;
      loop_counter<=0;
      fifo_wr_en<=0;
      fifo_rd_en<=0;
      fifo_wr_data<=0;
      i<=0;
      
      state<=IDLE;
    end
  else 
    case(state)
      
      //idle----------------------------------------------------------------------------=
      
      IDLE:begin
          ifu2ar_interrupt<=0;
          ifu2ar_maskable_interrupt<=0;
        if(ar2ifu_start_wl == 1) begin//need to stop second itteration untill entaire operation complete
          state<=CONFIG_READ;
          ifu2ar_grant_rqst<=1;
        end
      end
      
      
   //config_read-------------------------------------------------------------------------
      
      CONFIG_READ:begin 
        ifu2ar_interrupt<=0;
        ifu2ar_maskable_interrupt<=0;
        if(|prog_size == 0 &&ar2ifu_grant)
          begin
            
            ifu2ar_rd_rqst<=1;
            ifu2ar_addr_valid<=1;
            ifu2ar_addr<=config_read_start_addr;
            if(ar2ifu_data_in_valid && ifu2ar_addr== config_read_start_addr) begin
                prog_size<=ar2ifu_data_in;
            	state<=CONFIG_READ;
                ifu2ar_addr_valid<=0;
                ifu2ar_rd_rqst<=0;     //if rd_rqst is continuously high data in repeated previous value
            end
          end
      
        else if(|prog_start_addr == 0&&ar2ifu_grant)
          begin
           
            ifu2ar_rd_rqst<=1;
            ifu2ar_addr_valid <= 1;
            ifu2ar_addr<=config_read_start_addr+2;
            if(ar2ifu_data_in_valid && ifu2ar_addr== config_read_start_addr+2) 
              begin
            	prog_start_addr<=ar2ifu_data_in;
               
                ifu2ar_rd_rqst<=0;
                ifu2ar_addr_valid <= 0;
                state<=CONFIG_OPERATION;
            end
          end
        else
          state<=state;
      end
      
      //config_operation-------------------------------------------------------------------
 
      CONFIG_OPERATION:begin
       
        
        ifu2ar_interrupt<=0;
        
        if(total_rqst == 0) begin
          if(prog_size < FIFO_LENGTH)
            total_rqst<=1;
          else 
            total_rqst<=((prog_size-FIFO_LENGTH)/(FIFO_LENGTH-threshold_value))+1;
        end
        else if(loop_counter < total_rqst)
          begin
            if(loop_counter==0)
              begin 
                if(prog_size < FIFO_LENGTH)
                  begin
                    rqst_size<=prog_size;
                    rqst_source_addr <=prog_start_addr ;
                    rqst_dest_addr<=dummy_addr;
                    state<=CONFIG_WRITE;
                    ifu2ar_maskable_interrupt<=0;
                  end
                else begin
                   rqst_size<=FIFO_LENGTH;
                    rqst_source_addr <= prog_start_addr;
                    rqst_dest_addr<=dummy_addr;
                    state<=CONFIG_WRITE;
                    ifu2ar_maskable_interrupt<=0;
                end
                
              end
            else
              begin
                rqst_size<=FIFO_LENGTH-threshold_value;
                rqst_source_addr <=rqst_source_addr +rqst_size;
                rqst_dest_addr<=dummy_addr;
                state<=CONFIG_WRITE;
                ifu2ar_maskable_interrupt<=0;
              end
      end
        else if(total_rqst == loop_counter) begin
          ifu2ar_maskable_interrupt<=1;
          total_rqst<=0;
          state<=IDLE;
        end
      end
      
      
      
      //config_write--------------------------------------------------------------------------
      
        CONFIG_WRITE:begin
             
            if(ar2ifu_ack) begin
                ifu2ar_addr_valid<=0;
                ifu2ar_data_out_valid<=0;
                ifu2ar_interrupt<=1;
                ifu2ar_maskable_interrupt<=0;
                i<=0;
                ifu2ar_wr_rqst<=0;
                state<=FIFO_WRITE;
              end
             else if(i==0) begin
                ifu2ar_wr_rqst<=1;
                ifu2ar_addr<=config_write_start_addr;
                ifu2ar_addr_valid <= 1;
                ifu2ar_data_out_valid<=1;
                ifu2ar_data_out <= rqst_size;

                state<=CONFIG_WRITE;
                i=i+1;
              end
          
              else if(i==1)
                begin
                  ifu2ar_wr_rqst<=1;
                  ifu2ar_addr<=config_write_start_addr+2;
                  ifu2ar_addr_valid <= 1;
                  ifu2ar_data_out <= rqst_source_addr;
                  state<=CONFIG_WRITE;
                  i=i+1;
                end
          
              else if(i==2)
                begin
                  ifu2ar_wr_rqst<=1;
                  ifu2ar_addr<=config_write_start_addr+4;
                  ifu2ar_addr_valid <= 1;
                  ifu2ar_data_out <= rqst_dest_addr;
                  state<=CONFIG_WRITE;
                  ifu2ar_interrupt <= 0;
      			  ifu2ar_maskable_interrupt <= 0;
                  loop_counter<=loop_counter+1;
                  i<=i+1;
                end
            end
        
        //fifo_write-------------------------------------------------------------------------

      FIFO_WRITE:begin
        
        ifu2ar_interrupt<=0;
        ifu2ar_maskable_interrupt<=0;
        
        if(ar2ifu_wr_adone) begin
          if(idu2ifu_rd_rqst)
            begin
              state<=FIFO_READ;
              fifo_wr_en<=1;
              fifo_wr_data<=ar2ifu_wr_adata;
              fifo_rd_en<=1;
            end
          else begin
            fifo_wr_en<=1;
            fifo_wr_data<=ar2ifu_wr_adata;
            fifo_rd_en<=0;
            state<=FIFO_READ;
          end
        end
            
        
        else if(idu2ifu_rd_rqst==1 && ar2ifu_wr_avalid && !fifo_full) begin

          state<=FIFO_WRITE;
          fifo_wr_en<=1;
          fifo_wr_data<=ar2ifu_wr_adata;
          fifo_rd_en<=1;
        end
  
        else if(!fifo_full && ar2ifu_wr_avalid) begin
            fifo_wr_en<=1; 
            fifo_wr_data<=ar2ifu_wr_adata;
          	fifo_rd_en<=0;
           	state<=FIFO_WRITE;
          end
        
      else if(idu2ifu_rd_rqst==1) begin

          state<=FIFO_WRITE;
          fifo_rd_en<=1;
        end

        else begin
        fifo_wr_en<=0;
        fifo_rd_en<=0;
        state<=FIFO_WRITE;
      end
      end
        
      //fifo_read----------------------------------------------------------------------------
          
     FIFO_READ:begin
       ifu2ar_grant_rqst<=0;
       ifu2ar_interrupt<=0;
       ifu2ar_maskable_interrupt<=0;
       
       if(idu2ifu_rd_rqst) 
         begin
          if(threshold) 
            begin
            if((total_rqst > loop_counter))
              begin
                fifo_rd_en<=0;
                fifo_wr_en<=0;
                state<=CONFIG_OPERATION;
              end
            else
              begin
                fifo_rd_en<=1;
                fifo_wr_en<=0;

                state<=CONFIG_OPERATION;
              end
          end
          else
            begin
              if(fifo_empty)
                begin
                  fifo_rd_en<=0;
                  fifo_wr_en<=0;

                  state<=CONFIG_OPERATION;
                end
              else
                begin
                  fifo_rd_en<=1;
                  fifo_wr_en<=0;
                  state<=FIFO_READ;
                  
                end
            end
        end
        else begin
          if(fifo_empty) begin
            
            state<=CONFIG_OPERATION;end
          else
            begin
              fifo_rd_en<=0;
            fifo_wr_en<=0;
            state<=FIFO_READ;
             
            end
          end
     end
      
      //default--------------------------------------------------------------------------------
              
       default:state<=IDLE;
        
    endcase

  
endmodule
