module mux(
  input  wire                      clk,
  input  wire                      rst,
  input  wire [Es-1:0]             mux_in   [0:no_of_sram_banks-1],
 // input wire mux_in_vld,
  input  wire [no_of_sel_ln-1:0]   mux_sel,
  output reg  [Es-1:0]             mux_out,
  output reg                       out_vld,
  input ack_start_sys
);



  //   assign mux_out = mux_in [mux_sel];
  //   assign out_vld =  mux_in_vld;

//   reg [Es-1:0] mux_in_temp;
//   always@(*)
//     mux_in_temp = mux_in;
  

  always @(posedge clk)
    if (!rst) begin
      mux_out <= 'b0;
      out_vld <= 1'b0;
    end else begin
      // if (|mux_sel == 1'b0 || |mux_sel == 1'b1) 
      if(ack_start_sys)
//       if(mux_in_vld)
        begin
          mux_out <= mux_in[mux_sel];
          out_vld <= 1'b1;
        end 
      else begin
        out_vld <= 1'b0;
      end
    end

  //   always@(*)   
  //     if(ack_start_sys)
  //       begin
  //         mux_out = mux_in[mux_sel];
  //         out_vld = 1'b1;
  //       end 
  //   else begin
  //     out_vld = 1'b0;
  //   end



endmodule

