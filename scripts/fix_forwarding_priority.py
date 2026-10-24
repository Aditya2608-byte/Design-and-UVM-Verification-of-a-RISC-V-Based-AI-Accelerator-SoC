with open('rtl/core/riscv_core.sv', 'r', encoding='utf-8') as f:
    content = f.read()

# Fix branch forwarding priority
old_branch = """    // Forward the final WB value.
    if (mem_wb_reg_write &&
        (mem_wb_rd != 5'd0) && (mem_wb_rd == rs1)) begin
      branch_op_a = wb_data;
    end

    if (mem_wb_reg_write &&
        (mem_wb_rd != 5'd0) && (mem_wb_rd == rs2)) begin
      branch_op_b = wb_data;
    end"""

new_branch = """    // Forward the final WB value only if not already forwarded from EX/MEM
    else if (mem_wb_reg_write &&
        (mem_wb_rd != 5'd0) && (mem_wb_rd == rs1)) begin
      branch_op_a = wb_data;
    end

    if (!(ex_mem_reg_write && !ex_mem_mem_read && (ex_mem_rd != 5'd0) && (ex_mem_rd == rs2))) begin
      if (mem_wb_reg_write &&
          (mem_wb_rd != 5'd0) && (mem_wb_rd == rs2)) begin
        branch_op_b = wb_data;
      end
    end"""

# Let's inspect exact text in riscv_core.sv
print("Branch text in content:", old_branch in content)

# Fix EX-stage forwarding priority
old_ex = """    // Forward from MEM/WB
    if (mem_wb_reg_write && (mem_wb_rd != 5'd0) &&
        (mem_wb_rd == id_ex_rs1)) begin
      forward_a_data = wb_data;
    end

    if (mem_wb_reg_write && (mem_wb_rd != 5'd0) &&
        (mem_wb_rd == id_ex_rs2)) begin
      forward_b_data = wb_data;
    end"""

print("EX text in content:", old_ex in content)
