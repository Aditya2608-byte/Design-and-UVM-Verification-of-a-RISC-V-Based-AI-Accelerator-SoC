import os

file_path = "rtl/core/riscv_core.sv"
with open(file_path, "r", encoding="utf-8") as f:
    text = f.read()

# Branch forwarding replacement
old_branch = """    // Forward ALU result from EX/MEM.
    // Do not forward EX/MEM for a load because the load data is not
    // available until the MEM/WB stage.
    if (ex_mem_reg_write && !ex_mem_mem_read &&
        (ex_mem_rd != 5'd0) && (ex_mem_rd == rs1)) begin
      branch_op_a = ex_mem_alu_res;
    end

    if (ex_mem_reg_write && !ex_mem_mem_read &&
        (ex_mem_rd != 5'd0) && (ex_mem_rd == rs2)) begin
      branch_op_b = ex_mem_alu_res;
    end

    // Forward the final WB value.
    if (mem_wb_reg_write &&
        (mem_wb_rd != 5'd0) && (mem_wb_rd == rs1)) begin
      branch_op_a = wb_data;
    end

    if (mem_wb_reg_write &&
        (mem_wb_rd != 5'd0) && (mem_wb_rd == rs2)) begin
      branch_op_b = wb_data;
    end"""

new_branch = """    // Forward ALU result from EX/MEM (takes priority over MEM/WB).
    // Do not forward EX/MEM for a load because the load data is not
    // available until the MEM/WB stage.
    if (ex_mem_reg_write && !ex_mem_mem_read &&
        (ex_mem_rd != 5'd0) && (ex_mem_rd == rs1)) begin
      branch_op_a = ex_mem_alu_res;
    end else if (mem_wb_reg_write &&
        (mem_wb_rd != 5'd0) && (mem_wb_rd == rs1)) begin
      branch_op_a = wb_data;
    end

    if (ex_mem_reg_write && !ex_mem_mem_read &&
        (ex_mem_rd != 5'd0) && (ex_mem_rd == rs2)) begin
      branch_op_b = ex_mem_alu_res;
    end else if (mem_wb_reg_write &&
        (mem_wb_rd != 5'd0) && (mem_wb_rd == rs2)) begin
      branch_op_b = wb_data;
    end"""

# EX forwarding replacement
old_ex = """    // Forward from EX/MEM
    if (ex_mem_reg_write && (ex_mem_rd != 5'd0) &&
        (ex_mem_rd == id_ex_rs1)) begin
      forward_a_data = ex_mem_alu_res;
    end

    if (ex_mem_reg_write && (ex_mem_rd != 5'd0) &&
        (ex_mem_rd == id_ex_rs2)) begin
      forward_b_data = ex_mem_alu_res;
    end 

    // Forward from MEM/WB
    if (mem_wb_reg_write && (mem_wb_rd != 5'd0) &&
        (mem_wb_rd == id_ex_rs1)) begin
      forward_a_data = wb_data;
    end

    if (mem_wb_reg_write && (mem_wb_rd != 5'd0) &&
        (mem_wb_rd == id_ex_rs2)) begin
      forward_b_data = wb_data;
    end"""

new_ex = """    // Forward from EX/MEM (takes priority over MEM/WB)
    if (ex_mem_reg_write && (ex_mem_rd != 5'd0) &&
        (ex_mem_rd == id_ex_rs1)) begin
      forward_a_data = ex_mem_alu_res;
    end else if (mem_wb_reg_write && (mem_wb_rd != 5'd0) &&
        (mem_wb_rd == id_ex_rs1)) begin
      forward_a_data = wb_data;
    end

    if (ex_mem_reg_write && (ex_mem_rd != 5'd0) &&
        (ex_mem_rd == id_ex_rs2)) begin
      forward_b_data = ex_mem_alu_res;
    end else if (mem_wb_reg_write && (mem_wb_rd != 5'd0) &&
        (mem_wb_rd == id_ex_rs2)) begin
      forward_b_data = wb_data;
    end"""

assert old_branch in text, "old_branch target not found!"
text = text.replace(old_branch, new_branch)

assert old_ex in text, "old_ex target not found!"
text = text.replace(old_ex, new_ex)

with open(file_path, "w", encoding="utf-8", newline="") as f:
    f.write(text)

print("Successfully applied forwarding priority fixes to", file_path)
