with open("rtl/soc_sram.sv", "r") as f:
    text = f.read()

text = text.replace('`ifdef SYNTHESIS', '`if defined(SYNTHESIS) || defined(ALTERA_RESERVED_QIS) || defined(QUARTUS_SYNTHESIS)')
text = text.replace('parameter     INIT_FILE      = "sim/firmware.mif"', 'parameter     INIT_FILE      = "firmware.mif"')

with open("rtl/soc_sram.sv", "w") as f:
    f.write(text)

with open("rtl/de10_lite_top.sv", "r") as f:
    top_text = f.read()

top_text = top_text.replace('parameter INIT_FILE = "sim/firmware.mif"', 'parameter INIT_FILE = "firmware.mif"')
with open("rtl/de10_lite_top.sv", "w") as f:
    f.write(top_text)

with open("de10_lite.qsf", "r") as f:
    qsf_text = f.read()

qsf_additions = """set_global_assignment -name NUM_PARALLEL_PROCESSORS 12
set_global_assignment -name VERILOG_MACRO "SYNTHESIS=1"
set_global_assignment -name MIF_FILE firmware.mif
"""
if "SYNTHESIS=1" not in qsf_text:
    qsf_text = qsf_additions + qsf_text
    with open("de10_lite.qsf", "w") as f:
        f.write(qsf_text)

print("Updated soc_sram.sv, de10_lite_top.sv, and de10_lite.qsf")
