module ram(
    input clk,
    input is_store,
    input is_load,
    input [3:0] w_enable, 
    input [31:0] addr,
    input [31:0] w_data,
    output reg [31:0] r_data
  );
  reg [31:0] mem [0:'ha00];
  //initial文でdataを読み込む
  initial
  begin
   $readmemh("/path/to/coremark/data.hex", mem);
  end
  always @(posedge clk)
  begin
      if (is_store) begin
        if(w_enable[0]) mem[addr][7:0] <= w_data[7:0];
        if(w_enable[1]) mem[addr][15:8] <= w_data[15:8];
        if(w_enable[2]) mem[addr][23:16] <= w_data[23:16];
        if(w_enable[3]) mem[addr][31:24] <= w_data[31:24];
      end else if (is_load) begin
        r_data <= mem[addr];
      end
  end  
endmodule
