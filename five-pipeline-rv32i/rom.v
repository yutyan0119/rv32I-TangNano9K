module rom(
             input wire [31:0] r_addr,
             output wire [31:0] r_data
            );
  //TODO: initial文でデータを読み込む
  reg [31:0] mem[0:'h1a40];
  initial $readmemh("/path/to/coremark/code.hex", mem);
  wire [31:0] addr;
  assign addr = r_addr >> 2;
  assign r_data = mem[addr];
endmodule
