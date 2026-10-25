# RISC-V SoC + 4×4 INT8 AI Accelerator — Project Inventory

**Date:** October 26, 2026  
**Target Device:** Intel MAX 10 FPGA (`10M50DAF484C7G`)  
**Development Board:** Terasic DE10-Lite  
**Working Repository:** `P:\risc_V_project` (branch: `fpga_de10_lite_dev`)  
**EDA Tools:** Intel Quartus Prime Lite Edition 25.1std, ModelSim-Altera Starter Edition 10.5b (18.1), Python 3.12  

---

## 1. Directory Structure

```text
P:\risc_V_project/
├── de10_lite.qsf                 # Intel Quartus Prime Settings File (pinout, timing, devices)
├── de10_lite.qpf                 # Intel Quartus Prime Project File
├── de10_lite.sdc                 # Synopsys Design Constraints (50 MHz clock, I/O delays)
├── firmware.mif                  # Memory Initialization File for FPGA M9K Block RAM
├── README_FPGA.md                # Bring-up and reproduction manual
├── output_files/                 # Generated FPGA programming files & reports
│   ├── de10_lite.sof             # SRAM Object File for JTAG programming (3.2 MB)
│   ├── de10_lite.pof             # Programmer Object File for EPCQ flash
│   ├── de10_lite.map.rpt         # Analysis & Synthesis report
│   ├── de10_lite.fit.rpt         # Fitter (Place & Route) report
│   ├── de10_lite.sta.rpt         # Timing Analyzer report
│   └── de10_lite.asm.rpt         # Assembler report
├── rtl/                          # Synthesizable RTL source files
│   ├── de10_lite_top.sv          # Board top-level wrapper (clock, resets, LEDs, 7-segs)
│   ├── soc_top.sv                # SoC integration (CPU + SRAM + AI Accelerator MMIO)
│   ├── soc_sram.sv               # Dual-port synchronous SRAM (M9K Block RAM in synthesis)
│   ├── core/                     # RISC-V RV32IM 5-Stage Pipelined Processor
│   │   ├── riscv_core.sv         # Pipeline top: IF, ID, EX, MEM, WB registers & muxes
│   │   ├── instruction_decode.sv # Control unit & immediate generator
│   │   ├── alu.sv                # RV32I ALU + RV32M hardware multiplier & divider
│   │   ├── register_file.sv      # 32x32-bit register file (x0 hardwired to 0)
│   │   └── hazard_unit.sv        # Load-use and branch hazard detection & forwarding
│   └── accelerator/              # 4x4 Systolic Array INT8 AI Accelerator
│       ├── accelerator.sv        # Accelerator top: MMIO control registers, FSM, SRAM interface
│       ├── systolic_array.sv     # 4x4 2D mesh of Processing Elements
│       ├── pe.sv                 # Processing Element: 8-bit MAC + flow registers
│       ├── mac.sv                # Multiply-Accumulate unit (INT8 x INT8 -> INT32 sum)
│       └── accumulator.sv        # Output buffer & ReLU activation stage
├── sim/                          # Simulation environments & test firmware
│   ├── firmware.hex              # Verilog $readmemh formatted firmware
│   ├── test_firmware.s           # RISC-V assembly source program
│   └── test_firmware.bin         # Raw binary machine code
├── tb/                           # Self-checking SystemVerilog testbenches
│   ├── tb_soc_top.sv             # Full SoC integration testbench
│   ├── tb_de10_lite_top.sv       # Board wrapper testbench (switches, buttons, displays)
│   └── tb_accelerator.sv         # Standalone AI accelerator verification testbench
├── scripts/                      # Autonomous tool scripts & automation
│   ├── make_mif.py               # Generates Intel MIF from HEX/bin
│   ├── report_worst_paths.tcl    # STA timing extraction script
│   └── fix_rtl.py                # Automated RTL verification fixes
└── reports/                      # Verification, synthesis, and architectural reports
    ├── project_inventory.md      # This inventory file
    ├── rtl_audit.md              # Systematic RTL bug audit and architectural analysis
    ├── verification_report.md    # ModelSim functional test logs and cycle trace
    └── quartus_build_report.md   # Quartus compilation, resource, and timing metrics
```

---

## 2. Module Hierarchy

```text
de10_lite_top (Board Wrapper)
├── soc_top (u_soc_top)
│   ├── riscv_core (u_riscv_core)
│   │   ├── instruction_decode (u_decode)
│   │   ├── register_file (u_regfile)
│   │   ├── alu (u_alu)
│   │   │   └── lpm_mult / lpm_divide (RV32M Hardware Multiplication & Division)
│   │   └── hazard_unit (u_hazard)
│   ├── soc_sram (u_soc_sram)
│   │   └── altsyncram (u_m9k_ram) [Intel MAX 10 M9K Embedded RAM Blocks]
│   └── accelerator (u_accelerator)
│       ├── systolic_array (u_systolic_array)
│       │   └── pe[0..3][0..3] (16 Processing Elements)
│       │       └── mac (u_mac)
│       └── accumulator (u_accumulator)
├── hex_digit_decoder (u_hex0..u_hex3) [Active-low 7-segment display drivers for HEX0-3]
└── hex_digit_decoder (u_hex4..u_hex5) [Active-low 7-segment display drivers for HEX4-5]
```

---

## 3. SoC Memory Map & MMIO Address Space

The SoC implements a unified 32-bit flat memory space. The CPU accesses instruction and data SRAM at `0x0000_0000..0x0000_3FFF` (16 KB) and memory-mapped accelerator registers starting at `0x1000_0000`.

| Address Range | Size | Component | Functionality |
| :--- | :--- | :--- | :--- |
| `0x0000_0000 - 0x0000_0FFF` | 4 KB | Instruction SRAM | Bootloader and RISC-V application code |
| `0x0000_1000 - 0x0000_107F` | 128 B | Data SRAM (A & B) | Input Matrix A (64 B) and Matrix B (64 B) |
| `0x0000_1080 - 0x0000_10BF` | 64 B | Data SRAM (C) | Accelerator Output Matrix C (16 x 32-bit INT32) |
| `0x0000_10C0 - 0x0000_10F8` | 56 B | Data SRAM | Scalar scratchpad and verification variables |
| `0x0000_10FC` | 4 B | Data SRAM | Hardware signature register (`0xCAFEBABE`) |
| `0x1000_0000` | 4 B | AI Accelerator | Control Register (Bit 0: Start, Bit 1: ReLU Enable) |
| `0x1000_0004` | 4 B | AI Accelerator | Status Register (Bit 0: Done, Bit 1: Busy, Bit 2: Error) |
| `0x1000_0008` | 4 B | AI Accelerator | Matrix A SRAM Base Address Pointer |
| `0x1000_000C` | 4 B | AI Accelerator | Matrix B SRAM Base Address Pointer |
| `0x1000_0010` | 4 B | AI Accelerator | Matrix C SRAM Destination Pointer |
| `0x1000_0014` | 4 B | AI Accelerator | Matrix Dimensions (K=4, N=4, M=4) |

---

## 4. Hardware I/O Mapping (Terasic DE10-Lite)

| Pin | Direction | Signal Name | Description |
| :--- | :--- | :--- | :--- |
| `PIN_P11` | Input | `MAX10_CLK1_50` | 50 MHz Onboard Crystal Oscillator |
| `PIN_B8` | Input | `KEY[0]` | System Master Reset (Active-Low pushbutton) |
| `PIN_A7` | Input | `KEY[1]` | Auxiliary User Pushbutton |
| `PIN_C10` | Input | `SW[0]` | Display Mode Select (0 = PC, 1 = Signature `0xCAFEBABE`) |
| `PIN_A8` | Output | `LEDR[0]` | AI Accelerator Done Flag |
| `PIN_A9` | Output | `LEDR[1]` | AI Accelerator Busy Flag |
| `PIN_A10` | Output | `LEDR[2]` | AI Accelerator Error Flag |
| `PIN_B10` | Output | `LEDR[3]` | Memory Bus Transaction Active |
| `PIN_D13` | Output | `LEDR[4]` | **Signature `0xCAFEBABE` Verified (Golden Result)** |
| `PIN_C13` | Output | `LEDR[5]` | Accelerator Interrupt Request |
| `PIN_B11` | Output | `LEDR[8]` | Reset Active Indicator (`~KEY[0]`) |
| `PIN_A11` | Output | `LEDR[9]` | 1.5 Hz Visual System Heartbeat (Clock Alive) |
| `PIN_C14..C17` | Output | `HEX0[6:0]` | 7-Segment Display 0 (Nibble 0) |
| `PIN_C18..D17` | Output | `HEX1[6:0]` | 7-Segment Display 1 (Nibble 1) |
| `PIN_B20..B17` | Output | `HEX2[6:0]` | 7-Segment Display 2 (Nibble 2) |
| `PIN_F21..E17` | Output | `HEX3[6:0]` | 7-Segment Display 3 (Nibble 3) |
| `PIN_F18..D22` | Output | `HEX4[6:0]` | 7-Segment Display 4 (Nibble 4) |
| `PIN_J20..L19` | Output | `HEX5[6:0]` | 7-Segment Display 5 (Nibble 5) |
