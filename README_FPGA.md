# RISC-V SoC + 4×4 INT8 AI Accelerator — DE10-Lite FPGA Guide

**Board:** Terasic DE10-Lite  
**FPGA Device:** Intel MAX 10 `10M50DAF484C7G`  
**EDA Software:** Intel Quartus Prime Lite Edition 25.1std, ModelSim-Altera 10.5b  
**Git Branch:** `fpga_de10_lite_dev`  

---

## 1. Project Overview

This repository implements a full System-on-Chip (SoC) combining:
- A 5-stage pipelined **RISC-V RV32IM CPU** with hardware multiplication and division.
- A **4×4 INT8 Systolic Array AI Accelerator** with INT32 accumulation and programmable ReLU activation.
- A **16 KB Dual-Port Synchronous SRAM** mapped directly to Intel MAX 10 M9K Block RAM.
- A **DE10-Lite Board Top-Level Wrapper** with reset debouncing, LED status indicators, and 7-segment hex display decoders.

---

## 2. Environment Prerequisites

- **Host OS:** Windows 10 / 11 64-bit
- **Intel Quartus Prime Lite 25.1std:** `C:\altera_lite\25.1std\quartus\bin64\`
- **ModelSim-Altera Starter Edition 10.5b:** `C:\intelFPGA\18.1\modelsim_ase\win32aloem\`
- **Python 3.8+:** for script automation and MIF generation

> **Important Note regarding Windows path names:**  
> If your project path contains single apostrophes (e.g., `c:\Adi's Proj\`), Quartus CLI will report `Error (125086)`. To avoid this, mount a virtual drive letter `P:` using:
> ```powershell
> subst P: "c:\Adi's Proj\ASIC_Proj"
> cd P:\risc_V_project
> ```

---

## 3. How to Run Simulation (ModelSim)

To run the complete self-checking testbench in ModelSim:

```powershell
cd P:\risc_V_project

# Compile and run SoC Top Integration Test
& "C:\intelFPGA\18.1\modelsim_ase\win32aloem\vsim.exe" -c -do "vlib work; vlog -sv rtl/soc_sram.sv rtl/core/*.sv rtl/accelerator/*.sv rtl/soc_top.sv tb/tb_soc_top.sv; vsim -c -voptargs=+acc work.tb_soc_top -do \"run -all; quit -f\""

# Compile and run DE10-Lite Board Top Testbench
& "C:\intelFPGA\18.1\modelsim_ase\win32aloem\vsim.exe" -c -do "vlib work; vlog -sv rtl/soc_sram.sv rtl/core/*.sv rtl/accelerator/*.sv rtl/soc_top.sv rtl/de10_lite_top.sv tb/tb_de10_lite_top.sv; vsim -c -voptargs=+acc work.tb_de10_lite_top -do \"run -all; quit -f\""
```

**Expected Result:** All 16 accelerator matrix elements match, and `🏆 SUCCESS: DE10-Lite Top Verified Signature 0xCAFEBABE!` is printed.

---

## 4. How to Compile the FPGA Design (Quartus CLI)

To run the full synthesis, fitting, timing, and bitstream generation pipeline:

```powershell
cd P:\risc_V_project

# 1. Analysis & Synthesis (Map)
& "C:\altera_lite\25.1std\quartus\bin64\quartus_map.exe" de10_lite

# 2. Place & Route (Fitter)
& "C:\altera_lite\25.1std\quartus\bin64\quartus_fit.exe" de10_lite

# 3. Static Timing Analysis (STA)
& "C:\altera_lite\25.1std\quartus\bin64\quartus_sta.exe" de10_lite

# 4. Assembler (Generate .SOF and .POF Bitstreams)
& "C:\altera_lite\25.1std\quartus\bin64\quartus_asm.exe" de10_lite
```

Bitstreams are placed in:
- `output_files/de10_lite.sof` (SRAM Object File for JTAG)
- `output_files/de10_lite.pof` (Programmer Object File for non-volatile flash)

---

## 5. How to Program the DE10-Lite FPGA Board

1. Connect the DE10-Lite board to your computer using the USB Type-B cable.
2. Check that the Intel USB-Blaster is detected:
   ```powershell
   & "C:\altera_lite\25.1std\quartus\bin64\jtagconfig.exe"
   ```
   *Expected output: `1) USB-Blaster [USB-0] ... 10M50DA(.|ES)/10M50DC`*
3. Program the FPGA SRAM directly via JTAG:
   ```powershell
   & "C:\altera_lite\25.1std\quartus\bin64\quartus_pgm.exe" -m jtag -c USB-Blaster -o "p;output_files/de10_lite.sof"
   ```

---

## 6. Hardware Demonstration & Verification Checklist

Once programmed, observe the board controls and indicators:

### 1. Visual Indicators:
- **`LEDR[9]` (Heartbeat):** Blinks continuously at ~1.5 Hz, verifying that the 50 MHz system clock oscillator and PLL are active.
- **`LEDR[0]` (Accel Done):** Illuminates when the 4×4 INT8 systolic array finishes computing matrix multiplication.
- **`LEDR[1]` (Accel Busy):** Briefly flashes during matrix multiplication execution.
- **`LEDR[4]` (Success Signature):** **Turns ON solidly when the golden signature `0xCAFEBABE` is verified in SRAM!**
- **`LEDR[8]` (Reset):** Illuminates when `KEY[0]` is pressed.

### 2. User Controls:
- **`KEY[0]` (Reset Pushbutton):** Press and release to reset the CPU and AI accelerator to restart execution from address `0x0000_0000`.
- **`SW[0]` (Display Mode Switch):**
  - **`SW[0] = 0` (Down):** The 7-segment displays `HEX3..HEX0` show the lower 16 bits of the CPU Program Counter (`dbg_pc[15:0]`).
  - **`SW[0] = 1` (Up):** The 7-segment displays `HEX3..HEX0` decode the lower half of the golden signature register: **`bAbE`** (`0xBABE`)!
