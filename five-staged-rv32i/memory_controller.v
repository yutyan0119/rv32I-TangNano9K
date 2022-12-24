`include "define.vh"

module memory_controller (
    input wire clk,is_store, is_load, reset,
    input [2:0] mem_wren, load_val,
    input [31:0] pre_addr, w_data,
    output wire uart_tx,
    output wire [31:0] read_data
);
/* verilator lint_off WIDTH */
wire [31:0] addr = (pre_addr-'h6100) >> 2;
wire uart_wr_i ;
assign uart_wr_i = (mem_wren == 3'b000 && pre_addr == `UART_ADDR && is_store == 1'b1) ? 1'b1 : 1'b0;
wire[7:0] uart_dat_i;
assign uart_dat_i = w_data[7:0];
uart uart(
    .uart_tx(uart_tx),
    .uart_wr_i(uart_wr_i),
    .uart_dat_i(uart_dat_i),
    .clk(clk),
    .reset(reset)
);

wire [31:0] counter;

hardware_counter hardware_counter(
    .clk(clk),
    .reset(reset),
    .COUNTER_OP(counter)
);

wire [1:0] offset = pre_addr[1:0];
wire [3:0] w_enable;
assign w_enable = (mem_wren == 3'b000) ? (4'b0001 << offset) : 
                  (mem_wren == 3'b001) ? (4'b0011 << offset) : 
                  (mem_wren == 3'b010) ? (4'b1111 << offset): 4'b0000; 


wire [31:0] r_data_mem;
wire [4:0] offset_8 = offset << 3;
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

wire [31:0] shift_data = r_data_mem >> offset_8;

function [31:0]filter_r_data(
    input [31:0] shift_data,
    input [1:0] offset_8,
    input [3:0] load_val
);
    case (load_val)
        3'b000: filter_r_data = {{24{shift_data[7]}}, shift_data[7:0]};
        3'b001: filter_r_data = {{16{shift_data[15]}}, shift_data[15:0]};
        3'b010: filter_r_data = shift_data;
        3'b100: filter_r_data = {24'b0, shift_data[7:0]};
        3'b101: filter_r_data = {16'b0, shift_data[15:0]};
        default: filter_r_data = 32'b0;
    endcase
endfunction

assign read_data = (pre_addr == `HARDWARE_COUNTER_ADDR && is_load && load_val == 3'b010) ? counter : filter_r_data(shift_data, offset_8, load_val);
/* verilator lint_on WIDTH */
endmodule