`include "define.vh"

module alu(
    input wire [3:0] alu_op,
    input wire signed [31:0] data1, data2,
    output wire [31:0] alu_result
  );
  assign alu_result = (alu_op == 4'b0000) ? data1 + data2 : 
                      (alu_op == 4'b1000) ? data1 - data2 : 
                      (alu_op == 4'b0001) ? data1 << data2[4:0] : 
                      (alu_op == 4'b0010) ? (data1 < data2) ? 32'b1 : 32'b0 : 
                      (alu_op == 4'b0011) ? ($unsigned(data1) < $unsigned(data2)) ? 32'b1 : 32'b0 : 
                      (alu_op == 4'b0100) ? data1 ^ data2 : 
                      (alu_op == 4'b0101) ? data1 >> data2[4:0] : 
                      (alu_op == 4'b1101) ? data1 >>> data2[4:0] : 
                      (alu_op == 4'b0110) ? data1 | data2 : 
                      (alu_op == 4'b0111) ? data1 & data2 : 32'b0;

endmodule
