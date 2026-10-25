with open("rtl/core/riscv_core.sv", "r") as f:
    text = f.read()

# Fix branch in pc_next
text = text.replace(
    "} else if (branch && branch_taken) begin",
    "} else if (branch && branch_taken && !pipeline_stall) begin"
)

# Fix branch_flush
text = text.replace(
    "assign branch_flush = branch && branch_taken;",
    "assign branch_flush = branch && branch_taken && !pipeline_stall;"
)

with open("rtl/core/riscv_core.sv", "w") as f:
    f.write(text)

print("Fixed branch stall handling in riscv_core.sv")
