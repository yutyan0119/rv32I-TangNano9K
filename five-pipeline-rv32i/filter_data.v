`include "define.vh"

module filter_data (
    input wire [31:0] r_data, r_addr, counter,
    input is_load, 
    input wire [2:0] load_val,
    output wire [31:0] read_data
    );

    wire [1:0] offset = r_addr[1:0];
    /* verilator lint_off WIDTH */
    wire [4:0] offset_8 = offset << 3;
    /* verilator lint_on WIDTH */
    wire [31:0] shift_data = r_data >> offset_8;
    function [31:0]filter_r_data(
        input [31:0] shift_data,
        input [4:0] offset_8,
        input [2:0] load_val
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

    assign read_data = (r_addr == `HARDWARE_COUNTER_ADDR && is_load && load_val == 3'b010) ? counter : filter_r_data(shift_data, offset_8, load_val);

endmodule