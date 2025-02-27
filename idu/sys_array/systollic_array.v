`include "PE.v"

module systolic_array #(
  parameter ROW = 8, COL = 8, ES = 8, elements = 8, ROW_el = 64
)(
  input              clk,
  input              rst_n,
  input              dfu2sys_a_data_in_vld   [0:ROW-1],
  input  [ES-1:0]    dfu2sys_a_data_in       [0:ROW-1],
  input              dfu2sys_b_data_in_vld   [0:COL-1],
  input  [ES-1:0]    dfu2sys_b_data_in       [0:COL-1],

  output  reg        sys2dfu_c_data_out_vld  [0:ROW-1],
  output  reg [(ES*3)-1:0] sys2dfu_c_data_out [0:ROW-1]
);

  wire               temp_a_data_in_vld      [0:ROW*COL-1];
  wire  [ES-1:0]     temp_a_data_in          [0:ROW*COL-1];
  wire               temp_b_data_in_vld      [0:ROW*COL-1];
  wire  [ES-1:0]     temp_b_data_in          [0:ROW*COL-1];
  wire               temp_a_data_out_vld     [0:ROW*COL-1];
  wire  [ES-1:0]     temp_a_data_out         [0:ROW*COL-1];
  wire               temp_b_data_out_vld     [0:ROW*COL-1];
  wire  [ES-1:0]     temp_b_data_out         [0:ROW*COL-1];
  wire               temp_c_data_out_vld     [0:ROW*COL-1];
  wire  [ES*3-1:0]   temp_c_data_out         [0:ROW*COL-1];


  genvar row, col;
  generate
    for (row = 0; row < ROW; row = row + 1) begin
      for (col = 0; col < COL; col = col + 1) begin
        if (col == 0) begin
          assign temp_a_data_in[row*COL+col] = dfu2sys_a_data_in[row];
          assign temp_a_data_in_vld[row*COL+col] = dfu2sys_a_data_in_vld[row];
        end else begin
          assign temp_a_data_in[row*COL+col] = temp_a_data_out[row*COL+col-1];
          assign temp_a_data_in_vld[row*COL+col] = temp_a_data_out_vld[row*COL+col-1];
        end

        if (row == 0) begin
          assign temp_b_data_in[row*COL+col] = dfu2sys_b_data_in[col];
          assign temp_b_data_in_vld[row*COL+col] = dfu2sys_b_data_in_vld[col];
        end else begin
          assign temp_b_data_in[row*COL+col] = temp_b_data_out[(row-1)*COL+col];
          assign temp_b_data_in_vld[row*COL+col] = temp_b_data_out_vld[(row-1)*COL+col];
        end

        processing_element pe_inst (
          .clk(clk),
          .rst_n(rst_n),
          .a_in(temp_a_data_in[row*COL+col]),
          .a_in_vld(temp_a_data_in_vld[row*COL+col]),
          .b_in(temp_b_data_in[row*COL+col]),
          .b_in_vld(temp_b_data_in_vld[row*COL+col]),
          .a_out(temp_a_data_out[row*COL+col]),
          .a_out_vld(temp_a_data_out_vld[row*COL+col]),
          .b_out(temp_b_data_out[row*COL+col]),
          .b_out_vld(temp_b_data_out_vld[row*COL+col]),
          .c_out(temp_c_data_out[row*COL+col]),
          .c_out_vld(temp_c_data_out_vld[row*COL+col])
        );
      end
    end
  endgenerate
  
  parameter AB_mx_state = 0, C_state= 1;
  reg state;

  reg [ROW-1:0] row_counter; // 3 bits to count from 0 to 7
  reg AB_indicator; 
  always @(posedge clk or negedge rst_n)      
    if (!rst_n)
      begin            
        for (int i = 0; i < ROW; i = i + 1) 
          begin
            sys2dfu_c_data_out[i] <= { (ES*3){1'b0} };
            sys2dfu_c_data_out_vld[i] <= 1'b0; 
          end
        row_counter <= 3'b0;
        AB_indicator<=0;
        state <=AB_mx_state;
      end 
  else   
    case(state)
      AB_mx_state:if (dfu2sys_a_data_in_vld[0]||dfu2sys_a_data_in_vld[ROW-1])  
        begin
          row_counter<=0;
          AB_indicator<=1;
        end
      else if (AB_indicator)
        state <= C_state;
      
      
      C_state:
        if (AB_indicator && (row_counter < ROW))  
        begin
          for (integer i=0;i<ROW;i=i+1) 
            begin              
              sys2dfu_c_data_out[i] = temp_c_data_out[(ROW*row_counter)+i];                
              sys2dfu_c_data_out_vld[i] = 1;               
            end
          row_counter <= row_counter + 1;
        end
      else 
        begin
          for (integer i=0;i<ROW;i=i+1) 
            begin              
              sys2dfu_c_data_out[i] = 0;             
              sys2dfu_c_data_out_vld[i] = 0;  
              row_counter<=0;
          AB_indicator<=0;
            end
        end
      default:state<= AB_mx_state;
    endcase
endmodule
/*      
         if (dfu2sys_a_data_in_vld[0]||dfu2sys_a_data_in_vld[ROW-1])  
           begin          
            row_counter<=0;
            AB_indicator<=1;
           end
         else if (AB_indicator&&row_counter < ROW)  
           begin           
              for (integer i=0;i<ROW;i=i+1) 
                begin              
                  sys2dfu_c_data_out[i] = temp_c_data_out[(ROW*row_counter)+i];                
                  sys2dfu_c_data_out_vld[i] = 1;               
                  $display($time,"| sys2dfu_c_data_out[%0d] =%0d | sys2dfu_c_data_out_vld[%0d]=%0d",i,sys2dfu_c_data_out[i],i,sys2dfu_c_data_out_vld[i]);
                  $display(row_counter);
                end
              row_counter <= row_counter + 1;
           end
         else   
           begin
             for (int i = 0; i < ROW; i = i + 1) 
               begin
                 sys2dfu_c_data_out[i] <= 0;                
                 sys2dfu_c_data_out_vld[i] <= 0; 
                 row_counter<=0;
                 AB_indicator<=0;
               end
           end
endmodule
*/

