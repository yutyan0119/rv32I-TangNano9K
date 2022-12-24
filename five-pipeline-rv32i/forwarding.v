`include "define.vh"
module forwarding (
    input wire is_raw, is_stall, is_mem_raw,
    input wire [31:0] r_data,
    input wire [31:0] alu_result,
    input wire [31:0] mem_result,
    output wire [31:0] forward_result
);
    assign forward_result = is_raw ? alu_result : (is_stall || is_mem_raw) ? mem_result : r_data;
endmodule