module branch_exec (
    input wire[2:0] branch_op,
    input wire signed [31:0] data1,
    input wire signed [31:0] data2,
    input wire [1:0] pc_sel,
    output reg is_branch
  );
  always @(*)begin
    case (pc_sel)
      (2'b00):is_branch <= 1'b0;
      (2'b10):is_branch <= 1'b1;
      (2'b01): begin
        case (branch_op)
          (3'b000):is_branch <= (data1 == data2);
          (3'b001):is_branch <= (data1 != data2);
          (3'b100):is_branch <= (data1 < data2);
          (3'b101):is_branch <= (data1 >= data2);
          (3'b110):is_branch <= ($unsigned(data1) < $unsigned(data2));
          (3'b111):is_branch <= ($unsigned(data1) >= $unsigned(data2));
          default: is_branch <= 1'b0;
        endcase
      end
      default: is_branch <= 1'b0;
    endcase
  end
endmodule
