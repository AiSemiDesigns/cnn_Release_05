module AXI_TARGET(
  input           ACLK,
  input           ARESETn,

  // AXI write address channel
  input	[AXI_ID_WIDTH-1:0] AWID,
  input  [AXI_ADDR_WIDTH-1:0]   AWADDR,
  input  [AXI_LEN_WIDTH-1:0]    AWLEN,
  input  [AXI_SIZE_WIDTH-1:0]    AWSIZE,
  input  [1:0]    AWBURST,
  input           AWVALID,
  output reg      AWREADY,

  // AXI write data channel
  input  [AXI_DATA_WIDTH-1:0]   WDATA,
  input  [3:0]    WSTRB,
  input           WLAST,
  input           WVALID,
  output reg      WREADY,
  input	[AXI_ID_WIDTH-1:0] WID,

  // AXI write response channel
  input	[AXI_ID_WIDTH-1:0] BID,
  output reg [1:0] BRESP,
  output reg       BVALID,
  input            BREADY,

  // AXI read address channel
  input	[AXI_ID_WIDTH-1:0] ARID,
  input  [AXI_ADDR_WIDTH-1:0]   ARADDR,
  input  [AXI_LEN_WIDTH-1:0]    ARLEN,
  input  [AXI_SIZE_WIDTH-1:0]    ARSIZE,
  input  [1:0]    ARBURST,
  input           ARVALID,
  output reg      ARREADY,

  // AXI read data channel
  input	[AXI_ID_WIDTH-1:0] RID,
  output  [AXI_DATA_WIDTH-1:0] RDATA,
  output reg [1:0]  RRESP,
  output       RVALID,
  output        RLAST,
  input             RREADY,

  //..axi ar ...
  input [AXI_DATA_WIDTH-1:0] ar2axi_rd_data,
  input ar2axi_rd_data_vld,
  output [AXI_ADDR_WIDTH-1:0] axi2ar_wr_addr,axi2ar_rd_addr,
  output axi2ar_wr_addr_valid , axi2ar_rd_addr_valid,
  output axi2ar_wr_done,
  output [AXI_DATA_WIDTH-1:0]axi2ar_wr_data,
  output axi2ar_wr_data_valid
);

  // Write FSM states
  localparam WRITE_IDLE   = 2'b00;
  localparam WRITE_ADDR   = 2'b01;
  localparam WRITE_DATA   = 2'b10;
  localparam WRITE_RESP   = 2'b11;

  // Read FSM states
  localparam READ_IDLE    = 2'b00;
  localparam READ_ADDR    = 2'b01;
  localparam READ_DATA    = 2'b10;

  // FSM registers
  reg [1:0] write_state;
  reg [1:0] read_state;

  // Address and burst counters
  reg [AXI_ADDR_WIDTH-1:0] write_address;
  reg [AXI_LEN_WIDTH-1:0] burst_count;
  reg [AXI_ADDR_WIDTH-1:0] read_address;
  reg [AXI_LEN_WIDTH-1:0] read_burst_count;
  reg [AXI_LEN_WIDTH-1:0]rd_burst_temp;
  reg [AXI_LEN_WIDTH-1:0] count;

  reg write_valid;
  reg [AXI_DATA_WIDTH-1:0]write_data;
  reg write_last;
  reg [AXI_ADDR_WIDTH-1:0] write_addr;
  reg [AXI_ADDR_WIDTH-1:0] read_addr;
  reg rd_valid;

  // Memory array (for simplicity)
  //reg [31:0] mem [0:255];
  //integer i;

  // Burst logic function
  function [AXI_ADDR_WIDTH-1:0] next_address;
    input [AXI_ADDR_WIDTH:0] curr_address;
    input [1:0]  burst_type;
    input [2:0]  size;
    input [AXI_DATA_WIDTH-1:0]data;

    $strobe($time,"design data=%0h next_addr=%0h",data,next_address);
    begin
      case (burst_type)
        2'b00: next_address = curr_address; // FIXED
        2'b01: next_address = curr_address + 1;//(1 << size); // INCREMENTAL
        2'b10: next_address = {curr_address[31:4], (curr_address[3:0] + (1 << size)) % 16}; // WRAP
        default: next_address = curr_address;
      endcase
    end
  endfunction

  // Write FSM
  always @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn) begin

      write_state <= WRITE_IDLE;
      AWREADY <= 1'b0;
      WREADY <= 1'b0;
      BVALID <= 1'b0;
      BRESP <= 2'b00;
      write_address <= 32'b0;
      burst_count <= 8'b0;
      write_data <= 0;
      write_valid <= 0;
      write_last <= 0;
      write_addr <= 0;

      /*for(i=0;i<=255;i=i+1)
  begin
    mem[i]<= 0;
  end
  */
    end else begin
      case (write_state)
        WRITE_IDLE: begin
          AWREADY <= AWVALID;
          write_valid <= 0;
          write_last <= 0;
          if (AWVALID) begin
            write_address <= AWADDR;
            burst_count <= AWLEN;
            write_state <= WRITE_ADDR;
          end
        end

        WRITE_ADDR: begin
          if (AWVALID && AWREADY) begin
            AWREADY <= 1'b0;
            write_state <= WRITE_DATA;
            WREADY <= 1;
          end
        end

        WRITE_DATA: begin
          if (WVALID && WREADY) begin
            //   mem[write_address] <= WDATA;
            write_addr <= write_address;
            write_data <= WDATA;
            write_valid <= 1;
            write_last <= WLAST;
            //   $strobe($time,"design memory data[%0h]= %0h ",write_address-1,mem[write_address-1]);
            write_address <= next_address(write_address, AWBURST, AWSIZE,WDATA);
            burst_count <= burst_count - 1;
            if (burst_count == 0 && WLAST) begin
              write_state <= WRITE_RESP;
              WREADY<=0;
            end
          end
          //burst_count != 0; // Assert WREADY if more data expected
        end


        WRITE_RESP: begin
          WREADY<=0;
          BVALID <= 1'b1;
          BRESP <= 2'b00; // OKAY response
          write_valid = 0;

          if (BREADY && BVALID) begin
            BVALID <= 1'b0;
            write_state <= WRITE_IDLE;
          end
        end
      endcase
    end
  end


  // Read FSM
  always @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn) begin
      read_state <= READ_IDLE;
      //ARREADY <= 1'b0;
      //RVALID <= 1'b0;
      //   RLAST <= 1'b0;
      RRESP <= 2'b00;
      //ARVALID<=0;
      read_address <= 32'b0;
      read_burst_count <= 8'b0;
      rd_burst_temp <= 0;
      //       count <= 0;
      //rd_valid <= 0;
    end else begin
      case (read_state)
        READ_IDLE: begin
          // RLAST<=0;
          //rd_valid <= 0;
          RRESP <= 2'b00;
          ARREADY <= ARVALID;
          if (ARVALID) begin
            read_address <= ARADDR;
            // rd_valid <= 1;
            read_burst_count <= ARLEN;
            rd_burst_temp <= ARLEN ;
            read_state <= READ_ADDR;
          end
        end

        READ_ADDR: begin
          if (ARVALID && ARREADY) begin
            ARREADY <= 1'b0;
            read_state <= READ_DATA;
            count <= 0;
          end
        end

        READ_DATA: begin
          if (RREADY) begin
            read_addr <= read_address;
            if(RREADY&& RVALID) begin
              read_address <= next_address(read_address, ARBURST, ARSIZE,32'hff);
              read_burst_count <= read_burst_count - 1;
              if (read_burst_count == 0) begin
                read_state <= READ_IDLE;
                // RLAST <= 1;
              end
            end 
          end
        end
      endcase
    end
  end



  assign axi2ar_wr_addr = write_addr;
  assign axi2ar_wr_addr_valid = (write_state == WRITE_DATA)?write_valid:0;
  assign  axi2ar_wr_data = WDATA;
  assign  axi2ar_wr_data_valid = (write_state == WRITE_DATA)?WVALID:0;

  assign  axi2ar_wr_done = (write_state == WRITE_DATA)?WLAST:0;

  assign axi2ar_rd_addr = read_addr;
  assign axi2ar_rd_addr_valid = rd_valid;
  assign RDATA = ar2axi_rd_data;
  assign RVALID = ar2axi_rd_data_vld;

  assign RLAST = (read_state == READ_DATA && (read_burst_count==0)) ? 1:0;


  always@(posedge ACLK or negedge ARESETn)
    if(!ARESETn)
      begin
        rd_valid <= 0;
        count <= 0;
      end
  else if(count == rd_burst_temp)
    begin
      count <= 0;
      rd_valid <= 0;
    end
  else if (read_state == READ_DATA && RREADY)
    begin
      count <= count+1;
      rd_valid <= 1;
    end
  else if(read_state == READ_ADDR && (ARVALID && ARREADY))
    count <= 0;

endmodule


