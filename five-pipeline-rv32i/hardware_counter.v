//
// hardware counter
//


module hardware_counter(
    input clk,
    input reset,
    output [31:0] COUNTER_OP
);

    reg [31:0] cycles;

    always @(posedge clk) begin
        if(!reset)begin
            cycles <= 32'd0;
        end else begin
            cycles <= cycles + 1;
        end
    end

    assign COUNTER_OP = cycles;

endmodule