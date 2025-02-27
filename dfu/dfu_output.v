module dfu_output (
  input clk,
  input rst,
  input idu2dfu_compute_fifo_empty,
  output reg dfu2idu_compute_instr_req,
  input [INSTR_WIDTH-1:0] idu2dfu_compute_instr,
  input idu2dfu_compute_instr_vld,
  output reg [sram_addr-1:0] dfu2ip_a_sram_rd_addr[0:no_of_sram_banks-1],
  output reg dfu2ip_a_sram_rd_en[0:no_of_sram_banks-1],
  output reg dfu2ip_b_sram_rd_en[0:no_of_sram_banks-1],
  output reg [sram_addr-1:0] dfu2ip_b_sram_rd_addr[0:no_of_sram_banks-1],
  output dfu2mux_rd_en
);

  reg [sel_sram_bank_bits-1:0] dfu2ip_a_sel_sram[0:no_of_sram_banks-1];
  reg [sel_sram_bank_bits-1:0] dfu2ip_b_sel_sram[0:no_of_sram_banks-1];

  reg [4:0] state; 
  reg [FIFO_WIDTH-1:0] start_addr_a, start_addr_b, start_addr_c;
  reg [10:0] clk_count, clk_count_b;
  reg [sel_sram_bank_bits-1:0] sram_bank_sel_counter[0:no_of_sram_banks-1];
  //  reg [sel_sram_bank_bits-1:0] bank_inc[0:no_of_sram_banks-1];
  reg [sram_addr-1:0] sram_b_addr[0:no_of_sram_banks-1];
  reg [sram_addr-1:0] a_rd_addr_temp[0:no_of_sram_banks-1];
  reg [sel_sram_bank_bits-1:0]inc_addr[0:no_of_sram_banks-1];

  parameter idel=5'd0, com_req_idu=5'd1, com_fetch_idu=5'd2, req_sram_data=5'd3;



  always @(posedge clk) begin
    if (!rst) begin
      state <= idel;
      dfu2idu_compute_instr_req <= 0;

      start_addr_a <= 0;
      start_addr_b <= 0;
      start_addr_c <= 0;
      clk_count <= 0;
      clk_count_b <= 0;
      for (integer i = 0; i < no_of_sram_banks; i = i + 1) begin
        dfu2ip_a_sel_sram[i] <= 'b0;
        dfu2ip_b_sel_sram[i] <= 'b0;
        dfu2ip_a_sram_rd_addr[i] <= {sram_addr{1'b0}};
        dfu2ip_a_sram_rd_en[i] <= 0;
        dfu2ip_b_sram_rd_en[i] <= 0;
        dfu2ip_b_sram_rd_addr[i] <= {sram_addr{1'b0}};
        sram_bank_sel_counter[i] <= 0;
        //  bank_inc[i] <= 0;
        sram_b_addr[i] <= {sram_addr{1'b0}};
        a_rd_addr_temp[i]<={sram_addr{1'b0}};
        inc_addr[i]<={sram_addr{1'b0}};
        //         a_rd_addr_temp[i]<=((El_RC/no_of_sram_banks)*i);
      end
    end else begin
      case (state)
        idel: begin
          if (!idu2dfu_compute_fifo_empty) begin
            state <= com_req_idu;
          end
        end
        com_req_idu: begin
          dfu2idu_compute_instr_req <= 1;
          state <= com_fetch_idu;
        end
        com_fetch_idu: begin
          if (idu2dfu_compute_instr_vld) begin
            start_addr_a[FIFO_WIDTH-1:0] <= idu2dfu_compute_instr[(2*FIFO_WIDTH)-1:FIFO_WIDTH];
            start_addr_b[FIFO_WIDTH-1:0] <= idu2dfu_compute_instr[(3*FIFO_WIDTH)-1:(2*FIFO_WIDTH)];
            start_addr_c[FIFO_WIDTH-1:0]  <= idu2dfu_compute_instr[(4*FIFO_WIDTH)-1:(3*FIFO_WIDTH)];
            state <= req_sram_data;
            dfu2idu_compute_instr_req <= 0;
          end
        end
        req_sram_data: begin
//           if (dfu2op_a_sram_data_out_vld[0])
          if (clk_count < (El_RC + (ROW - 1))) begin
            for (integer i = 0; i < ROW; i = i + 1) begin
              if (i <= clk_count && clk_count < (El_RC + i)) begin
                dfu2ip_a_sram_rd_addr[i] <= a_rd_addr_temp[i]+inc_addr[i];
                dfu2ip_a_sram_rd_en[i] = 1;
                dfu2ip_a_sel_sram[i] = sram_bank_sel_counter[i];
                a_rd_addr_temp[i]<=(El_RC/no_of_sram_banks)+a_rd_addr_temp[i];
                if ((a_rd_addr_temp[i] + (El_RC/no_of_sram_banks)) == sram_locations)                   
                  inc_addr[i]<=inc_addr[i]+1'b1;
                sram_bank_sel_counter[i] = sram_bank_sel_counter[i] + 1'b1;
              end
              else begin
                dfu2ip_a_sram_rd_addr[i] = {sram_addr{1'b0}};
                dfu2ip_a_sram_rd_en[i] = 0;
                dfu2ip_a_sel_sram[i] = {sel_sram_bank_bits{1'b0}};
              end
            end
            //               for(integer i=0;i<ROW;i=i+1)
            //                 begin
            //                   inc_addr[i]<=inc_addr[i]+1'b1;
            //                 end
            clk_count <= clk_count + 1'b1;
          end else begin
            state <= idel;
            clk_count <= 0;
            for (integer i = 0; i < ROW; i = i + 1) begin
              dfu2ip_a_sram_rd_addr[i] <= {sram_addr{1'b0}};
              dfu2ip_a_sram_rd_en[i] <= 0;
              dfu2ip_a_sel_sram[i] <= {sel_sram_bank_bits{1'b0}};
            end
          end

          if (clk_count_b < (El_RC + (COL - 1))) begin
            for (integer i = 0; i < COL; i = i + 1) begin
              if (i <= clk_count_b && clk_count_b < (El_RC + i)) begin
                dfu2ip_b_sram_rd_addr[i] = sram_b_addr[i];
                dfu2ip_b_sram_rd_en[i] = 1;
                dfu2ip_b_sel_sram[i] = i;
                sram_b_addr[i] = sram_b_addr[i] + 1'b1;
              end else begin
                dfu2ip_b_sram_rd_addr[i] = {sram_addr{1'b0}};
                dfu2ip_b_sram_rd_en[i] = 0;
                dfu2ip_b_sel_sram[i] = {sel_sram_bank_bits{1'b0}};
              end
            end
            clk_count_b <= clk_count_b + 1'b1;
          end else begin
            //state <= idel;
            //clk_count <= 0;
            clk_count_b <= 0;
            for (integer i = 0; i < COL; i = i + 1) begin
              dfu2ip_b_sram_rd_addr[i] <= {sram_addr{1'b0}};
              dfu2ip_b_sram_rd_en[i] <= 0;
              dfu2ip_b_sel_sram[i] <= {sel_sram_bank_bits{1'b0}};
            end
          end
        end
        default : state <= idel;
      endcase
    end
  end
  
  assign dfu2mux_rd_en = (state == req_sram_data ) && (clk_count < (El_RC + (ROW - 1))) ? 1:0;
endmodule

