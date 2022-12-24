module register_file (
    input clk, we,
    input [4:0] r_addr1, r_addr2, w_addr,
    input [31:0] w_data,
    output wire [31:0] r_data1, r_data2
  );
  reg [31:0] register [0:31];

  initial
  begin
    register[0] = 32'b0;
  end
  assign r_data1 = register[r_addr1];
  assign r_data2 = register[r_addr2];
  always @(posedge clk)
  begin
    if (we && w_addr != 5'b0)
    begin
      register[w_addr] <= w_data;
    end
    else
    begin
    end
  end
endmodule
