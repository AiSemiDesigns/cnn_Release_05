module processing_element #(
	parameter ROW = 8,COL = 8, ES =8,elements = 8
)(
	
	input clk,
	input rst_n,
	input [ES-1:0] a_in,
	input a_in_vld,
	input [ES-1:0] b_in,
	input b_in_vld,
	output reg [ES-1:0] a_out,
	output reg a_out_vld,
	output reg [ES-1:0] b_out,
	output reg b_out_vld,
    output reg [ES*3-1:0] c_out,
	output reg c_out_vld
);

  reg [ES*2-1:0] accum;
  reg accum_vld;
	always @(posedge clk or negedge rst_n) begin
		if (!rst_n) begin
			a_out <= 0;
			b_out <= 0;
			c_out <= 0;
			accum <= 0;
          accum_vld <= 0;
			b_out_vld <= 0;
			c_out_vld <= 0;
			a_out_vld <= 0;
		end else 
          begin
            
			b_out <= b_in;
            b_out_vld <= (b_in_vld)?b_in_vld : 'b0;
            a_out <= a_in;
            a_out_vld <= (a_in_vld)?a_in_vld : 'b0 ;
            accum_vld <= a_in_vld && b_in_vld;
            c_out_vld <= accum_vld;
	        if (a_in_vld && b_in_vld) 
              begin
                accum <= accum + a_in * b_in;
              end
            c_out <= accum;
		end
    end
endmodule











































// module processing_element #(
//     parameter ROW = 8, COL = 8, ES = 8,elements=16
// )(
//     input clk,
//     input rst_n,
//     input [ES-1:0] a_in,
//     input a_in_vld,
//     input [ES-1:0] b_in,
//     input b_in_vld,
//     output reg [ES-1:0] a_out,
//     output reg a_out_vld,
//     output reg [ES-1:0] b_out,
//     output reg b_out_vld,
//     output reg [ES*3-1:0] c_out,
//     output reg c_out_vld
//     //output reg c_out_last_vld  // New output signal
// );

//   reg [ES*3-1:0] accum;
//   reg accum_vld;
//   reg [7:0] valid_counter;  // Counter 
//   reg last_element ;    //  the last element
//   reg c_out_last_vld;
  
//   always @(negedge clk or negedge rst_n) begin
//     if (!rst_n) begin
//         a_out <= 0;
//         b_out <= 0;
//         c_out <= 0;
//         accum <= 0;
//         accum_vld <= 0;
//         b_out_vld <= 0;
//         c_out_vld <= 0;
//         a_out_vld <= 0;
//         c_out_last_vld <= 0;  
//         valid_counter <= 0; 
//         last_element  <= 0;
      
//     end else begin
//         b_out <= b_in;
//         b_out_vld <= (b_in_vld) ? b_in_vld : 'b0;
//         //#10;
//         a_out <= a_in;
//         a_out_vld <= (a_in_vld) ? a_in_vld : 'b0;
//         accum_vld <= a_in_vld && b_in_vld;
//         c_out_vld <= accum_vld;

//         if (a_in_vld && b_in_vld) begin
//             accum <= accum + a_in * b_in;
//             valid_counter <= valid_counter + 1;
//         end

//         c_out <= accum;

//         //  last element
//       if (valid_counter == (elements-1)) begin
//             last_element  <= 1;
//         end

//         if (last_element ) begin
//             c_out_last_vld <= 1;
//             last_element  <= 0; 
//         end else begin
//             c_out_last_vld <= 0;
//         end
//     end
//   end
// endmodule





