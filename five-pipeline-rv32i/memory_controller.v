`include "define.vh"

module memory_controller (
    input wire clk, is_store, is_load, reset, is_flash_e,
    input [2:0] mem_wren,
    input [31:0] ram_addr, w_data,
    output wire uart_tx,
    output wire [31:0] counter, r_data_mem
);
wire [31:0] addr = (ram_addr-'h6100) >> 2;
wire uart_wr_i ;
assign uart_wr_i = (is_flash_e) ? 1'b0 : (mem_wren == 3'b000 && ram_addr == `UART_ADDR && is_store == 1'b1) ? 1'b1 : 1'b0;
wire[7:0] uart_dat_i;
assign uart_dat_i = w_data[7:0];
uart uart(
    .uart_tx(uart_tx),
    .uart_wr_i(uart_wr_i),
    .uart_dat_i(uart_dat_i),
    .clk(clk),
    .reset(reset)
);

hardware_counter hardware_counter(
    .clk(clk),
    .reset(reset),
    .COUNTER_OP(counter)
);

//for write before write to ram
wire [1:0] offset = ram_addr[1:0];
wire [3:0] w_enable;
assign w_enable = (is_flash_e) ? 4'b0000:
                  (mem_wren == 3'b000) ? (4'b0001 << offset) : 
                  (mem_wren == 3'b001) ? (4'b0011 << offset) : 
                  (mem_wren == 3'b010) ? (4'b1111 << offset): 4'b0000; 

 /* verilator lint_off WIDTH */
wire [4:0] offset_8 = offset << 3;
 /* verilator lint_on WIDTH */
wire [31:0] w_data_offset;
assign w_data_offset = w_data << offset_8;

ram ram(
    .clk(clk),
    .is_store(is_store),
    .is_load(is_load),
    .w_enable(w_enable),
    .addr(addr),
    .w_data(w_data_offset),
    .r_data(r_data_mem)
);

endmodule