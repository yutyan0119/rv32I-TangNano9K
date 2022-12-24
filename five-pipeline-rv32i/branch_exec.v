module branch_exec (
    input wire[2:0] branch_op,
    input wire signed [31:0] data1,
    input wire signed [31:0] data2,
    input wire [1:0] pc_sel,
    output wire is_branch
  );
  assign is_branch = (pc_sel == 2'b00) ? 1'b0 : 
                     (pc_sel == 2'b10) ? 1'b1 : 
                     (pc_sel == 2'b01) ? ((branch_op == 3'b000) ? (data1 == data2) : 
                                         (branch_op == 3'b001) ? (data1 != data2) : 
                                         (branch_op == 3'b100) ? (data1 < data2) : 
                                         (branch_op == 3'b101) ? (data1 >= data2) : 
                                         (branch_op == 3'b110) ? ($unsigned(data1) < $unsigned(data2)) : 
                                         (branch_op == 3'b111) ? ($unsigned(data1) >= $unsigned(data2)) : 1'b0 )
                                         : 1'b0;

endmodule
