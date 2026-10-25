with open("rtl/core/riscv_core.sv", "r") as f:
    text = f.read()

debug_block = """  always @(posedge clk) begin
    if (rst_n && pc_reg >= 32'h0000_0088 && pc_reg <= 32'h0000_00B0) begin
      $display("[DEBUG_CORE] PC: %h pc_next: %h br: %b taken: %b op_a: %h op_b: %h stall: %b if_id_instr: %h",
               pc_reg, pc_next, branch, branch_taken, branch_op_a, branch_op_b, pipeline_stall, if_id_instr);
    end
  end

"""
text = text.replace(debug_block, "")
with open("rtl/core/riscv_core.sv", "w") as f:
    f.write(text)

print("Removed debug print from riscv_core.sv")
