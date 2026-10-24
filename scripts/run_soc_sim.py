import subprocess
import os
import sys

iverilog_bin = r"P:\iverilog\bin"
env = os.environ.copy()
env["PATH"] = iverilog_bin + os.pathsep + env.get("PATH", "")

files = [
    "rtl/core/riscv_pkg.sv",
    "rtl/accelerator/accelerator_pkg.sv",
    "rtl/core/alu.sv",
    "rtl/core/branch_comp.sv",
    "rtl/core/control_unit.sv",
    "rtl/core/hazard_unit.sv",
    "rtl/core/imm_gen.sv",
    "rtl/core/load_store_unit.sv",
    "rtl/core/register_file.sv",
    "rtl/core/riscv_core.sv",
    "rtl/accelerator/mac.sv",
    "rtl/accelerator/pe.sv",
    "rtl/accelerator/accumulator.sv",
    "rtl/accelerator/relu.sv",
    "rtl/accelerator/controller.sv",
    "rtl/accelerator/systolic_array.sv",
    "rtl/accelerator/accelerator.sv",
    "rtl/soc_interconnect.sv",
    "rtl/soc_sram.sv",
    "rtl/soc_top.sv",
    "tb/tb_soc_top.sv"
]

out_vvp = "sim/sim_soc.vvp"
compile_cmd = ["iverilog", "-g2012", "-I", "rtl", "-I", "rtl/core", "-I", "rtl/accelerator", "-o", out_vvp] + files

print("Compiling SoC Simulation...")
res = subprocess.run(compile_cmd, env=env, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
if res.returncode != 0:
    print("Compilation failed:")
    sys.stdout.buffer.write(res.stderr)
    sys.exit(res.returncode)

print("Running SoC Simulation...")
sim_res = subprocess.run(["vvp", out_vvp], env=env, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
sys.stdout.buffer.write(sim_res.stdout)
if sim_res.stderr:
    sys.stdout.buffer.write(sim_res.stderr)

if sim_res.returncode != 0:
    sys.exit(sim_res.returncode)
