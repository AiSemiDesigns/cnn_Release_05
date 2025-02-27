`include "dfu_ip_fsm.v"
`include "sram_banks.v"

module dfu_ip_top (
    input  wire                    clk,
    input  wire                    rst,
    input  wire                    idu2dfu_load_fifo_empty,
    input  wire [INSTR_WIDTH-1:0]  idu2dfu_load_instr,
    input  wire                    idu2dfu_load_instr_vld,
    input  wire                    ar2dfu_ack,
    input  wire [AXI_DATA_WIDTH-1:0] ar2dfu_data_in,
    input  wire                    ar2dfu_data_in_vld,
    input  wire                    ar2dfu_ack_data_done,
    input  wire                    dfu2ip_a_sram_rd_en[0:no_of_sram_banks-1],
    input  wire [sram_addr-1:0] dfu2ip_a_sram_rd_addr[0:no_of_sram_banks-1],
    input  wire                    dfu2ip_b_sram_rd_en[0:no_of_sram_banks-1],
    input  wire [sram_addr-1:0] dfu2ip_b_sram_rd_addr[0:no_of_sram_banks-1],

    output reg                     dfu2idu_load_instr_req,
    output reg                     dfu2ar_grant_req,
    input  wire                    ar2dfu_grant,
    output reg                     dfu2ar_wr_req,
    output reg [FIFO_WIDTH-1:0]    dfu2ar_addr,
    output reg                     dfu2ar_addr_vld,
    output reg [DATA_WIDTH-1:0]    dfu2ar_data_out,
    output reg                     dfu2ar_data_out_vld,
    output reg                     dfu2idu_load_instr_done,
    output reg [Es-1:0]            dfu2op_bank_a_sram_data_out[0:no_of_sram_banks-1],
    output reg                     dfu2op_bank_a_sram_data_out_vld[0:no_of_sram_banks-1],
    output reg [Es-1:0]            dfu2op_bank_b_sram_data_out[0:no_of_sram_banks-1],
    output reg                     dfu2op_bank_b_sram_data_out_vld[0:no_of_sram_banks-1],
    output reg					   dfu2ar_write_interrupt
);

    wire [sram_addr-1:0] wr_a_addr;
    wire                     wr_a_en;
    wire [sram_addr-1:0] wr_b_addr;
    wire                     wr_b_en;

    // Instantiate Req_And_Fetch_Data module
    dfu_ip_fsm dut_fsm (
        .clk                      (clk),
        .rst                      (rst),
        .idu2dfu_load_fifo_empty  (idu2dfu_load_fifo_empty),
        .dfu2idu_load_instr_req   (dfu2idu_load_instr_req),
        .idu2dfu_load_instr       (idu2dfu_load_instr),
        .idu2dfu_load_instr_vld   (idu2dfu_load_instr_vld),
        .dfu2ar_grant_req         (dfu2ar_grant_req),
        .ar2dfu_grant             (ar2dfu_grant),
        .dfu2ar_wr_req            (dfu2ar_wr_req),
        .dfu2ar_addr              (dfu2ar_addr),
        .dfu2ar_addr_vld          (dfu2ar_addr_vld),
        .dfu2ar_data_out          (dfu2ar_data_out),
        .dfu2ar_data_out_vld      (dfu2ar_data_out_vld),
        .ar2dfu_ack               (ar2dfu_ack),
        .wr_a_en                  (wr_a_en),
        .wr_a_addr                (wr_a_addr),
        .wr_b_en                  (wr_b_en),
        .wr_b_addr                (wr_b_addr),
       // .ar2dfu_data_in           (ar2dfu_data_in),
        .ar2dfu_data_in_vld       (ar2dfu_data_in_vld),
        .ar2dfu_ack_data_done     (ar2dfu_ack_data_done),
      .dfu2idu_load_instr_done  (dfu2idu_load_instr_done),
      .dfu2ar_write_interrupt   (dfu2ar_write_interrupt)
    );

    // Instantiate Sram_Banks module
    sram_banks dut_sram (
        .clk                      (clk),
        .rst                      (rst),
        .ar2dfu_data_in           (ar2dfu_data_in),
        .wr_a_en                  (wr_a_en),
        .wr_a_addr                (wr_a_addr),
        .wr_b_en                  (wr_b_en),
        .wr_b_addr                (wr_b_addr),
        .dfu2ip_a_sram_rd_en      (dfu2ip_a_sram_rd_en),
        .dfu2ip_a_sram_rd_addr    (dfu2ip_a_sram_rd_addr),
        .dfu2ip_b_sram_rd_en      (dfu2ip_b_sram_rd_en),
        .dfu2ip_b_sram_rd_addr    (dfu2ip_b_sram_rd_addr),
        .dfu2op_bank_a_sram_data_out  (dfu2op_bank_a_sram_data_out),
        .dfu2op_bank_a_sram_data_out_vld (dfu2op_bank_a_sram_data_out_vld),
        .dfu2op_bank_b_sram_data_out  (dfu2op_bank_b_sram_data_out),
        .dfu2op_bank_b_sram_data_out_vld (dfu2op_bank_b_sram_data_out_vld)
    );

endmodule

