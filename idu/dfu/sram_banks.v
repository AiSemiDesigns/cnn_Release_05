`include "sram.v"

module sram_banks (
    input  wire                    clk,
    input  wire                    rst,
    input  wire [AXI_DATA_WIDTH-1:0] ar2dfu_data_in,
    input  wire                    wr_a_en,
    input  wire                    wr_b_en,
    input  wire [sram_addr-1:0] wr_a_addr,
    input  wire [sram_addr-1:0] wr_b_addr,
    input  wire                    dfu2ip_a_sram_rd_en[0:no_of_sram_banks-1],
    input  wire                    dfu2ip_b_sram_rd_en[0:no_of_sram_banks-1],
    input  wire [sram_addr-1:0] dfu2ip_a_sram_rd_addr[0:no_of_sram_banks-1],
    input  wire [sram_addr-1:0] dfu2ip_b_sram_rd_addr[0:no_of_sram_banks-1],

    output reg  [Es-1:0]           dfu2op_bank_a_sram_data_out[0:no_of_sram_banks-1],
    output reg                     dfu2op_bank_a_sram_data_out_vld[0:no_of_sram_banks-1],
    output reg  [Es-1:0]           dfu2op_bank_b_sram_data_out[0:no_of_sram_banks-1],
    output reg                     dfu2op_bank_b_sram_data_out_vld[0:no_of_sram_banks-1]
);

    // Generate block for Bank A SRAM instances
    genvar i;
    generate
        for (i = 0; i < no_of_sram_banks; i = i + 1) begin : bank_a_gen
            sram bank_a_inst (
                .clk                       (clk),
                .rst                       (rst),
                .bank_data_in              (ar2dfu_data_in[(i+1)*Es-1:i*Es]),
                .wr_en                     (wr_a_en),
                .wr_addr                   (wr_a_addr),
                .dfu2ip_sram_rd_en         (dfu2ip_a_sram_rd_en[i]),
                .dfu2ip_sram_rd_addr       (dfu2ip_a_sram_rd_addr[i]),
                .dfu2op_bank_sram_data_out (dfu2op_bank_a_sram_data_out[i]),
                .dfu2op_bank_sram_data_out_vld (dfu2op_bank_a_sram_data_out_vld[i])
            );
        end
    endgenerate

    // Generate block for Bank B SRAM instances
    genvar j;
    generate
        for (j = 0; j < no_of_sram_banks; j = j + 1) begin : bank_b_gen
            sram bank_b_inst (
                .clk                       (clk),
                .rst                       (rst),
                .bank_data_in              (ar2dfu_data_in[(j+1)*Es-1:j*Es]),
                .wr_en                     (wr_b_en),
                .wr_addr                   (wr_b_addr),
                .dfu2ip_sram_rd_en         (dfu2ip_b_sram_rd_en[j]),
                .dfu2ip_sram_rd_addr       (dfu2ip_b_sram_rd_addr[j]),
                .dfu2op_bank_sram_data_out (dfu2op_bank_b_sram_data_out[j]),
                .dfu2op_bank_sram_data_out_vld (dfu2op_bank_b_sram_data_out_vld[j])
            );
        end
    endgenerate

endmodule

