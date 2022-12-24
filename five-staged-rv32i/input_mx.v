`include "define.vh"

module input_mx(
    input wire alu_sel,
    input wire[31:0] reg_data, imm_pc,
    output wire[31:0] out_data
  );
  assign out_data = (alu_sel == 1'b1) ? imm_pc : reg_data;
endmodule
