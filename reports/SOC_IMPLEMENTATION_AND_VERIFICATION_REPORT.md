# RISC-V (RV32IM) + AI Accelerator SoC: Physical Implementation, Debug & Bring-Up Report

**Project Target:** Complete System-on-Chip Implementation & Verification  
**Branch:** `fix/fpga-bringup-and-soc-debug`  
**Review Target Date:** 28 October 2026  
**Status:** Verification Passed (100%), Target-Specific Synthesis Complete (100%), Ready for Physical PnR / Bitstream  

---

## 1. Executive Summary

The end-to-end integration and synthesis flow for the RISC-V + AI Accelerator System-on-Chip (`soc_top`) has been brought to full functional closure and target-specific physical synthesis.

Key achievements:
1. **Identified and Fixed 2 Critical RTL Hardware Bugs**:
   - **Bug 1 (Sticky Done in Accelerator MMIO):** The accelerator state machine asserted `done` for only a single clock cycle before immediately returning to `STATE_IDLE`. When the RISC-V CPU polled `REG_STATUS` (`0x40000004`), it missed the 1-cycle window and hung in an infinite polling loop. Added a sticky `status_done_reg` with software W1C / start-clearing.
   - **Bug 2 (Forwarding Priority Inversion in CPU Core):** In `rtl/core/riscv_core.sv`, EX and Branch forwarding evaluated `MEM/WB` forwarding in separate subsequent `if` blocks without `else if`. Consecutive writes to the same destination register (such as `lui x30, 0xCAFEC` in MEM/WB followed immediately by `addi x30, x30, -1346` in EX/MEM) allowed the stale WB value to overwrite the valid EX/MEM value, corrupting the success signature `0xCAFEBABE`. Structured forwarding logic with strict `else if` priority.
2. **End-to-End SoC Verification Passed (0 Errors)**:
   - Full 54-instruction boot & inference firmware executed in **88 clock cycles**.
   - RV32M hardware operations verified: `MUL` (12 * 10 = 120), `DIV` (120 / 12 = 10), `REM` (120 % 10 = 0).
   - AI Accelerator 4x4 matrix multiplication computed and verified in SRAM: `C[0][0]=11`, `C[0][1]=13`, `C[0][2]=8`, `C[0][3]=8`, `C[1][0]=27`, `C[1][1]=29`.
   - Test signature `0xCAFEBABE` written to address `0x000010FC` at cycle 87.
   - All 6 unit and subsystem regression suites passed (`tb_alu`, `tb_register_file`, `tb_imm_gen`, `tb_hazard_unit`, `tb_riscv_core`, `tb_accelerator`).
3. **Physical Synthesis Optimization (97.8% Logic Reduction)**:
   - Diagnosed generic synthesis cell explosion (613,508 cells, 131,072 DFFs) caused by unconstrained asynchronous RAM synthesis.
   - Successfully executed target-specific synthesis for Xilinx 7-Series (`synth_xilinx -family xc7`):
     - Total cell count reduced from 613,508 to **13,427 cells** (97.8% reduction).
     - Netlist size reduced from 57 MB to **3.2 MB** (`sim/soc_top_xc7_netlist.v`).
     - Resource utilization: **28 DSP48E1** slices, **3,194 Flip-Flops**, **8,028 LUTs**, **1,024 RAM128X1D** distributed RAM cells.
     - Structurally checked and validated with Yosys (`Found and reported 0 problems`).

---

## 2. Root Cause Analysis and RTL Modifications

### 2.1. Bug 1: Accelerator MMIO Sticky Status Register
- **File:** `rtl/accelerator/accelerator.sv` (and `rtl/accelerator/controller.sv`)
- **Mechanism:** In `controller.sv`, `done` is generated in `STATE_DONE` for 1 clock cycle:
  ```systemverilog
  STATE_DONE: begin
      done = 1'b1;
      next_state = STATE_IDLE;
  end
  ```
  The RISC-V firmware polls the MMIO register `REG_STATUS` (`0x4000_0004`):
  ```assembly
  poll_loop:
      lw   x21, 0x004(x10)
      andi x22, x21, 1
      beq  x22, x0, poll_loop
  ```
  Because the RISC-V load instruction takes multiple clock cycles through the 5-stage pipeline, the 1-cycle `done` pulse disappeared before the CPU load instruction could sample it.
- **Resolution:** Introduced `status_done_reg` in `rtl/accelerator/accelerator.sv`:
  ```systemverilog
  logic status_done_reg;
  always_ff @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
          status_done_reg <= 1'b0;
      end else begin
          if (ctrl_done) begin
              status_done_reg <= 1'b1;
          end else if (ctrl_start || (s_axi_wvalid && s_axi_wstrb[0] && s_axi_wdata[0] && (s_axi_awaddr[7:0] == REG_STATUS))) begin
              status_done_reg <= 1'b0; // Clear on start or W1C write
          end
      end
  end
  ```

### 2.2. Bug 2: RISC-V Pipeline Forwarding Priority Inversion
- **File:** `rtl/core/riscv_core.sv`
- **Mechanism:** In the original forwarding multiplexer logic:
  ```systemverilog
  // Forward from EX/MEM
  if (ex_mem_reg_write && (ex_mem_rd != 5'd0) && (ex_mem_rd == id_ex_rs1)) begin
      forward_a_data = ex_mem_alu_res;
  end

  // Forward from MEM/WB
  if (mem_wb_reg_write && (mem_wb_rd != 5'd0) && (mem_wb_rd == id_ex_rs1)) begin
      forward_a_data = wb_data;
  end
  ```
  When instruction $I_1$ writes register $X$, and the immediate next instruction $I_2$ also writes register $X$, while $I_3$ reads register $X$:
  - $I_2$ is in `EX/MEM` (newer value).
  - $I_1$ is in `MEM/WB` (older value).
  - Because `MEM/WB` was evaluated in an independent `if` after `EX/MEM`, the older value from $I_1$ overwrote the newer value from $I_2$!
  In the firmware:
  ```assembly
  lui  x30, 0xCAFEC       # I1: Writes 0xCAFEC000 to x30
  addi x30, x30, -1346    # I2: Writes 0xCAFEBABE to x30
  sw   x30, 0x0FC(x23)    # I3: Reads x30
  ```
  The core forwarded `0xCAFEC000` instead of `0xCAFEBABE` to the store instruction!
- **Resolution:** Re-architected both ALU operand forwarding and branch operand forwarding with explicit priority using `else if`:
  ```systemverilog
  // Forward from EX/MEM (highest priority: youngest instruction)
  if (ex_mem_reg_write && (ex_mem_rd != 5'd0) && (ex_mem_rd == id_ex_rs1)) begin
      forward_a_data = ex_mem_alu_res;
  end else if (mem_wb_reg_write && (mem_wb_rd != 5'd0) && (mem_wb_rd == id_ex_rs1)) begin
      forward_a_data = wb_data;
  end
  ```

---

## 3. End-to-End Verification Results

### 3.1. SoC Simulation Trace
- **Simulator:** Icarus Verilog (`iverilog 14.0-devel` + `vvp`)
- **Execution Cycles:** 88 cycles to completion
- **Trace Highlights:**
  - Cycle 0–36: Boot, RV32M test (MUL=120, DIV=10, REM=0), write Matrix A and Matrix B to MMIO registers.
  - Cycle 36: Firmware writes `REG_CTRL = 1` (Start accelerator).
  - Cycle 45: Accelerator systolic array completes matrix multiplication, asserts `ctrl_done`, sets `status_done_reg = 1`.
  - Cycle 57: CPU `lw` reads `REG_STATUS`, detects bit 0 = 1, exits `poll_loop`.
  - Cycle 60–84: CPU reads `C[0][0..3]` and `C[1][0..1]` from MMIO registers `0x4000_0300..` and writes to SRAM `0x1000..0x1014`.
  - Cycle 87: CPU executes `sw x30, 0x0FC(x23)` storing signature `0xCAFEBABE` to SRAM `0x0000_10FC`.
  - Testbench checks pass with **0 errors**:
    ```
    ================================================================================
           🏆 [ALL TESTS PASSED] RISC-V AI ACCELERATOR SOC FULLY OPERATIONAL        
    ================================================================================
    ```

### 3.2. Regression Test Matrix
| Testbench | Module Under Test | Status | Result / Error Count |
|---|---|---|---|
| `tb/core/tb_alu.sv` | RV32IM ALU & Shifter | **PASS** | 10/10 test vectors passed (0 errors) |
| `tb/core/tb_register_file.sv` | 32x32 Register File | **PASS** | R0-hardwiring & R/W verified (0 errors) |
| `tb/core/tb_imm_gen.sv` | Immediate Generator | **PASS** | I, S, B, U, J immediate types verified (0 errors) |
| `tb/core/tb_hazard_unit.sv` | Hazard & Stall Unit | **PASS** | 8 hazard scenarios verified (0 errors) |
| `tb/core/tb_riscv_core.sv` | RV32IM 5-Stage Core | **PASS** | 15 pipeline scenarios verified (0 errors) |
| `tb/tb_accelerator.sv` | AI Accelerator Top | **PASS** | 5 matrix scenarios + ReLU verified (0 errors) |
| `tb/tb_soc_top.sv` | Full Integrated SoC | **PASS** | End-to-end firmware + MMIO + RV32M + AI (0 errors) |

---

## 4. Synthesis & Physical Resource Utilization

Target Device: **Xilinx 7-Series FPGA (`xc7a100tcsg324-1` / `xc7` family)**  
Synthesis Tool: **Yosys 0.69+276 with Slang SV2017 frontend**

### 4.1. Comparative Resource Breakdown

| Resource Category | Generic Synthesis (Baseline) | Target-Specific Synthesis (`xc7`) | Reduction / Utilization |
|---|---|---|---|
| **Total Cells** | 613,508 cells | **13,427 cells** | **97.8% logic reduction** |
| **Netlist Size** | 56.9 MB | **3.2 MB** | **94.4% smaller** |
| **DSP Blocks** | 0 (generic) | **28 DSP48E1** | 16 in AI Accel, 12 in RV32M |
| **Flip-Flops (FF)** | 131,072 DFFs | **3,194 FFs** (3193 FDCE + 1 FDPE) | 2.5% of Artix-7 100T |
| **LUTs (Look-Up Tables)** | 166,283 MUX + 120k logic | **8,028 LUTs** (LUT2-LUT6) | 12.6% of Artix-7 100T |
| **Distributed RAM** | Unmapped (blown to DFFs) | **1,024 RAM128X1D** | 16 KB dual-port memory |
| **Carry Chains** | 0 | **908 CARRY4** | Fast arithmetic & MAC |
| **Clock Buffers** | 0 | **1 BUFG** | Primary global clock net |
| **Structural Check** | Passed | **Passed (0 problems)** | Netlist read-back validated |

---

## 5. Hardware Bring-Up & Next Steps

### 5.1. Board Identification & Pin Constraints
The SoC top-level signals that interface with physical FPGA pins:
- `clk`: Primary system clock input (100 MHz oscillator).
- `rst_n`: Active-low reset input (pushbutton switch).
- `accel_done`: Status LED indicating neural network computation completion.
- `data_req`, `data_we`: Optional diagnostic activity LEDs.

A physical constraints template has been generated at `synthesis/constraints_template.xdc`.

### 5.2. Running Place & Route (PnR) and Bitstream Generation
Depending on your preferred toolchain:

#### Option A: Using Vivado Batch Mode
```powershell
vivado -mode batch -source synthesis/vivado_synth.tcl
```

#### Option B: Using Open-Source Flow (Yosys + nextpnr-xilinx)
```powershell
call C:\Users\Asus\Downloads\oss-cad-suite-windows-x64-20261012\oss-cad-suite\environment.bat
yosys -s synthesis/synth_soc_xc7.ys
```
