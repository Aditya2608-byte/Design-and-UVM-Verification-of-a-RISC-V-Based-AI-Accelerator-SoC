import os

with open("README.md", "r", encoding="utf-8") as f:
    content = f.read()

# Update badges
old_badges = """![SystemVerilog](https://img.shields.io/badge/Language-SystemVerilog%20%7C%20Python-blue?style=for-the-badge&logo=verilog)
![Target Architecture](https://img.shields.io/badge/Architecture-RISC--V%20RV32IM%20SoC-red?style=for-the-badge&logo=riscv)
![Verification](https://img.shields.io/badge/Verification-100%25%20Passing-brightgreen?style=for-the-badge)
![Speedup](https://img.shields.io/badge/Performance-105.6x%20vs%20Scalar%20CPU-orange?style=for-the-badge)
![Status](https://img.shields.io/badge/Milestone%201-Phase%201%20Complete-success?style=for-the-badge)"""

new_badges = """![SystemVerilog](https://img.shields.io/badge/Language-SystemVerilog%20%7C%20Python-blue?style=for-the-badge&logo=verilog)
![Target Architecture](https://img.shields.io/badge/Architecture-RISC--V%20RV32IM%20SoC-red?style=for-the-badge&logo=riscv)
![Target FPGA](https://img.shields.io/badge/FPGA-Terasic%20DE10--Lite%20(MAX%2010)-purple?style=for-the-badge)
![Verification](https://img.shields.io/badge/Verification-100%25%20Full%20SoC%20Pass-brightgreen?style=for-the-badge)
![Status](https://img.shields.io/badge/Hardware-Ready%20for%20Review%20(Oct%202026)-success?style=for-the-badge)"""

assert old_badges in content, "old_badges not found"
content = content.replace(old_badges, new_badges)

# Update roadmap
old_roadmap = """## 🚀 11. Project Roadmap

### Milestone 1: Phase 1 (100% Completed)
- [x] Synthesizable SystemVerilog 4x4 INT8 Systolic / Processing Array.
- [x] INT32 Accumulation preventing arithmetic overflow.
- [x] Hardware ReLU Activation unit.
- [x] 6-state Moore/Mealy Controller FSM.
- [x] Self-checking SystemVerilog testbenches with 100% pass rate.
- [x] Python NumPy golden reference model and cycle benchmark suite.
- [x] Waveform generation and GTKWave timing inspection.

### Milestone 2: Phase 2 (Planned SoC Integration)
- [ ] **Interconnect Bus Wrapper:** APB / AXI4-Lite slave interface.
- [ ] **RISC-V CPU Core:** Open-source RV32IM core (Ibex / CV32E40P).
- [ ] **Shared Memory:** Tightly-Coupled Memory (TCM) subsystem for matrix streaming.
- [ ] **Firmware Library:** C driver / HAL library for memory-mapped accelerator routines.
- [ ] **UVM Environment:** Advanced UVM verification with constrained-random stimulus and functional coverage."""

new_roadmap = """## 🚀 11. Project Roadmap & Implementation Milestones

### Milestone 1: AI Accelerator Core (100% Completed)
- [x] Synthesizable SystemVerilog 4x4 INT8 Systolic / Processing Array.
- [x] INT32 Accumulation preventing arithmetic overflow.
- [x] Hardware ReLU Activation unit.
- [x] 6-state Moore/Mealy Controller FSM with sticky MMIO status register.
- [x] Self-checking SystemVerilog unit testbenches (100% pass rate).
- [x] Python NumPy golden reference model and benchmark suite.

### Milestone 2: Full SoC Integration & Verification (100% Completed)
- [x] **Pipelined RV32IM CPU Core:** 5-stage hazard-controlled RISC-V core with hardware multiplier/divider and forward-priority logic.
- [x] **Memory Crossbar & Interconnect:** Address-decoded bus router separating SRAM (`0x0000_0000..0x0000_3FFF`) and Accelerator MMIO (`0x4000_0000..0x4000_03FF`).
- [x] **16 KB Dual-Port SRAM Subsystem:** Instruction ROM/RAM and data RAM with byte-enable strobes.
- [x] **Firmware & Assembler:** 54-instruction verification bootloader and end-to-end C inference routine (`nn_demo.c`).
- [x] **Full SoC End-to-End Simulation:** Verified in 88 clock cycles with 0 errors; signature `0xCAFEBABE` written to `0x0000_10FC`.
- [x] **Regression Test Suite:** 100% pass rate across ALU, Register File, Immediate Gen, Hazard Unit, RISC-V Core, and Accelerator.

### Milestone 3: FPGA Physical Implementation & Hardware Bring-Up (100% Completed)
- [x] **Target FPGA:** Terasic DE10-Lite (Intel MAX 10 `10M50DAF484C7G`).
- [x] **Board-Level Top Wrapper (`rtl/de10_lite_top.sv`):** Interfaces with 50 MHz clock, reset button `KEY[0]`, status LEDs `LEDR[9:0]`, and 7-segment displays `HEX5..0`.
- [x] **Quartus Prime Project & Constraints:** Complete `.qpf`, `.qsf` pin mapping, and `.sdc` 50 MHz timing constraints.
- [x] **Live Review Hardware Demo:** `LEDR[4]` asserts upon `0xCAFEBABE` signature match; 7-segment display shows `b A b E` when `SW[0]=1`.
- [x] **Hardware Bring-Up Documentation:** [`reports/DE10_LITE_BRINGUP_GUIDE.md`](reports/DE10_LITE_BRINGUP_GUIDE.md) and [`reports/SOC_IMPLEMENTATION_AND_VERIFICATION_REPORT.md`](reports/SOC_IMPLEMENTATION_AND_VERIFICATION_REPORT.md)."""

assert old_roadmap in content, "old_roadmap not found"
content = content.replace(old_roadmap, new_roadmap)

with open("README.md", "w", encoding="utf-8", newline="") as f:
    f.write(content)

print("Successfully updated README.md")
