module store_inst (
  input clk,
  input rst,
  input idu2dfu_store_fifo_empty,
  output reg dfu2idu_store_instr_req,
  input [INSTR_WIDTH-1:0] idu2dfu_store_instr,
  input idu2dfu_store_instr_vld,
  output reg dfu2ar_grant_req,
  input ar2dfu_grant,
  output reg dfu2ar_rd_req,
  output reg [FIFO_WIDTH-1:0] dfu2ar_rd_addr,
  output reg dfu2ar_rd_addr_vld,
  output reg [FIFO_WIDTH-1:0] dfu2ar_rd_data_out,
  output reg dfu2ar_rd_data_out_vld,
  input ar2dfu_ack,
  input ack_sram_c_rd, // Read operation done from SRAM
  output reg dfu2idu_store_done,
  output reg dfu2ar_read_interrupt
);
  reg [4:0] state; 
  reg [FIFO_WIDTH-1:0] sram_addr;
  reg [FIFO_WIDTH-1:0] dram_addr, dram_addr_temp;
  integer i, k, j;
  
  // State definitions
  parameter idel = 5'd0,
            store_req_idu = 5'd1,
            store_fetch_idu = 5'd2,
            req_arb_wr_cu = 5'd3,
            wait_ack_sram = 5'd4;

  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      // Reset state and outputs
      state <= idel;
      dfu2idu_store_instr_req <= 0;
      dfu2ar_grant_req <= 0;
      i <= 0;
      k <= 0;
      j <= 0;
      sram_addr <= 0;
      dram_addr <= 0;
      dfu2idu_store_done <= 0;
      dram_addr_temp <= 0;
      dfu2ar_rd_req <= 0;
      dfu2ar_rd_addr <= 0;
      dfu2ar_rd_addr_vld <= 0;
      dfu2ar_rd_data_out <= 0;
      dfu2ar_rd_data_out_vld <= 0;
      dfu2ar_read_interrupt<=0;
    end else begin
      case(state)
        idel: begin                
          if (!idu2dfu_store_fifo_empty) begin
            state <= store_req_idu;
          end
          dfu2idu_store_done <= 0;
          dfu2ar_grant_req <= 0;
          i <= 0;
          k <= 0;
          j <= 0;
          sram_addr <= 0;
         // dram_addr <= 0;
          dram_addr_temp <= 0;
        end

        store_req_idu: begin
          dfu2idu_store_instr_req <= 1;
          state <= store_fetch_idu;
        end

        store_fetch_idu: begin
          dfu2idu_store_instr_req <= 0;
          if (idu2dfu_store_instr_vld) begin
            sram_addr <= idu2dfu_store_instr[(2*FIFO_WIDTH)-1:FIFO_WIDTH];
          //  dram_addr <= idu2dfu_store_instr[(3*FIFO_WIDTH)-1:(2*FIFO_WIDTH)];
            dram_addr_temp <= idu2dfu_store_instr[(3*FIFO_WIDTH)-1:(2*FIFO_WIDTH)];
            state <= req_arb_wr_cu;
            dfu2ar_grant_req <= 1;
          end        
        end

        req_arb_wr_cu: begin
          dfu2idu_store_instr_req <= 0;
          if (ar2dfu_grant) begin
          if (ar2dfu_ack) begin
              dfu2ar_rd_req <= 0;
              dfu2ar_rd_addr <= 0;
              dfu2ar_rd_addr_vld <= 0;
              dfu2ar_rd_data_out <= 0;                   
              state <= wait_ack_sram;
              dfu2ar_rd_data_out_vld <= 0;
              i <= 0;
              dfu2ar_read_interrupt<=1;
            end
            else if (i == 0) begin
              dfu2ar_rd_req <= 1;
              dfu2ar_rd_addr <= cu_length; // lenght
              dfu2ar_rd_addr_vld <= 1;
              dfu2ar_rd_data_out <=ROW ;
             // k <= k + 1;
              i <= i + 1;
              dfu2ar_rd_data_out_vld <= 1;end
              else if (i == 1) begin
              dfu2ar_rd_req <= 1;
              dfu2ar_rd_addr <= cu_sram_addr; // SRAM address
              dfu2ar_rd_addr_vld <= 1;
              dfu2ar_rd_data_out <= k;
              dfu2ar_rd_data_out_vld <= 1;
              k <= k + 1;
              i <= i + 1;
              
              end else if (i == 2) begin
              dfu2ar_rd_req <= 1;
              dfu2ar_rd_addr <= cu_dram_addr; // DRAM address
              dfu2ar_rd_addr_vld <= 1;
              dfu2ar_rd_data_out <= dram_addr_temp + j;                    
              j <= C_El - ROW; // Example value, adjust as needed
              dram_addr_temp <= dfu2ar_rd_data_out;
              dfu2ar_rd_data_out_vld <= 1;
            end
          end
        end

        wait_ack_sram: begin
          dfu2ar_read_interrupt<=0;
          if (ack_sram_c_rd && (k < ROW )) begin
            state <= req_arb_wr_cu;
            dfu2ar_read_interrupt<=0;
          end else if (k == ROW - 1 && ack_sram_c_rd) begin
            state <= idel;
            dfu2idu_store_done <= 1;
             dfu2ar_read_interrupt<=0;
          end
        end

        default: state <= idel;
      endcase
    end
  end
endmodule

