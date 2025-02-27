module dfu_lsc
(
  input clk, rst,
  input dfu2idu_load_instr_done, dfu2idu_compute_done, dfu2idu_store_done,
  output reg dfu_lsc_done
);

  always@(posedge clk or negedge rst)
  begin
    if (!rst) begin
      dfu_lsc_done <= 0;
    end else begin
      dfu_lsc_done <= dfu2idu_load_instr_done || dfu2idu_compute_done || dfu2idu_store_done;
    end
  end

endmodule
