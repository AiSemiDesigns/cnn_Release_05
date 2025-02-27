parameter PADDR_WIDTH=32;
parameter PDATA_WIDTH=32;

parameter ADDR_WIDTH=64;
parameter CU_DATA_WIDTH= 64;
parameter DATA_WIDTH=64;
parameter FIFO_WIDTH=64;
parameter FIFO_LENGTH=32;
//parameter threshold_value=8;

parameter AXI_ID_WIDTH=8;
parameter AXI_ADDR_WIDTH=64;
parameter AXI_LEN_WIDTH=8;
parameter AXI_SIZE_WIDTH=3;

parameter AXI_DATA_WIDTH=64;
parameter AXI_STROBE_WIDTH=4;

parameter AXI_RESP_WIDTH=2;
parameter FIFO_IFU_WIDTH=64;

parameter Es=8;
parameter INSTR_WIDTH=256;

parameter no_of_sram_banks=8;
parameter ROW=8;
parameter no_of_sel_ln=$clog2(no_of_sram_banks);

parameter COL=8;
parameter El_RC=64;
parameter sel_sram_bank_bits=$clog2(no_of_sram_banks);

parameter sram_locations=64;
parameter sram_addr=$clog2(sram_locations);

parameter C_El=32;
parameter cu_length=32'h403;

parameter cu_sram_addr=32'h411;
parameter cu_dram_addr=32'h413;
parameter AXI_WIDTH=64;

parameter sram_addr_c=3;
parameter AXI_RDATA_WIDTH=64;
//// IFU FSM 7/////

parameter config_read_start_addr='h3fe;
parameter config_write_start_addr='h403;
parameter dummy_addr='d10;

parameter threshold_value=(FIFO_LENGTH/4);

