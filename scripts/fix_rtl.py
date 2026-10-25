import os

# 1. Fix rtl/accelerator/accelerator.sv
with open("rtl/accelerator/accelerator.sv", "r") as f:
    acc_text = f.read()

acc_text = acc_text.replace("integer r_init, c_init;\n", "")
acc_text = acc_text.replace("for (r_init = 0;", "for (int r_init = 0;")
acc_text = acc_text.replace("for (c_init = 0;", "for (int c_init = 0;")

acc_text = acc_text.replace("integer r_idx, c_idx;\n", "")
acc_text = acc_text.replace("for (r_idx = 0;", "for (int r_idx = 0;")
acc_text = acc_text.replace("for (c_idx = 0;", "for (int c_idx = 0;")

with open("rtl/accelerator/accelerator.sv", "w") as f:
    f.write(acc_text)
print("[1/4] Fixed accelerator.sv latches.")

# 2. Fix rtl/core/hazard_unit.sv
hazard_unit_code = """// ============================================================================
// File: rtl/core/hazard_unit.sv
// Description: Load-use and Branch Hazard Detection for 5-stage RV32I Pipeline
// ============================================================================

module hazard_unit (
  input  logic        id_ex_mem_read,
  input  logic [4:0]  id_ex_rd,

  input  logic        ex_mem_mem_read,
  input  logic [4:0]  ex_mem_rd,

  input  logic [4:0]  if_id_rs1,
  input  logic [4:0]  if_id_rs2,

  input  logic        if_id_branch,
  input  logic        id_ex_reg_write,

  output logic        stall
);

  always_comb begin
    stall = 1'b0;

    // 1. Stall while load is in ID/EX and dependent instruction in IF/ID
    if (id_ex_mem_read &&
        (id_ex_rd != 5'd0) &&
        ((id_ex_rd == if_id_rs1) ||
         (id_ex_rd == if_id_rs2))) begin
      stall = 1'b1;
    end

    // 2. Keep dependent instruction stalled while load is in EX/MEM
    if (ex_mem_mem_read &&
        (ex_mem_rd != 5'd0) &&
        ((ex_mem_rd == if_id_rs1) ||
         (ex_mem_rd == if_id_rs2))) begin
      stall = 1'b1;
    end

    // 3. Branch hazard: Stall branch in ID if previous instruction in ID/EX produces operand
    if (if_id_branch && id_ex_reg_write &&
        (id_ex_rd != 5'd0) &&
        ((id_ex_rd == if_id_rs1) ||
         (id_ex_rd == if_id_rs2))) begin
      stall = 1'b1;
    end
  end

endmodule
"""
with open("rtl/core/hazard_unit.sv", "w") as f:
    f.write(hazard_unit_code)
print("[2/4] Fixed hazard_unit.sv branch hazard stall.")

# 3. Fix rtl/core/riscv_core.sv
with open("rtl/core/riscv_core.sv", "r") as f:
    core_text = f.read()

# Fix hazard_unit instantiation
old_hu_inst = """.if_id_rs1       (rs1),
    .if_id_rs2       (rs2),
    .stall            (pipeline_stall)"""
new_hu_inst = """.if_id_rs1       (rs1),
    .if_id_rs2       (rs2),
    .if_id_branch    (branch),
    .id_ex_reg_write (id_ex_reg_write),
    .stall           (pipeline_stall)"""
assert old_hu_inst in core_text, "hazard_unit inst not found in riscv_core.sv"
core_text = core_text.replace(old_hu_inst, new_hu_inst)

# Fix forward_a_data & forward_b_data
old_fwd = """    // Forward from EX/MEM (takes priority over MEM/WB)
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

new_fwd = """    // Forward from EX/MEM (takes priority over MEM/WB).
    // Do not forward from EX/MEM if instruction in EX/MEM is a load.
    if (ex_mem_reg_write && !ex_mem_mem_read && (ex_mem_rd != 5'd0) &&
        (ex_mem_rd == id_ex_rs1)) begin
      forward_a_data = ex_mem_alu_res;
    end else if (mem_wb_reg_write && (mem_wb_rd != 5'd0) &&
        (mem_wb_rd == id_ex_rs1)) begin
      forward_a_data = wb_data;
    end

    if (ex_mem_reg_write && !ex_mem_mem_read && (ex_mem_rd != 5'd0) &&
        (ex_mem_rd == id_ex_rs2)) begin
      forward_b_data = ex_mem_alu_res;
    end else if (mem_wb_reg_write && (mem_wb_rd != 5'd0) &&
        (mem_wb_rd == id_ex_rs2)) begin
      forward_b_data = wb_data;
    end"""
assert old_fwd in core_text, "forwarding logic not found in riscv_core.sv"
core_text = core_text.replace(old_fwd, new_fwd)

# Fix instr_addr
old_ia = "assign instr_addr = pc_reg;"
new_ia = "assign instr_addr = (!rst_n) ? RESET_ADDR : (pipeline_stall ? pc_reg : pc_next);"
assert old_ia in core_text, "instr_addr not found in riscv_core.sv"
core_text = core_text.replace(old_ia, new_ia)

with open("rtl/core/riscv_core.sv", "w") as f:
    f.write(core_text)
print("[3/4] Fixed riscv_core.sv hazard forwarding and fetch addressing.")

# 4. Fix rtl/de10_lite_top.sv INIT_FILE
with open("rtl/de10_lite_top.sv", "r") as f:
    top_text = f.read()

top_text = top_text.replace('parameter INIT_FILE = "sim/firmware.hex"', 'parameter INIT_FILE = "sim/firmware.mif"')
with open("rtl/de10_lite_top.sv", "w") as f:
    f.write(top_text)
print("[4/4] Updated de10_lite_top.sv default INIT_FILE to sim/firmware.mif.")
