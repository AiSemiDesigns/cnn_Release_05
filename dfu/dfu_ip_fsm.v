module dfu_ip_fsm (
    input wire                   clk,
    input wire                   rst,
    input wire                   idu2dfu_load_fifo_empty,
    output reg                   dfu2idu_load_instr_req,
    input wire [INSTR_WIDTH-1:0] idu2dfu_load_instr,
    input wire                   idu2dfu_load_instr_vld,
    output reg                   dfu2ar_grant_req,
    input                        ar2dfu_grant,          // Newly added
    output reg                   dfu2ar_wr_req,
    output reg [FIFO_WIDTH-1:0]  dfu2ar_addr,
    output reg                   dfu2ar_addr_vld,
    output reg [DATA_WIDTH-1:0]  dfu2ar_data_out,
    output reg                   dfu2ar_data_out_vld,
    input wire                   ar2dfu_ack,
    output                   wr_a_en,		//updated
    output                   wr_b_en,		//updated
  output  [sram_addr-1:0] wr_a_addr,		//updated
  output  [sram_addr-1:0] wr_b_addr,		//updated
 
  //  input wire [AXI_DATA_WIDTH-1:0] ar2dfu_data_in,
    input wire                   ar2dfu_data_in_vld,
    input wire                   ar2dfu_ack_data_done,
    output reg                   dfu2idu_load_instr_done,
    output reg			 dfu2ar_write_interrupt
);

    // State Parameters
    parameter IDLE                 = 3'b000;
    parameter FETCH_INSTR          = 3'b001;
    parameter REQUEST              = 3'b010;
    parameter CU_WRITE             = 3'b011;
    parameter DATA_FETCH           = 3'b100;
    parameter SPEC                 = 3'b110;

    parameter config_write_Startaddr = 'h403;

    // Internal Registers
    reg [sram_addr-1:0] temp;
    reg [255:0] instruction;
    reg [15:0]  band_x;
    reg [15:0]  band_y;
    reg [63:0]  dram_addr;
    reg [63:0]  sram_addr;
    reg [7:0]   A_Bmatrix;
    reg [7:0]   req_count;
   // reg [5:0]   req_count_b;
    reg [63:0]  req_size;
    reg [63:0]  req_src_addr;
    reg [63:0]  req_des_addr;
    reg [2:0]   state;
    reg [2:0]   i;
    
  

    // State Machine
    always @(posedge clk) begin
        if (!rst) begin
            // Reset logic
            state                    <= IDLE;
            instruction              <= 0;
            band_x                   <= 0;
            band_y                   <= 0;
            A_Bmatrix                <= 0;
            dram_addr                <= 0;
            sram_addr                <= 0;
            req_size                 <= 0;
            req_src_addr             <= 0;
            req_des_addr             <= 0;
            req_count                <= 0;
           // req_count_b              <= 0;
            i                        <= 0;
            dfu2idu_load_instr_req   <= 0;
            dfu2ar_grant_req         <= 0;
            dfu2ar_wr_req            <= 0;
            dfu2ar_addr              <= 0;
            dfu2ar_addr_vld          <= 0;
            dfu2ar_data_out          <= 0;
            dfu2ar_data_out_vld      <= 0;
        //    wr_a_en                  <= 0;
         //   wr_b_en                  <= 0;
         //   wr_a_addr                <= 0;
          //  wr_b_addr                <= 0;
            dfu2idu_load_instr_done  <= 0;
           temp                     <= 0;
          	dfu2ar_write_interrupt<=0;
        end else begin
            case (state)
                // Monitoring idu2dfu_load_fifo_empty and generating request for instruction.
                IDLE: begin
                    i                    <= 0;
                    temp                 <= 0;
                    req_count            <= 0;
            //        wr_a_en              <= 0;
               //     wr_b_en              <= 0;

                    if (!idu2dfu_load_fifo_empty) begin
                        dfu2idu_load_instr_req <= 1;
                        state                 <= FETCH_INSTR;
                    end else begin
                        dfu2idu_load_instr_req <= 0;
                        state                 <= IDLE;
                    end
                    dfu2idu_load_instr_done <= 0;
                end

                // Fetching instructions from IDU.
                FETCH_INSTR: begin
                  dfu2idu_load_instr_req <= 0;
                    if (idu2dfu_load_instr_vld) begin
                        instruction <= idu2dfu_load_instr;
                        state       <= REQUEST;
                      dfu2idu_load_instr_req <= 0;
                    end else begin
                        state       <= FETCH_INSTR;
                    end
                end

                // Requesting to write into CU via arbiter.
                REQUEST: begin
                //    wr_a_en              <= 0;
                 //   wr_b_en              <= 0;
                    dfu2idu_load_instr_req <= 0;
                    dfu2idu_load_instr_done <= 0;
                    dfu2ar_grant_req     <= 1;
                    band_x               <= instruction[23:8];
                    band_y               <= instruction[39:24];
                    A_Bmatrix            <= instruction[47:40];
                    dram_addr            <= instruction[127:64];
                    sram_addr            <= instruction[191:128];
                    state                <= SPEC;
                end

                SPEC: begin
                    if (req_count < band_y[7:0]) begin
                        if (req_count == 0) begin
                            req_size[15:0]    <= band_x;
                            req_size[63:16] <= 'b0;
                            req_src_addr <= dram_addr;
                            req_des_addr <= sram_addr;
                            state       <= CU_WRITE;
                        end else begin
                            req_size[15:0]    <= band_x;
                            req_size[63:16] <= 'b0;
                            req_src_addr <= req_src_addr + band_x;
                            req_des_addr <= sram_addr;
                            state       <= CU_WRITE;
                        end
                    end else begin
                        dfu2ar_wr_req <= 0;
                        state         <= REQUEST;
                    end
                end

                // Writing into CU via arbiter.
                CU_WRITE: begin
                 //   wr_a_en   <= 0;
                 //   wr_b_en   <= 0;
                 
                 if (ar2dfu_ack) begin
                        dfu2ar_addr_vld     <= 0;
                        dfu2ar_data_out_vld <= 0;
                        dfu2ar_wr_req       <= 0;
                        state              <= DATA_FETCH;
                        dfu2ar_write_interrupt<=1;
                    end
                    
                    else if (ar2dfu_grant) begin
                      
                        case (i)
                            0: begin
                                dfu2ar_wr_req       <= 1;
                                dfu2ar_addr         <= config_write_Startaddr;
                                dfu2ar_addr_vld     <= 1;
                                dfu2ar_data_out     <= req_size;
                                dfu2ar_data_out_vld <= 1;
                                i                  <= i + 1;
                            end
                            1: begin
                                dfu2ar_wr_req       <= 1;
                                dfu2ar_addr         <= config_write_Startaddr + 2;
                                dfu2ar_addr_vld     <= 1;
                                dfu2ar_data_out     <= req_src_addr;
                                dfu2ar_data_out_vld <= 1;
                                i                  <= i + 1;
                            end
                            2: begin
                                dfu2ar_wr_req       <= 1;
                                dfu2ar_addr         <= config_write_Startaddr + 4;
                                dfu2ar_addr_vld     <= 1;
                                dfu2ar_data_out     <= req_des_addr;
                                dfu2ar_data_out_vld <= 1;
                                i                  <= i + 1;
                            end
                        endcase
                    end
			else 
				state <= CU_WRITE;
                    
                end

                // Matrix A data fetching from AXI via arbiter.
                DATA_FETCH: begin
                    dfu2idu_load_instr_done <= 0;
		   dfu2ar_write_interrupt<=0;
                  if (ar2dfu_data_in_vld && A_Bmatrix == 'h00) begin
                       // wr_a_en  <= 1;
                      //  wr_b_en  <= 0;
                       // wr_a_addr <= temp;
                        temp     <= temp + 1'b1;
                       // dfu2ar_write_interrupt<=0;
                    end else if (ar2dfu_data_in_vld && A_Bmatrix == 'h01) begin
                     //   wr_a_en  <= 0;
                     //   wr_b_en  <= 1;
                  //      wr_b_addr <= temp;
                        temp     <= temp + 1'b1;
                      //  dfu2ar_write_interrupt<=0;
                    end

                    if (ar2dfu_ack_data_done) begin
                    //  dfu2ar_write_interrupt<=0;
                        if (req_count + 1 != band_y) begin
                            state     <= SPEC;
                            i         <= 0;
                            req_count <= req_count + 1;
                        end else if (req_count + 1 == band_y) begin
                            dfu2idu_load_instr_done <= 1;
                            state                  <= IDLE;
                            dfu2ar_grant_req       <= 0;
                        end
                    end
                end
            endcase
        end
    end
  
  assign wr_a_addr = ((state ==DATA_FETCH)&& (ar2dfu_data_in_vld && A_Bmatrix == 'h00))?temp:wr_a_addr;
  assign  wr_a_en = ((state ==DATA_FETCH)&&(ar2dfu_data_in_vld && A_Bmatrix == 'h00))?1:0;
  
  assign wr_b_addr = ((state ==DATA_FETCH)&& (ar2dfu_data_in_vld && A_Bmatrix == 'h01))?temp:wr_b_addr;
  assign  wr_b_en = ((state ==DATA_FETCH)&&(ar2dfu_data_in_vld && A_Bmatrix == 'h01))?1:0;
endmodule

