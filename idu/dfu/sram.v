module sram (
  input  wire                    clk,
  input  wire                    rst,
  input  wire [Es-1:0]           bank_data_in,
  input  wire                    wr_en,
  input  wire [sram_addr-1:0] wr_addr,
  input  wire                    dfu2ip_sram_rd_en,
  input  wire [sram_addr-1:0] dfu2ip_sram_rd_addr,

  output  [Es-1:0]            dfu2op_bank_sram_data_out,
  output                      dfu2op_bank_sram_data_out_vld
);

  reg [Es-1:0] bank[0:(2**sram_addr)-1];

  //...................testing...........................
  wire [Es-1:0]temp;
  assign temp = bank [0];
  //.......................testing.......................

  reg [Es-1:0] bank_data_in_temp;
  reg [sram_addr-1:0]wr_addr_temp;

  always@(*)
    begin
      bank_data_in_temp = bank_data_in;
      wr_addr_temp = wr_addr;
    end

  always @(posedge clk) begin
    if (!rst) begin
      integer i;
      for (i = 0; i < (2**sram_addr); i = i + 1) begin
        bank[i] <= 0;
      end
    end else begin
      if (wr_en) begin
        bank[wr_addr_temp] <= bank_data_in_temp;
      end

    end
  end

  assign dfu2op_bank_sram_data_out = (dfu2ip_sram_rd_en)?bank[dfu2ip_sram_rd_addr]:0;
  assign dfu2op_bank_sram_data_out_vld = (dfu2ip_sram_rd_en)?1:0;


endmodule

