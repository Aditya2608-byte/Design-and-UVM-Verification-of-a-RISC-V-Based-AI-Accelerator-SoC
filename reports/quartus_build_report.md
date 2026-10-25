# Intel Quartus Prime FPGA Implementation & Build Report

**Project Name:** `de10_lite`  
**Target Device:** Intel MAX 10 FPGA (`10M50DAF484C7G`)  
**Package:** 484-pin FineLine BGA  
**Speed Grade:** -C7  
**EDA Software:** Intel Quartus Prime Lite Edition 25.1std.0 Build 1129  
**Host Environment:** Windows 11 64-bit, AMD Ryzen 7 (12 cores utilized)  
**Build Status:** **COMPILATION & BITSTREAM GENERATION SUCCESSFUL (0 Errors)**  

---

## 1. Build Flow Summary

| Compilation Stage | Tool Executable | Status | Elapsed Time | Errors | Warnings |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Analysis & Synthesis** | `quartus_map.exe` | **SUCCESS** | 00:00:24 | 0 | 25 |
| **Fitter (Place & Route)** | `quartus_fit.exe` | **SUCCESS** | 00:03:45 | 0 | 3 |
| **Timing Analysis** | `quartus_sta.exe` | **SUCCESS** | 00:00:06 | 0 | 8 |
| **Assembler (Bitstream)** | `quartus_asm.exe` | **SUCCESS** | 00:00:02 | 0 | 0 |
| **Total Build Pipeline** | | **SUCCESS** | **00:04:17** | **0** | **36** |

---

## 2. FPGA Device Resource Utilization

Final physical resource utilization reported by `quartus_fit` for the Intel MAX 10 `10M50DAF484C7G`:

| Resource Type | Used | Available | Utilization Percentage |
| :--- | :--- | :--- | :--- |
| **Total Logic Elements (LEs)** | **10,878** | **49,760** | **21.86 %** |
| -- Combinational with no register | 7,654 | 49,760 | 15.38 % |
| -- Combinational with a register | 3,091 | 49,760 | 6.21 % |
| -- Register only (no combinational) | 133 | 49,760 | 0.27 % |
| **Dedicated Logic Registers** | **3,224** | **49,760** | **6.48 %** |
| **Total Memory Bits** | **131,072** | **1,677,312** | **7.81 %** |
| -- M9K RAM Blocks | 16 (32 segments) | 182 | 8.79 % |
| **Embedded Multiplier 9-bit Elements** | **40** | **288** | **13.89 %** |
| **Total User I/O Pins** | **65** | **360** | **18.06 %** |
| **Clock Networks (Global Clocks)** | **1** | **20** | **5.00 %** |
| **Phase-Locked Loops (PLLs)** | **0** | **4** | **0.00 %** |
| **Internal Configuration Flash (UFM)** | **0** | **1** | **0.00 %** |

---

## 3. Subsystem Resource Breakdown

| Hierarchy Path | Module Name | Logic Elements | Registers | Memory Bits | DSP Multipliers |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `top` | `de10_lite_top` | 10,878 | 3,224 | 131,072 | 40 |
| `├── u_soc_top` | `soc_top` | 10,790 | 3,197 | 131,072 | 40 |
| `│   ├── u_riscv_core` | `riscv_core` (RV32IM) | 3,420 | 1,480 | 0 | 8 |
| `│   │   ├── u_alu` | `alu` (ALU + MUL/DIV) | 1,840 | 0 | 0 | 8 |
| `│   │   ├── u_regfile` | `register_file` (32x32) | 1,220 | 1,024 | 0 | 0 |
| `│   │   └── u_hazard` | `hazard_unit` | 42 | 0 | 0 | 0 |
| `│   ├── u_soc_sram` | `soc_sram` (16 KB) | 0 | 0 | 131,072 | 0 |
| `│   └── u_accelerator` | `accelerator` (4x4 AI) | 7,370 | 1,717 | 0 | 32 |
| `│       ├── u_systolic_array` | `systolic_array` | 6,110 | 1,280 | 0 | 32 |
| `│       │   └── pe[0..3][0..3]` | 16 PEs (MAC units) | 6,110 | 1,280 | 0 | 32 |
| `│       └── u_accumulator` | `accumulator` (ReLU) | 980 | 320 | 0 | 0 |
| `└── hex_digit_decoders` | Displays 0..5 | 88 | 0 | 0 | 0 |

---

## 4. Static Timing Analysis (STA) Summary

Calculated using Synopsys Design Constraints (`de10_lite.sdc`):
- Clock: `MAX10_CLK1_50` on `PIN_P11` (50.000 MHz, 20.000 ns target period).

| Corner Model | Operating Temperature | Setup Slack | Hold Slack | Min Pulse Width | Status |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Slow 1200mV 85C** | +85 °C | -130.776 ns | **+0.341 ns** | **+9.500 ns** | Hold MET, Setup Limited by Divider |
| **Slow 1200mV 0C** | 0 °C | -117.361 ns | **+0.306 ns** | **+9.512 ns** | Hold MET, Setup Limited by Divider |
| **Fast 1200mV 0C** | 0 °C | -43.492 ns | **+0.147 ns** | **+9.267 ns** | Hold MET, Setup Limited by Divider |

### Technical Note on Timing Closure:
- **Hold time and clock pulse widths are fully met** with generous margins across all process corners.
- The negative setup slack is isolated entirely to the unpipelined 32-bit combinational divider in `alu.sv` (total path delay: 154.3 ns).
- The accelerator datapath, systolic processing elements, embedded DSPs, and register files all comfortably meet 50 MHz.
- Safe operating frequency for executing code paths involving 32-bit integer division is $\le 6.48\text{ MHz}$ (e.g. 5 MHz clock, period 200 ns).

---

## 5. Generated Output Files

All bitstream files are located in `P:\risc_V_project\output_files/`:
- `de10_lite.sof`: 3,216,567 bytes (SRAM Object File for direct JTAG FPGA configuration).
- `de10_lite.pof`: 1,450,252 bytes (Programmer Object File for non-volatile MAX 10 flash).
- `de10_lite.pin`: Full textual pinout and drive strength assignment report.
- `de10_lite.sta.rpt`: Complete STA timing report with all setup/hold path breakdowns.
