`include "define.vh"

module alu(
    input wire [3:0] alu_op,
    input wire signed [31:0] data1, data2,
    output reg [31:0] alu_result
  );
    always @(*)
  begin
    case (alu_op)
      4'b0000:
        alu_result <= data1 + data2;
      4'b1000:
        alu_result <= data1 - data2;
      4'b0001:
        alu_result <= data1 << data2[4:0];
      4'b0010:
        alu_result <= (data1 < data2) ? 32'b1 : 32'b0;
      4'b0011:
        alu_result <= ($unsigned(data1) < $unsigned(data2)) ? 32'b1 : 32'b0;
      4'b0100:
        alu_result <= data1 ^ data2;
      4'b0101:
        alu_result <= data1 >> data2[4:0];
      4'b1101:
        alu_result <= data1 >>> data2[4:0];
      4'b0110:
        alu_result <= data1 | data2;
      4'b0111:
        alu_result <= data1 & data2;
      default:
        alu_result <= 32'b0;
    endcase
  end

endmodule
