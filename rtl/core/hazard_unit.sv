// ============================================================================
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
