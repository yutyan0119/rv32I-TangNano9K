`include "define.vh"

module rb_mux (
    input wire [31:0] mem_data, alu_result, pc_plus4,
    input wire [1:0] write_sel,
    output wire [31:0] wb_data
  );
  assign wb_data = (write_sel == 2'b00) ? alu_result :
         (write_sel == 2'b01) ? mem_data :
         (write_sel == 2'b10) ? pc_plus4 : 32'b0;
endmodule
