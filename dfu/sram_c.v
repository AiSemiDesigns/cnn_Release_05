module sram_c (
  input clk,
  input rst,
  input wr_en,
  input [sram_addr_c-1:0] wr_c_addr,
  input [(Es*3)-1:0] bank_data_c_in,
 // input bank_data_c_in_vld,
  input rd_en,
  input [sram_addr_c-1:0] rd_addr,
  output reg [(Es*3)-1:0] data_out,
  output reg data_out_vld
);
  reg [(Es*3)-1:0] bank_c [0:(COL-1)];

  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      integer i;
      for (i = 0; i < COL; i = i + 1) begin
        bank_c[i] <= 0;
      end
      data_out <= 0;
      data_out_vld <= 0;
    end else begin
      // Write operation
      if (wr_en && (wr_c_addr < COL)) begin
        bank_c[wr_c_addr] = bank_data_c_in;
       
      end

      // Read operation
      if (rd_en && (rd_addr < COL)) begin
        data_out <= bank_c[rd_addr];
        data_out_vld <= 1;
      end else begin
        data_out_vld <= 0;
      end
    end
  end
endmodule

