`include "define.vh"

module nextpc(
    input wire[31:0] pc_plus4, alu_result,
    input wire is_branch,
    output wire[31:0] next_pc
  );
  assign next_pc = is_branch ? alu_result : pc_plus4;
endmodule
