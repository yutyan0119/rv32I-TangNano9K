`include "define.vh"

module cpu (
    input wire clk, cpu_resetn,
    output wire uart_tx
  );
  reg [31:0] pc, pc_wb;
  wire [31:0] opcode;
  rom rom(
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
  reg r_wren_e, r_wren_m, r_wren_wb;
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

  reg alu_1sel_e, alu_2sel_e, is_stall_e1, is_stall_e2;
  reg [31:0] pc_e, imm_e, r_data1_e, r_data2_e;
  wire [31:0] alu_in1, alu_in2;
  wire [31:0] after_forward1, after_forward2;
  wire [31:0] r_data_mem;
  reg is_raw_e1, mem_raw1_e;
  reg is_raw_e2, mem_raw2_e;
  reg [31:0] alu_result_m;
  reg [31:0] r_data_mem_forw;
  wire [31:0] alu_result;
  reg is_store_e, is_load_e;
  wire is_raw1 = ((r_addr1 == w_addr_e) && (w_addr_e != 5'b0) && r_wren_e && !is_load_e ); //RAWハザード対策.ストールが必要なものを除く
  wire is_raw2 = ((r_addr2 == w_addr_e) && (w_addr_e != 5'b0) && r_wren_e && !is_load_e ); //RAWハザード対策.ただし、ストールが必要なものを除く
  wire mem_raw1 = ((r_addr1 == w_addr_m) && (w_addr_m != 5'b0) && r_wren_m); //RAWハザード対策.ただし、ストールが必要なものを除く
  wire mem_raw2 = ((r_addr2 == w_addr_m) && (w_addr_m != 5'b0) && r_wren_m); //RAWハザード対策.ただし、ストールが必要なものを除く
  reg is_stall_d1, is_stall_d2;
  forwarding forward1(
    .is_raw(is_raw1),
    .is_stall(is_stall_d1),
    .is_mem_raw(mem_raw1),
    .r_data(r_data1),
    .alu_result(alu_result),
    .mem_result(w_data_wb),
    .forward_result(after_forward1)
  );

  forwarding forward2(
    .is_raw(is_raw2),
    .is_stall(is_stall_d2),
    .is_mem_raw(mem_raw2),
    .r_data(r_data2),
    .alu_result(alu_result),
    .mem_result(w_data_wb),
    .forward_result(after_forward2)
  );

  reg [31:0] after_forward1_e, after_forward2_e;
  reg [31:0] pc_d;
  input_mx input_mux1(
             .alu_sel(alu_1sel),
             .reg_data(after_forward1),
             .imm_pc(pc_d),
             .out_data(alu_in1)
           );

  input_mx input_mux2(
             .alu_sel(alu_2sel),
             .reg_data(after_forward2),
             .imm_pc(imm),
             .out_data(alu_in2)
           );
  
  reg [31:0] alu_in1_e, alu_in2_e;
  reg [3:0] alu_op_e;
  alu alu(
        .alu_op(alu_op_e),
        .data1(alu_in1_e),
        .data2(alu_in2_e),
        .alu_result(alu_result)
      );

  reg [2:0] branch_op_e;
  reg [1:0] pc_sel_e;
  wire is_branch;
  branch_exec branch_exec(
                .branch_op(branch_op_e),
                .data1(after_forward1_e),
                .data2(after_forward2_e),
                .pc_sel(pc_sel_e),
                .is_branch(is_branch)
              );
  wire is_stall1 = (r_addr1 == w_addr_e) && (w_addr_e != 5'b0) && r_wren_e && is_load_e; //RAWハザード対策(load命令用)この場合はstallをしないといけない
  wire is_stall2 = (r_addr2 == w_addr_e) && (w_addr_e != 5'b0) && r_wren_e && is_load_e; //RAWハザード対策(load命令用)この場合はstallをしないといけない
  wire is_stall = is_stall1 | is_stall2;
  // wire is_flash = is_branch & !is_flash_e;
  wire is_flash =  (is_valid_e == 1'b0 || is_flash_e == 1'b1) ? 1'b0 : (is_branch) ? (pc_d != alu_result) : (pc_d != pc_e + 4);


  reg [2:0] mem_wren_e, load_val_e, load_val_m;
  wire [31:0] mem_addr = alu_in1_e + alu_in2_e;

  wire [31:0] counter;
  reg is_load_m;
  wire [31:0] filtered_data;
  reg is_flash_e;
  memory_controller memory_controller(
  .clk(clk),
  .is_store(is_store_e),
  .is_load(is_load_e),
  .is_flash_e(is_flash_e),
  .reset(cpu_resetn),
  .mem_wren(mem_wren_e),
  .ram_addr(mem_addr),
  .w_data(after_forward2_e),
  .counter(counter),
  .uart_tx(uart_tx),
  .r_data_mem(r_data_mem)
);

filter_data filter_data(
  .r_data(r_data_mem),
  .r_addr(alu_result_m),
  .counter(counter),
  .is_load(is_load_m),
  .load_val(load_val_m),
  .read_data(filtered_data)
);

  reg [1:0] write_sel_m;
  reg [31:0] pc_plus4;
  
  rb_mux rb_mux(
           .write_sel(write_sel_m),
           .alu_result(alu_result_m),
           .pc_plus4(pc_plus4),
           .mem_data(filtered_data),
           .wb_data(w_data_wb)
         );

  reg is_branch_m;
  

  reg [1:0] write_sel_e;
  reg [31:0] pc_m;

  wire [31:0] next_pc;
  wire is_stall_d = is_stall_d1 | is_stall_d2;
  predictor predictor(
    .clk(clk),
    .pc(pc),
    .pc_e(pc_e),
    .pc_sel(pc_sel_e),
    .is_branch(is_branch),
    .jump_address(alu_result),
    .is_stall(is_stall),
    .next_pc(next_pc)
  );
  reg is_valid_d, is_valid_e;
  always @( posedge clk )
  begin
    if (!cpu_resetn)
    begin
      pc <= 32'h100;
      pc_d <= 32'h9c;
      pc_e <= 32'h98;
      pc_m <= 32'h94;
      pc_wb <= 32'h90;
      is_flash_e <= 1'b0;
      is_branch_m <= 1'b0;
      is_valid_d <= 1'b0;
      is_valid_e <= 1'b0;
      opcode_d <= `NOP;
      alu_1sel_e <= 1'b0; //reg
      alu_2sel_e <= 1'b0; //reg
      imm_e <= 32'b0;
      alu_op_e <= 4'b0; //add
      branch_op_e <= 3'b010; //no branch
      pc_sel_e <= 2'b0; // pc + 4
      mem_wren_e <= 3'b111; // no write
      load_val_e <= 3'b111; // no load
      write_sel_e <= 2'b00; // write to register
      w_addr_e <= 5'b0; //0 register 
      r_data1_e <= 32'b0; //0
      r_data2_e <= 32'b0; //0
      r_wren_e <= 1'b0; //no write
      is_store_e <= 1'b0; //no store
      is_load_e <= 1'b0; //no load
      is_raw_e1 <= 1'b0; //no raw
      is_raw_e2 <= 1'b0; //no raw
    end
    else begin
      //fetch stage
      //decode stage
      is_stall_d1 <= is_stall1;
      is_stall_d2 <= is_stall2;
      if(is_flash_e) begin
          opcode_d <= `NOP;
          is_valid_d <= 1'b0;
      end else if (is_stall) begin end
      else begin
          pc_d <= pc;
          opcode_d <= opcode;
          is_valid_d <= 1'b1;
      end
      //execute stage
      if (!is_stall && !is_flash_e)begin
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
          is_raw_e1 <= is_raw1;
          is_raw_e2 <= is_raw2;
          is_stall_e1 <= is_stall_d1;
          is_stall_e2 <= is_stall_d2;
          mem_raw1_e <= mem_raw1;
          mem_raw2_e <= mem_raw2;
          after_forward1_e <= after_forward1;
          after_forward2_e <= after_forward2;
          alu_in1_e <= alu_in1;
          alu_in2_e <= alu_in2;
          is_flash_e <= is_flash;
          is_valid_e <= is_valid_d;
      end else begin
          alu_1sel_e <= 1'b0; //reg
          alu_2sel_e <= 1'b0; //reg
          imm_e <= 32'b0;
          alu_op_e <= 4'b0; //add
          branch_op_e <= 3'b010; //no branch
          pc_sel_e <= 2'b0; // pc + 4
          mem_wren_e <= 3'b111; // no write
          load_val_e <= 3'b111; // no load
          write_sel_e <= 2'b00; // write to register
          w_addr_e <= 5'b0; //0 register 
          r_data1_e <= 32'b0; //0
          r_data2_e <= 32'b0; //0
          r_wren_e <= 1'b0; //no write
          is_store_e <= 1'b0; //no store
          is_load_e <= 1'b0; //no load
          is_raw_e1 <= 1'b0; //no raw
          is_raw_e2 <= 1'b0; //no raw
          is_flash_e <= is_flash;
          is_valid_e <= 1'b0;
      end
      //memory stage
        if(is_flash_e)begin
          pc_m <= pc_e;
          w_addr_m <= 5'b0;
          r_wren_m <= 1'b0;
          load_val_m <= 3'b111;
          write_sel_m <= 2'b0;
          is_branch_m <= 1'b0;
        end else begin
          pc_m <= pc_e;
          alu_result_m <= alu_result;
          write_sel_m <= write_sel_e;
          pc_plus4 <= pc_e + 4;
          is_branch_m <= is_branch;
          w_addr_m <= w_addr_e;
          r_wren_m <= r_wren_e;
          load_val_m <= load_val_e;
          is_load_m <= is_load_e;
        end
      //writeback stage
          r_data_mem_forw <= w_data_wb;
          pc_wb <= pc_m;
          if (!is_stall &&!is_flash_e)begin
            pc <= next_pc;
          end
          else if (is_flash_e) begin
            pc <= (is_branch_m) ? alu_result_m : pc_m + 4;
          end
    end
  end
endmodule