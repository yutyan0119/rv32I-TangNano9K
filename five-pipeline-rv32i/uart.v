module uart(
   // Outputs
   // uart_busy,   // High means UART is transmitting
   uart_tx,     // UART transmit wire
   // Inputs
   uart_wr_i,   // Raise to transmit byte
   uart_dat_i,  // 8-bit data
   clk,   // System clock, 100 MHz
   reset    // System reset
);

  input uart_wr_i;
  input [7:0] uart_dat_i;
  input clk;
  input reset;

  // output uart_busy;
  output uart_tx;

  reg [3:0] bitcount;
  reg [8:0] shifter;
  reg uart_tx;

  wire uart_busy = |bitcount[3:1];
  wire sending = |bitcount;

  // clk is 100MHz.  We want a 115200Hz clock

  reg [28:0] d;
  wire [28:0] dInc = d[28] ? (115200) : (115200 - 123000000);
  wire [28:0] dNxt = d + dInc;
  always @(posedge clk) begin
    if (!reset) begin
        d <= 29'b0;
    end else begin
        d <= dNxt;
    end
  end
  wire ser_clk = ~d[28]; // this is the 115200 Hz clock

  always @(posedge clk)
  begin
    if (!reset) begin
      uart_tx <= 1;
      bitcount <= 0;
      shifter <= 0;
    end else begin
      // just got a new byte
      if (uart_wr_i & ~uart_busy) begin
        shifter <= { uart_dat_i[7:0], 1'h0 };
        bitcount <= (1 + 8 + 2);
      end

      if (sending & ser_clk) begin
        { shifter, uart_tx } <= { 1'h1, shifter };
        bitcount <= bitcount - 1;
      end
    end
  end

endmodule