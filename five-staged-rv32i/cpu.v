`include "define.vh"

module cpu (
    input wire clk, cpu_resetn,
    output wire uart_tx
  );
  reg [31:0] pc;
  wire [31:0] opcode;
  rom rom(
        .clk(clk),
        .r_addr(pc),
        .r_data(opcode)
      );

  wire [4:0] r_addr1, r_addr2, w_addr;
  wire [3:0] alu_op;
  wire alu_1sel, alu_2sel;
  wire [1:0] write_sel;
  wire r_wren;
  wire [2:0] mem_wren;
  wire [31:0] imm;
  wire [1:0] pc_sel;
  wire [2:0] branch_op, load_val;
  reg [31:0] opcode_d;
  wire is_load, is_store;
  decoder decoder(
            .opcode(opcode_d),
            .r_addr1(r_addr1),
            .r_addr2(r_addr2),
            .w_addr(w_addr),
            .alu_op(alu_op),
            .alu_1sel(alu_1sel),
            .alu_2sel(alu_2sel),
            .write_sel(write_sel),
            .r_wren(r_wren),
            .mem_wren(mem_wren),
            .is_store(is_store),
            .is_load(is_load),
            .imm(imm),
            .pc_sel(pc_sel),
            .branch_op(branch_op),
            .load_val(load_val)
          );

  reg [4:0] w_addr_e, w_addr_m;
  wire [31:0] w_data_wb;
  reg r_wren_e, r_wren_m;
  wire [31:0] r_data1, r_data2;
  register_file register_file(
                  .clk(clk),
                  .r_addr1(r_addr1),
                  .r_addr2(r_addr2),
                  .w_addr(w_addr_m),
                  .w_data(w_data_wb),
                  .we(r_wren_m),
                  .r_data1(r_data1),
                  .r_data2(r_data2)
                );

  reg alu_1sel_e, alu_2sel_e;
  reg [31:0] pc_e, imm_e, r_data1_e, r_data2_e;
  wire [31:0] alu_in1, alu_in2;
  input_mx input_mux1(
             .alu_sel(alu_1sel_e),
             .reg_data(r_data1_e),
             .imm_pc(pc_e),
             .out_data(alu_in1)
           );

  input_mx input_mux2(
             .alu_sel(alu_2sel_e),
             .reg_data(r_data2_e),
             .imm_pc(imm_e),
             .out_data(alu_in2)
           );
  
  reg [3:0] alu_op_e;
  wire [31:0] alu_result;
  alu alu(
        .alu_op(alu_op_e),
        .data1(alu_in1),
        .data2(alu_in2),
        .alu_result(alu_result)
      );

  reg [2:0] branch_op_e;
  reg [1:0] pc_sel_e;
  wire is_branch;
  branch_exec branch_exec(
                .branch_op(branch_op_e),
                .data1(r_data1_e),
                .data2(r_data2_e),
                .pc_sel(pc_sel_e),
                .is_branch(is_branch)
              );

  reg [2:0] mem_wren_e, load_val_e;
  wire [31:0] r_data_mem;
  reg is_store_e, is_load_e;
  memory_controller memory_controller(
    .clk(clk),
    .is_store(is_store_e),
    .is_load(is_load_e),
    .reset(cpu_resetn),
    .mem_wren(mem_wren_e),
    .load_val(load_val_e),
    .pre_addr(alu_result),
    .w_data(r_data2_e),
    .read_data(r_data_mem),
    .uart_tx(uart_tx)
  );

  reg [1:0] write_sel_m;
  reg [31:0] alu_result_m;
  reg [31:0] pc_plus4;

  rb_mux rb_mux(
           .write_sel(write_sel_m),
           .alu_result(alu_result_m),
           .pc_plus4(pc_plus4),
           .mem_data(r_data_mem),
           .wb_data(w_data_wb)
         );

  reg is_branch_m;
  wire [31:0] next_pc;
  nextpc nextpc(
           .pc_plus4(pc_plus4),
           .alu_result(alu_result_m),
           .is_branch(is_branch_m),
           .next_pc(next_pc)
         );
  

  reg [1:0] write_sel_e;
  reg [2:0] stage;
  reg [31:0] pc_d;
  always @( posedge clk or negedge cpu_resetn )
  begin
    if (!cpu_resetn)
    begin
      pc <= 32'h100;
      stage <= 0;
    end
    else
    begin
      case (stage)
        0:
        begin //fetch stage
          stage <= 1;
        end
        1:
        begin//decode stage
          stage <= 2;
          pc_d <= pc;
          opcode_d <= opcode;
        end
        2:
        begin//execute stage
          stage <= 3;
          pc_e <= pc_d;
          alu_1sel_e <= alu_1sel;
          alu_2sel_e <= alu_2sel;
          imm_e <= imm;
          alu_op_e <= alu_op;
          branch_op_e <= branch_op;
          pc_sel_e <= pc_sel;
          mem_wren_e <= mem_wren;
          load_val_e <= load_val;
          write_sel_e <= write_sel;
          w_addr_e <= w_addr;
          r_data1_e <= r_data1;
          r_data2_e <= r_data2;
          r_wren_e <= r_wren;
          is_store_e <= is_store;
          is_load_e <= is_load;
        end
        3:
        begin//memory stage
          stage <= 4;
          alu_result_m <= alu_result;
          write_sel_m <= write_sel_e;
          pc_plus4 <= pc_e + 4;
          is_branch_m <= is_branch;
          w_addr_m <= w_addr_e;
          r_wren_m <= r_wren_e;
        end
        4:
        begin//writeback stage
          stage <= 0;
          pc <= next_pc;
          r_wren_m <= 0;
        end
        default:
          stage <= 0;
      endcase
    end
  end
endmodule
