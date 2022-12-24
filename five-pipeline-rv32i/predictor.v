`include "define.vh"

module predictor (
    input wire clk,
    input wire [31:0] pc, //予測の元ネタ
    input wire [31:0] pc_e, //予測のバッファ保存用
    input wire [1:0] pc_sel, //保存をするかどうか（分岐系の命令かどうか）
    input wire is_branch, //分岐してるかどうか
    input wire [31:0] jump_address, //分岐先
    input wire is_stall, //stallしてるかどうか
    output wire [31:0] next_pc //次のpc
);

wire [6:0] pc_index;
assign pc_index = pc[6:0];
reg [31:0] pc_buffer [0:127]; //pcの変換先を上位7bitから取得できる
reg [7:0] pc_check [0:127]; //保存されているnext_pcの元のpcの下位8bitを保存
reg [1:0] pc_predict [0:127]; //過去の結果に基づく予測結果
wire is_exist;
assign is_exist = ( pc_check[pc_index] == pc[14:7] ) ? 1'b1 : 1'b0;

wire [6:0] pc_e_index;
assign pc_e_index = pc_e[6:0];
wire is_exist_e;
assign is_exist_e = ( pc_check[pc_e_index] == pc_e[14:7] ) ? 1'b1 : 1'b0;

integer i;
initial begin
    for (i = 0; i < 128; i = i + 1) begin
        pc_check[i] = 8'b0;
        pc_buffer[i] = 32'b0;
        pc_predict[i] = 2'b0;
    end
end


//現在の状態に基づく予想を保存する場所
always @(posedge clk)begin
    if (pc_sel == 2'b10) begin
        pc_predict[pc_e_index] <= 2'b11;
        pc_check[pc_e_index] <= pc_e[14:7];
    end
    else if (pc_sel == 2'b01) begin
        if (is_branch)begin
            pc_predict[pc_e_index] <= (is_exist_e && pc_predict[pc_e_index] == 2'b11) ? 2'b11 : (is_exist_e) ? pc_predict[pc_e_index] + 1 : 2'b01;
            pc_buffer[pc_e_index] <= jump_address;
            pc_check[pc_e_index] <= pc_e[14:7];
        end
        else begin
            pc_predict[pc_e_index] <= (is_exist_e && pc_predict[pc_e_index] == 2'b00) ? 2'b00 : (is_exist_e) ? pc_predict[pc_e_index] - 1 : 2'b00;
            pc_buffer[pc_e_index] <= jump_address;
            pc_check[pc_e_index] <= pc_e[14:7];
        end
    end
end

//次の予測を反映させる場所
assign next_pc = (is_stall) ? pc : 
          (is_exist) ? ((pc_predict[pc_index][1]) ? pc_buffer[pc_index] : pc + 4) : pc + 4;
    
endmodule