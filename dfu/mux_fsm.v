`include "top_mux.v"

module mux_fsm(
  input  wire                      clk,
  input  wire                      rst,
  input  wire [Es-1:0]             dfu2op_a_sram_data_out [0:no_of_sram_banks-1],
  input  wire [Es-1:0]             dfu2op_b_sram_data_out [0:no_of_sram_banks-1],
  input  wire                      dfu2op_a_sram_data_out_vld [0:no_of_sram_banks-1],
  input  wire                      dfu2op_b_sram_data_out_vld [0:no_of_sram_banks-1],
  output   [Es-1:0]             dfu2sys_data_out_a      [0:no_of_sram_banks-1],
  output                        dfu2sys_data_vld_a      [0:no_of_sram_banks-1],
  output   [Es-1:0]             dfu2sys_data_out_b      [0:no_of_sram_banks-1],
  output                        dfu2sys_data_vld_b      [0:no_of_sram_banks-1],
  input dfu2mux_rd_en
);

  reg [10:0] clk_count_a;                        // Counter for clock cycles
  reg [sel_sram_bank_bits-1:0] sram_bank_sel_counter [0:no_of_sram_banks-1];

  reg [Es-1:0] a_sram_data_out [0:no_of_sram_banks-1];
  reg [no_of_sel_ln-1:0] mux_a_sel [0:no_of_sram_banks-1];
  reg [Es-1:0] b_sram_data_out [0:no_of_sram_banks-1];
  reg [no_of_sel_ln-1:0] mux_b_sel [0:no_of_sram_banks-1];
  reg ack_start_sys_a[0:no_of_sram_banks-1];
  reg ack_start_sys_b[0:no_of_sram_banks-1];

  //........................testing purpose..............................
  wire [sel_sram_bank_bits-1:0] sram_bank_sel_counter_temp ;
  assign sram_bank_sel_counter_temp = sram_bank_sel_counter[0];


  wire  ack_start_sys_b_temp;

  assign ack_start_sys_b_temp = ack_start_sys_b [0];

  //........................testing purpose..............................



  // Instantiate top_mux
  top_mux DUT (
    .clk(clk),
    .rst(rst),
    .dfu2op_a_sram_data_out(a_sram_data_out),
//     .dfu2op_b_sram_data_out_vld(dfu2op_b_sram_data_out_vld),
//     .dfu2op_a_sram_data_out_vld(dfu2op_a_sram_data_out_vld),
    .top_mux_a_sel(mux_a_sel),
    .dfu2sys_data_out_a(dfu2sys_data_out_a),
    .dfu2sys_data_vld_a(dfu2sys_data_vld_a),
    .dfu2op_b_sram_data_out(b_sram_data_out),
    .top_mux_b_sel(mux_b_sel),
    .dfu2sys_data_out_b(dfu2sys_data_out_b),
    .dfu2sys_data_vld_b(dfu2sys_data_vld_b),
    .ack_start_sys_a(ack_start_sys_a),
    .ack_start_sys_b(ack_start_sys_b)
  );

  // Update SRAM data and multiplexers on every clock edge
  always@(*)
    begin
      for (integer i=0;i<no_of_sram_banks;i=i+1) begin
        a_sram_data_out[i] = dfu2op_a_sram_data_out[i];
        b_sram_data_out[i] = dfu2op_b_sram_data_out[i];
      end
    end

  //   always @(*) begin
  //     for (integer i = 0; i < no_of_sram_banks; i = i + 1) begin
  //       for (integer j = 0; j < no_of_sram_banks; j = j + 1) begin
  //         //         a_sram_data_out[j][i] = dfu2op_a_sram_data_out[j];
  //         b_sram_data_out[j][i] = dfu2op_b_sram_data_out[j];
  //       end
  //     end
  //   end

  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      // Reset state
      clk_count_a <= 0;
      for (integer i = 0; i < no_of_sram_banks; i = i + 1) begin
        mux_a_sel[i] <= {no_of_sel_ln{1'b0}};
        mux_b_sel[i] <= {no_of_sel_ln{1'b0}};
        sram_bank_sel_counter[i] <= 0;
        ack_start_sys_a[i] <= 0;
        ack_start_sys_b[i] <= 0;
      end
    end else begin
      //       if (dfu2op_a_sram_data_out_vld[0] || dfu2op_b_sram_data_out_vld[no_of_sram_banks-1]) begin
      if(dfu2mux_rd_en) begin
        if (clk_count_a < (El_RC + (ROW - 1))) begin
          for (integer i = 0; i < ROW; i = i + 1) begin
            if (i <= clk_count_a && clk_count_a < (El_RC + i)) begin
              mux_a_sel[i] <= sram_bank_sel_counter[i];
              mux_b_sel[i] <= i;
              ack_start_sys_a[i] <= 1;
              ack_start_sys_b[i] <= 1;
              sram_bank_sel_counter[i] <= sram_bank_sel_counter[i] + 1;
            end else begin
              mux_a_sel[i] <= {no_of_sel_ln{1'b0}};
              mux_b_sel[i] <= {no_of_sel_ln{1'b0}};
              ack_start_sys_a[i] <= 0;
              ack_start_sys_b[i] <= 0;
            end
          end
          clk_count_a <= clk_count_a + 1;
        end else begin
          for (integer i = 0; i < ROW; i = i + 1) begin
            mux_a_sel[i] <= {no_of_sel_ln{1'b0}};
            mux_b_sel[i] <= {no_of_sel_ln{1'b0}};
            ack_start_sys_a[i] <= 0;
            ack_start_sys_b[i] <= 0;
          end
          clk_count_a <= 0;
        end
      end
      else begin
        for (integer i = 0; i < ROW; i = i + 1) begin
          mux_a_sel[i] <= {no_of_sel_ln{1'b0}};
          mux_b_sel[i] <= {no_of_sel_ln{1'b0}};
          ack_start_sys_a[i] <= 0;
          ack_start_sys_b[i] <= 0;
        end
        clk_count_a <= 0;
      end
    end
  end


endmodule

