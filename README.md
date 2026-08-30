# Design and UVM Verification of a RISC-V Based AI Accelerator SoC

[![UVM Verification](https://img.shields.io/badge/Verification-UVM%201.2-blueviolet.svg?style=flat-square)](https://www.accellera.org/)
[![Language](https://img.shields.io/badge/Language-SystemVerilog%20%7C%20C-orange.svg?style=flat-square)](#)
[![ISA](https://img.shields.io/badge/ISA-RV32IM-red.svg?style=flat-square)](https://riscv.org/)
[![License](https://img.shields.io/badge/License-MIT-green.svg?style=flat-square)](LICENSE)

An academic, production-grade System-on-Chip (SoC) design featuring an **RV32IM RISC-V CPU** integrated with a dedicated **AI Accelerator (Systolic Array Matrix Multiply & Vector Processing Engine)**. This repository contains the complete Register-Transfer Level (RTL) design, memory-mapped bus fabric, embedded firmware, and an industry-standard **Universal Verification Methodology (UVM)** testbench environment to achieve high functional and code coverage.

---

## Table of Contents
1. [Project Overview](#1-project-overview)
2. [SoC Architecture](#2-soc-architecture)
   - [RISC-V CPU Core](#risc-v-cpu-core)
   - [AI Accelerator (MAC Engine)](#ai-accelerator-mac-engine)
   - [Bus Interconnect & CSRs](#bus-interconnect-&-csrs)
3. [Memory & Register Map](#3-memory-&-register-map)
4. [Embedded Firmware Programming Model](#4-embedded-firmware-programming-model)
5. [RTL Design Modules](#5-rtl-design-modules)
6. [UVM Verification Environment](#6-uvm-verification-environment)
   - [Testbench Architecture](#testbench-architecture)
   - [Verification Components](#verification-components)
   - [Assertions & Formal Checks](#assertions-&-formal-checks)
   - [Functional Coverage Model](#functional-coverage-model)
7. [Directory Structure](#7-directory-structure)
8. [Toolchain & Simulation Setup](#8-toolchain-&-simulation-setup)
9. [Verification Plan & Regression Run](#9-verification-plan-&-regression-run)
10. [License & References](#10-license-&-references)

---

## 1. Project Overview

Modern computing workloads, especially Deep Learning and AI inference, are bottlenecked by the von Neumann architecture when executing matrix multiplications (GEMM) on general-purpose CPUs. This project demonstrates a classic heterogeneous SoC solution:
* An **RV32IM CPU** acts as the controller, executing firmware, running control logic, preparing data, and scheduling tasks.
* A specialized hardware **AI Accelerator** is offloaded to perform compute-intensive matrix operations, vector manipulations, and element-wise non-linear activations (ReLU) in parallel.
* Communication occurs over a standardized **AXI-Lite/APB Bus Interconnect**, enabling high-speed control register access and Direct Memory Access (DMA) for data transfer.

---

## 2. SoC Architecture

### Block Diagram

```text
                                  +------------------------------+
                                  |         RISC-V CPU           |
                                  |      (RV32IM Core)           |
                                  +--------------+---------------+
                                                 |
                                                 | [CPU Core Bus]
                                                 v
                                  +------------------------------+
                                  |    System Bus Interconnect   |
                                  |     (AXI-Lite / APB Fabric)  |
                                  +---+-------+-------+-------+--+
                                      |       |       |       |
             +------------------------+       |       |       +-----------------------+
             |                                |       |                               |
             v                                v       v                               v
+-------------------------+      +-------------------------+      +-----------------------+
|   Instruction Memory    |      |       Data Memory       |      |     UART Controller   |
|   (SRAM / Boot ROM)     |      |       (SRAM Shared)     |      |    (Console Debug)    |
+-------------------------+      +------------+------------+      +-----------------------+
                                              |
                                              | [Shared Memory Access]
                                              v
                                 +----------------------------+
                                 |        AI Accelerator      |
                                 |         (MAC Engine)       |
                                 |  +----------------------+  |
                                 |  |  Control Registers   |  |
                                 |  +----------------------+  |
                                 |  |  SRAM Input Buffers  |  |
                                 |  +----------------------+  |
                                 |  |  Systolic MAC Array  |  |
                                 |  +----------------------+  |
                                 |  |  Post-Processing/ReLU|  |
                                 |  +----------------------+  |
                                 +----------------------------+
```

### RISC-V CPU Core
* **ISA Standard:** RV32IM (Integer + Hardware Multiplication/Division).
* **Pipeline:** 3-stage single-issue in-order pipeline (Fetch, Decode, Execute/Writeback).
* **Hazard Handling:** Automatic data-forwarding and pipeline stalling for load-use and structural hazards.
* **Control/Status:** Implements machine-mode CSRs for exception handling, interrupt handling, and timer configurations.

### AI Accelerator (MAC Engine)
The AI Accelerator is optimized for GEMM (General Matrix Multiply) operations and vector math.

```text
   Memory Bus Interface (AXI/DMA)
               │
               ▼
      ┌─────────────────┐
      │  Control Registers (CSRs)
      └─────────────────┘
        │             │
        ▼             ▼
┌──────────────┐┌──────────────┐
│ Input Buffer ││ Weight Buffer│
└──────┬───────┘└──────┬───────┘
       │               │
       └───────┬───────┘
               ▼
     ┌───────────────────┐
     │  Systolic Array   │  ◄── Vector Multiply & Accumulate
     │  (MAC PE Matrix)  │
     └─────────┬─────────┘
               ▼
     ┌───────────────────┐
     │    Accumulator    │  ◄── Bias Addition & Vector Accumulate
     └─────────┬─────────┘
               ▼
     ┌───────────────────┐
     │ Activation Engine │  ◄── Element-Wise ReLU / Quantization
     └─────────┬─────────┘
               ▼
     ┌───────────────────┐
     │   Output Buffer   │
     └─────────┬─────────┘
               │
               ▼
   Data Memory Writeback (DMA)
```

1. **Input & Weight Buffers:** On-chip SRAM blocks that store feature maps (activations) and parameter weights locally, minimizing DRAM/DMEM traffic.
2. **MAC Array (Multiply-Accumulate):** A grid of Processing Elements (PEs) executing pipelined matrix products. Supports $8$-bit integer (INT8) quantization for hardware efficiency and $32$-bit integer accumulation to prevent overflow.
3. **Accumulator:** Pipelined registers to sum up partial products along with an optional Bias tensor.
4. **Activation Engine:** Implements hardware-level element-wise Rectified Linear Unit (ReLU):
   $$\text{ReLU}(x) = \max(0, x)$$
5. **Output Buffer:** Stores the computed output tensor block before pushing it back to main memory via DMA.

### Bus Interconnect & CSRs
* **Protocol:** AXI4-Lite for configuration registers; AXI4-Full (Master/Slave) with burst mode for high-throughput DMA transfers.
* **Arbiter:** Round-Robin priority arbiter resolving conflicts between CPU data cache/load-store unit and the Accelerator DMA.

---

## 3. Memory & Register Map

The SoC has a unified $32$-bit physical address space partitioned as follows:

| Base Address | End Address | Size | Description |
|---|---|---|---|
| `0x0000_0000` | `0x0000_FFFF` | 64 KB | Instruction Memory (Boot SRAM) |
| `0x0001_0000` | `0x000F_FFFF` | 960 KB | Shared Data Memory (SRAM) |
| `0x4000_0000` | `0x4000_001F` | 32 B | AI Accelerator Control/Status Registers (CSRs) |
| `0x4000_1000` | `0x4000_100F` | 16 B | UART Control Registers |

### Accelerator Control Registers (Base: `0x4000_0000`)

| Name | Offset | Access | Width (bits) | Reset Value | Description |
|---|---|---|---|---|---|
| `CTRL` | `0x00` | R/W | 32 | `0x0000_0000` | Control Register:<br>• Bit 0: **START** (Set to initiate computation)<br>• Bit 1: **RESET** (Soft reset)<br>• Bit 2: **INT_EN** (Enable done interrupt) |
| `STATUS` | `0x04` | R | 32 | `0x0000_0000` | Status Register:<br>• Bit 0: **DONE** (Computation complete)<br>• Bit 1: **BUSY** (Engine executing)<br>• Bit 2: **ERROR** (Illegal configuration) |
| `CFG_SIZE` | `0x08` | R/W | 32 | `0x0000_0000` | Matrix Dimensions:<br>• Bits \[15:0\]: Matrix M (Rows of A)<br>• Bits \[31:16\]: Matrix N (Cols of B) |
| `CFG_K` | `0x0C` | R/W | 32 | `0x0000_0000` | Common Dimension:<br>• Bits \[15:0\]: Matrix K (Cols of A / Rows of B) |
| `ADDR_A` | `0x10` | R/W | 32 | `0x0000_0000` | Pointer to Matrix A in Data Memory |
| `ADDR_B` | `0x14` | R/W | 32 | `0x0000_0000` | Pointer to Matrix B in Data Memory |
| `ADDR_C` | `0x18` | R/W | 32 | `0x0000_0000` | Pointer to Output Matrix C in Data Memory |
| `CFG_ACT` | `0x1C` | R/W | 32 | `0x0000_0000` | Post-processing Activation Mode:<br>• `0`: Bypass<br>• `1`: ReLU |

---

## 4. Embedded Firmware Programming Model

The firmware compiled by the RISC-V GCC toolchain is loaded into the Instruction Memory. It initializes data structures, populates inputs into the Data Memory, programs the accelerator, polls for hardware completion, and validates outputs.

```c
#include <stdint.h>

// Register Definitions
#define ACCEL_BASE       0x40000000
#define REG_ACCEL_CTRL   ((volatile uint32_t*)(ACCEL_BASE + 0x00))
#define REG_ACCEL_STAT   ((volatile uint32_t*)(ACCEL_BASE + 0x04))
#define REG_ACCEL_SIZE   ((volatile uint32_t*)(ACCEL_BASE + 0x08)
#define REG_ACCEL_K      ((volatile uint32_t*)(ACCEL_BASE + 0x0C))
#define REG_ACCEL_ADDR_A ((volatile uint32_t*)(ACCEL_BASE + 0x10))
#define REG_ACCEL_ADDR_B ((volatile uint32_t*)(ACCEL_BASE + 0x14))
#define REG_ACCEL_ADDR_C ((volatile uint32_t*)(ACCEL_BASE + 0x18))
#define REG_ACCEL_ACT    ((volatile uint32_t*)(ACCEL_BASE + 0x1C))

#define UART_TX_REG      ((volatile uint32_t*)0x40001000)

void uart_print(const char* str) {
    while (*str) {
        *UART_TX_REG = (uint32_t)(*str++);
    }
}

int main() {
    uart_print("Initializing AI Accelerator SoC...\n");

    // Matrix sizes: M=8, N=8, K=8
    uint16_t M = 8, N = 8, K = 8;
    
    // Address allocations in Data Memory (SRAM)
    uint32_t mat_a_addr = 0x00010000;
    uint32_t mat_b_addr = 0x00010100;
    uint32_t mat_c_addr = 0x00010200;

    // 1. Initialize Matrices in SRAM (Normally loaded from external flash/sensor)
    int8_t* mat_a = (int8_t*)mat_a_addr;
    int8_t* mat_b = (int8_t*)mat_b_addr;
    for (int i = 0; i < (M * K); i++) mat_a[i] = i % 10;
    for (int i = 0; i < (K * N); i++) mat_b[i] = (i * 3) % 7;

    // 2. Program Accelerator Configuration Registers
    *REG_ACCEL_SIZE   = (N << 16) | M;
    *REG_ACCEL_K      = K;
    *REG_ACCEL_ADDR_A = mat_a_addr;
    *REG_ACCEL_ADDR_B = mat_b_addr;
    *REG_ACCEL_ADDR_C = mat_c_addr;
    *REG_ACCEL_ACT    = 1; // Enable ReLU Activation

    // 3. Start Accelerator Computation
    uart_print("Starting Matrix Multiplication...\n");
    *REG_ACCEL_CTRL = 0x01; // Assert START bit

    // 4. Poll STATUS register until DONE bit is set
    while (((*REG_ACCEL_STAT) & 0x01) == 0) {
        // Polling loop (or enter sleep mode awaiting done interrupt)
    }

    uart_print("AI Accelerator finished computation!\n");

    // 5. Read result and verify (sample output validation)
    int32_t* results = (int32_t*)mat_c_addr;
    if (results[0] >= 0) {
        uart_print("Self-check completed successfully.\n");
    } else {
        uart_print("Error: Negative value detected in Output (ReLU failed).\n");
    }

    return 0;
}
```

---

## 5. RTL Design Modules

All design files are written in standard SystemVerilog (`.sv`):

*   **`rtl/cpu/cpu.sv`**: Top-level module for the RV32IM core. Contains instruction fetch, register bank, ALU, branch prediction, and memory-mapped control unit.
*   **`rtl/cpu/register_file.sv`**: RISC-V 32-register general-purpose bank with dual read ports and single write port.
*   **`rtl/accelerator/accelerator.sv`**: Orchestrates matrix computation. Fetches matrices via DMA, feeds operands to MAC array, triggers accumulation, applies ReLU, and outputs data.
*   **`rtl/accelerator/mac.sv`**: Pipelined MAC unit (Multiply-Accumulate) forming the base cell of the Systolic Array.
*   **`rtl/accelerator/controller.sv`**: Control Finite State Machine (FSM) defining cycles for loading weight registers, processing, routing outputs, and updating status signals.
*   **`rtl/memory/instruction_memory.sv`**: Read-only (under typical operations) memory storing compiled boot firmware binaries.
*   **`rtl/memory/data_memory.sv`**: Shared multi-port SRAM block for CPU read/write operations and accelerator DMA.
*   **`rtl/bus/bus.sv`**: Implements multi-master, multi-slave interconnect with memory decoding and arbiter logic.
*   **`rtl/uart/uart.sv`**: Universal Asynchronous Receiver-Transmitter for debugging output to terminal output.
*   **`rtl/soc_top.sv`**: Top level SoC wrapper instantiating the CPU, bus, memory models, accelerator core, and UART.

---

## 6. UVM Verification Environment

Verification is the cornerstone of this project. The system is validated using **Universal Verification Methodology (UVM 1.2)** to automatically generate thousands of random verification scenarios, check assertions, and log functional coverage.

### Testbench Architecture

```text
+---------------------------------------------------------------------------------+
|                                UVM TESTBENCH                                    |
|                                                                                 |
|  +---------------------------------------------------------------------------+  |
|  |                               UVM TEST                             |  |
|  |  +---------------------------------------------------------------------+  |  |
|  |  |                             UVM ENV                                 |  |  |
|  |  |                                                                     |  |  |
|  |  |  +-----------------------+              +-----------------------+   |  |  |
|  |  |  |     CPU Agent         |              |  Accelerator Agent    |   |  |  |
|  |  |  |                       |              |                       |   |  |  |
|  |  |  |  +-----------------+  |              |  +-----------------+  |   |  |  |
|  |  |  |  | Sequencer (CPU) |  |              |  | Sequencer (ACC) |  |   |  |  |
|  |  |  |  +--------+--------+  |              |  +--------+--------+  |   |  |  |
|  |  |  |           |           |              |           |           |   |  |  |
|  |  |  |           v           |              |           v           |   |  |  |
|  |  |  |  +--------+--------+  |              |  +--------+--------+  |   |  |  |
|  |  |  |  |  Driver (CPU)   |  |              |  |  Driver (ACC)   |  |   |  |  |
|  |  |  |  +--------+--------+  |              |  +--------+--------+  |   |  |  |
|  |  |  |           |           |              |           |           |   |  |  |
|  |  |  |           v           |              |           v           |   |  |  |
|  |  |  |  +--------+--------+  |              |  +--------+--------+  |   |  |  |
|  |  |  |  |  Monitor (CPU)  |  |              |  |  Monitor (ACC)  |  |   |  |  |
|  |  |  |  +--------+--------+  |              |  +--------+--------+  |   |  |  |
|  |  |  +-----------+-----------+              +-----------+-----------+   |  |  |
|  |  |              |                                      |               |  |  |
|  |  |              +-----------------+  +-----------------+               |  |  |
|  |  |                                |  |                                 |  |  |
|  |  |                                v  v                                 |  |  |
|  |  |                     +----------------------+                        |  |  |
|  |  |                     |    UVM Scoreboard    |                        |  |  |
|  |  |                     |  (Golden Reference)  |                        |  |  |
|  |  |                     +----------------------+                        |  |  |
|  |  |                                |                                    |  |  |
|  |  |                                v                                    |  |  |
|  |  |                     +----------------------+                        |  |  |
|  |  |                     |   Coverage Collector |                        |  |  |
|  |  |                     +----------------------+                        |  |  |
|  |  +---------------------------------------------------------------------+  |  |
|  +---------------------------------------------------------------------------+  |
|                                                                                 |
+---------------------------------------+-----------------------------------------+
                                        | (Virtual Interfaces)
                                        v
+---------------------------------------------------------------------------------+
|                                 DUT: SoC Top                                    |
|                                                                                 |
|      +-------------------+      +-------------------+      +-------------+      |
|      |    RISC-V CPU     |      |   AI Accelerator  |      |   Memory    |      |
|      +-------------------+      +-------------------+      +-------------+      |
|                                                                                 |
|                   ================ Assertions Binded ================           |
+---------------------------------------------------------------------------------+
```

### Verification Components
*   **Sequences:** Define high-level transaction sequences (e.g., Matrix Multiplications with extreme dimensional sizes, back-to-back hardware triggers, random bus conflicts, register reads/writes, interrupts/resets).
*   **Sequencer:** Manages the routing of transactions from sequence tasks to the Driver.
*   **Driver:** Drives transaction elements (like write-address, weight matrix values, configurations) onto the system interfaces.
*   **Monitor:** Passively captures pin-level bus activity and hardware events, transforming them into high-level transactions for analysis.
*   **Scoreboard:** Compares output data written to DMEM by the accelerator with an internal software reference (Golden Matrix multiplication pipeline in Python/C++ or native SV).
*   **Coverage Collector:** Observes transactions and evaluates code/functional coverage definitions.

### Assertions & Formal Checks
SystemVerilog Assertions (SVA) are binded directly to the design to verify protocol compliance statically:
1.  **Bus Protocol Handshake:**
    ```systemverilog
    property p_axi_handshake;
        @(posedge clk) disable iff (!rst_n)
        (m_axi_awvalid && !m_axi_awready) |=> m_axi_awvalid;
    endproperty
    assert property (p_axi_handshake) else `uvm_error("SVA", "AXI AWVALID deasserted before AWREADY response!");
    ```
2.  **Accelerator Cycle Duration Limit (Liveness Check):**
    ```systemverilog
    property p_start_to_done;
        @(posedge clk) disable iff (!rst_n)
        $rose(accel_start) |-> s_eventually (accel_done || accel_error);
    endproperty
    assert property (p_start_to_done) else `uvm_error("SVA", "Accelerator failed to finish and timed out!");
    ```

### Functional Coverage Model
*   **Cross Coverage:** Matrix Sizes (M, N, K) crossed with Activation type (Bypass, ReLU).
*   **Boundary Values:** Matrix dimension tests (e.g., $1 \times 1$, max size limit $64 \times 64$, power of $2$ values).
*   **Register Access Coverage:** Reading/writing each register, back-to-back writes to identical registers, and accessing non-existent addresses (checking error response generation).

---

## 7. Directory Structure

```text
AI_SOC/
├── rtl/                        # Register-Transfer Level (RTL) Design Files
│   ├── cpu/                    # RV32IM RISC-V CPU Core modules
│   │   ├── cpu.sv
│   │   ├── register_file.sv
│   │   └── alu.sv
│   ├── accelerator/            # Systolic MAC & Tensor acceleration logic
│   │   ├── accelerator.sv
│   │   ├── mac.sv
│   │   └── controller.sv
│   ├── memory/                 # Instruction & Data SRAM components
│   │   ├── instruction_memory.sv
│   │   └── data_memory.sv
│   ├── bus/                    # APB/AXI-Lite interconnect fabric
│   │   └── bus.sv
│   ├── uart/                   # Debug UART peripheral
│   │   └── uart.sv
│   └── soc_top.sv              # Structural top wrapper instantiating entire SoC
│
├── tb/                         # UVM Verification Environment
│   ├── agent/                  # Sequencer, Driver, Monitor definitions
│   │   ├── soc_agent.sv
│   │   ├── soc_driver.sv
│   │   └── soc_monitor.sv
│   ├── sequence/               # Test sequences (directed and random)
│   │   ├── soc_seq_pkg.sv
│   │   └── base_sequence.sv
│   ├── scoreboard/             # Predicts correct outputs & matches results
│   │   └── soc_scoreboard.sv
│   ├── coverage/               # Functional coverage definition files
│   │   └── soc_coverage.sv
│   ├── tests/                  # UVM test cases (Smoke, Random, Boundary)
│   │   ├── soc_test_pkg.sv
│   │   └── base_test.sv
│   └── tb_top.sv               # Top simulation bench instantiating DUT and Virtual Interfaces
│
├── firmware/                   # Embedded software running on CPU
│   ├── main.c                  # C application running neural layers
│   ├── startup.s               # RISC-V assembly boot script
│   └── link.ld                 # Memory-layout linker description script
│
├── scripts/                    # Automation scripts
│   ├── compile_firmware.py     # Script utilizing riscv-gcc to generate hex
│   ├── run_sim.sh              # Bash command scripts for Questa/VCS
│   └── Makefile                # Central compilation and simulation target manager
│
├── waves/                      # Waveform configurations (.rc, .gtkw, .do)
│   └── wave_config.gtkw
│
├── docs/                       # Project architecture and results reports
│   └── uvm_verification_plan.pdf
│
└── README.md                   # Project documentation
```

---

## 8. Toolchain & Simulation Setup

### Prerequisites
*   **C Compiler:** RISC-V Embedded Toolchain (`riscv64-unknown-elf-gcc`).
*   **Simulator:** QuestaSim, Synopsys VCS, or Cadence Xcelium.
*   **Waveform Tool:** GTKWave or Verdi.
*   **System Tools:** Python 3.x, Make.

### 1. Compile Firmware
The firmware must be cross-compiled to RISC-V machine code, and converted to a memory initialization hex format:
```bash
# Build firmware using Makefile helper
cd firmware
make clean
make all
# This produces firmware.hex containing the instructions to boot
```

### 2. Run UVM Simulation
Use the root Makefile to run the simulation under your chosen compiler tool.

**Using Questasim:**
```bash
# Compile and run default smoke test in Questa GUI mode
make run TEST=soc_smoke_test GUI=1 TOOL=questa

# Run default test in command line mode
make run TEST=soc_smoke_test TOOL=questa
```

**Using Synopsys VCS:**
```bash
# Run random matrix multiplication test suite with regression options
make run TEST=soc_random_matrix_test TOOL=vcs COV=1
```

---

## 9. Verification Plan & Regression Run

Our target verification metrics are set to match professional ASIC fabrication standards:
*   **Statement & Branch Code Coverage:** $\ge 98\%$
*   **Functional Coverage (Covergroups):** $100\%$
*   **Assertion Coverage:** $100\%$

### Regression Execution
To check robustness, run a full regression suite using the run script:
```bash
cd scripts
python3 run_regression.py --suite=full --threads=4
```
This runs a randomized seed regression of 500 testcases, verifying variable sized GEMMs, random memory access patterns, and resets during active execution.

---

## 10. License & References

*   **License:** Distributed under the MIT License. See [LICENSE](LICENSE) for more details.
*   **RISC-V ISA Reference:** [RISC-V Volume I: Unprivileged ISA](https://riscv.org/specifications/)
*   **UVM Reference:** [Accellera SystemVerilog UVM Class Reference Manual](https://www.accellera.org/)
