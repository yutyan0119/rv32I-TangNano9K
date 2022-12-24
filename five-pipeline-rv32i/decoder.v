`include "define.vh"
module decoder (
    input wire[31:0] opcode,
    output wire [4:0] r_addr1, r_addr2, w_addr, //レジスタのアドレス
    output wire [3:0] alu_op, //aluに何をしてもらうかの出力
    output wire alu_1sel, alu_2sel, //aluの前のmuxがどのデータを取るかのセレクタ
    output wire [1:0] write_sel, //レジスタに書き込むデータを選ぶセレクタ
    output wire  r_wren, //レジスタに書き込むか
    output wire [2:0] mem_wren, //storeするときにどこに書き込むかの判別用
    output wire is_store, //storeするか
    output wire is_load,
    output wire [31:0] imm, //符号拡張などをしたimm
    output wire [1:0] pc_sel, //無条件分岐・分岐・その他を判別する
    output wire [2:0] branch_op, load_val //どの分岐命令かを指示する, どれくらいloadするかを指示する
  );
  wire [6:0] op;
  wire [2:0] funct3;
  assign funct3 = opcode[14:12];
  assign op = opcode[6:0];
  assign r_addr1 = (op == `UFORMAT_LUI) ? 5'b0 : opcode[19:15];
  assign r_addr2 = opcode[24:20];
  assign w_addr = opcode[11:7];
  assign alu_1sel = (op == `BFORMAT || op == `UFORMAT_AUIPC || op == `JALFORMAT) ? 1'b1 : 1'b0; //1がPC,0がrs1
  assign alu_2sel = (op == `RFORMAT) ? 1'b0 : 1'b1; //1がimm, 2がrs2
  assign mem_wren = (op == `SFORMAT) ? opcode[14:12] : 3'b111; //111は何も書き込まない、それ以外はfunct3
  assign is_store = (op == `SFORMAT) ? 1'b1 : 1'b0;
  assign is_load = (op == `IFORMAT_LOAD) ? 1'b1 : 1'b0;
  assign branch_op = opcode[14:12]; //funct3をそのまま使用する
  assign load_val = opcode[14:12];
  assign write_sel = (op == `IFORMAT_LOAD) ? 2'b01 :
         (op == `JALFORMAT || op == `JALRFORMAT) ? 2'b10 : 2'b00; //loadはmemoryの値を, JAL系はPC+4を, それ以外はaluの結果
  assign r_wren = (((op == `RFORMAT) && ({opcode[31],opcode[29:25]} == 6'b000000)) ||
                   ((op == `IFORMAT_ALU) && (({opcode[31:25], opcode[14:12]} == 10'b00000_00_001) || ({opcode[31], opcode[29:25], opcode[14:12]} == 9'b0_000_00_101) ||  // SLLI or SRLI or SRAI
                                            (opcode[14:12] == 3'b000) || (opcode[14:12] == 3'b010) || (opcode[14:12] == 3'b011) || (opcode[14:12] == 3'b100) || (opcode[14:12] == 3'b110) || (opcode[14:12] == 3'b111))) ||
                   (op == `IFORMAT_LOAD) || (op == `UFORMAT_LUI) || (op == `UFORMAT_AUIPC) || (op == `JALFORMAT) || (op == `JALRFORMAT)) ? 1'b1 : 1'b0;
  assign pc_sel = (op == `BFORMAT) ? 2'b01 : (op == `JALFORMAT || op == `JALRFORMAT) ? 2'b10 : 2'b00;
  assign alu_op = (op == `RFORMAT) ? {opcode[30], opcode[14:12]} : (op == `IFORMAT_ALU) ? ((opcode[14:12] == 3'b101) ? {opcode[30], opcode[14:12]} : {1'b0, opcode[14:12]}) : 4'b0; //0が加算それ以外はよしな
  wire [31:0] i_sext, s_sext, b_sext, u_sext, jal_sext;
  assign i_sext = ((op == `IFORMAT_ALU) && ((opcode[14:12] == 3'b001) || (opcode[14:12] == 3'b101))) ? {27'b0, opcode[24:20]} :  // slli,srli,sraiは別
         {{20{opcode[31]}}, opcode[31:20]}; //それ以外は純粋な符号拡張
  assign s_sext = {{20{opcode[31]}}, opcode[31:25],opcode[11:7]}; //単純な符号拡張
  assign b_sext = {{19{opcode[31]}}, opcode[31], opcode[7], opcode[30:25], opcode[11:8], 1'b0}; //単純な符号拡張（branch時）
  assign u_sext = {opcode[31:12], 12'b0}; //U型のとき
  assign jal_sext ={{11{opcode[31]}}, opcode[31], opcode[19:12], opcode[20], opcode[30:21], 1'b0}; //jal
  assign imm = ((op == `IFORMAT_ALU) || (op == `IFORMAT_LOAD) || (op == `JALRFORMAT))  ? i_sext :
         (op == `SFORMAT)        ? s_sext :
         (op == `BFORMAT)       ? b_sext :
         ((op == `UFORMAT_LUI) || (op == `UFORMAT_AUIPC)) ? u_sext :
         (op == `JALFORMAT)       ? jal_sext : 32'b0;

endmodule
