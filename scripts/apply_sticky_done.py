with open('rtl/accelerator/accelerator.sv', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Add status_done_reg
content = content.replace(
    '    logic        reg_start_pulse;\n',
    '    logic        reg_start_pulse;\n    logic        status_done_reg;\n'
)

# 2. Reset assignment
content = content.replace(
    '            reg_start_pulse   <= 1\'b0;\n            act_en_reg        <= 1\'b0;',
    '            reg_start_pulse   <= 1\'b0;\n            status_done_reg   <= 1\'b0;\n            act_en_reg        <= 1\'b0;'
)

# 3. Setting/clearing status_done_reg in clocked block
content = content.replace(
    "            reg_start_pulse <= 1'b0; // Single cycle pulse\n            if (reg_we) begin",
    "            reg_start_pulse <= 1'b0; // Single cycle pulse\n            if (ctrl_start) begin\n                status_done_reg <= 1'b0;\n            end else if (ctrl_done) begin\n                status_done_reg <= 1'b1;\n            end\n            if (reg_we) begin"
)

# 4. Clear on start write or W1C
content = content.replace(
    "                    REG_CTRL: begin\n                        if (reg_wdata[CTRL_START_BIT]) begin\n                            reg_start_pulse <= 1'b1;\n                        end",
    "                    REG_CTRL: begin\n                        if (reg_wdata[CTRL_START_BIT]) begin\n                            reg_start_pulse <= 1'b1;\n                            status_done_reg <= 1'b0;\n                        end"
)

content = content.replace(
    "                    REG_CFG_ACT: act_en_reg <= reg_wdata[CFG_ACT_RELU_BIT];",
    "                    REG_STATUS: begin\n                        if (reg_wdata[STATUS_DONE_BIT]) begin\n                            status_done_reg <= 1'b0;\n                        end\n                    end\n                    REG_CFG_ACT: act_en_reg <= reg_wdata[CFG_ACT_RELU_BIT];"
)

# 5. Read multiplexer for REG_STATUS
content = content.replace(
    "REG_STATUS:      reg_rdata = {29'd0, ctrl_error, ctrl_busy, ctrl_done};",
    "REG_STATUS:      reg_rdata = {29'd0, ctrl_error, ctrl_busy, (ctrl_done | status_done_reg)};"
)

# 6. IRQ output
content = content.replace(
    "assign irq   = ctrl_done;",
    "assign irq   = ctrl_done | status_done_reg;"
)

with open('rtl/accelerator/accelerator.sv', 'w', encoding='utf-8') as f:
    f.write(content)

print("Updated rtl/accelerator/accelerator.sv successfully!")
