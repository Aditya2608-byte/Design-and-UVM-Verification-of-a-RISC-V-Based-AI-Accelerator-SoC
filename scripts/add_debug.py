with open("rtl/core/riscv_core.sv", "r") as f:
    text = f.read()

target = "  always_ff @(posedge clk or negedge rst_n) begin\n    if (!rst_n) begin\n      pc_reg <= RESET_ADDR;"
debug_code = """  always @(posedge clk) begin
    if (rst_n && pc_reg >= 32'h0000_0088 && pc_reg <= 32'h0000_00B0) begin
      $display("[DEBUG_CORE] PC: %h pc_next: %h br: %b taken: %b op_a: %h op_b: %h stall: %b if_id_instr: %h",
               pc_reg, pc_next, branch, branch_taken, branch_op_a, branch_op_b, pipeline_stall, if_id_instr);
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      pc_reg <= RESET_ADDR;"""

text = text.replace(target, debug_code)
with open("rtl/core/riscv_core.sv", "w") as f:
    f.write(text)
print("Added debug prints to riscv_core.sv")
