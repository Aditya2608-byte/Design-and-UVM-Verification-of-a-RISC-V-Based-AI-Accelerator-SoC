# RISC-V SoC + 4×4 INT8 AI Accelerator — Master Results Report

**Target FPGA:** Intel MAX 10 (`10M50DAF484C7G`) on Terasic DE10-Lite  
**Design Top Entity:** `de10_lite_top` (RV32IM Core + 4×4 Systolic Array + 16 KB SRAM)  
**Tools:** Intel Quartus Prime Lite Edition 25.1std & ModelSim-Altera 10.5b  
**Status:** **100% Timing Closed, Verified, and Assembled (0 Errors, 0 Violations)**  

---

## 1. Timing Analysis & Slack Metrics (Quartus Timing Analyzer)

Evaluated across Slow 1200mV 85°C, Slow 1200mV 0°C, and Fast 1200mV 0°C models:

| Clock Domain | Period | Target Freq | Worst-Case Setup Slack | Worst-Case Hold Slack | Minimum Pulse Width | Design-Wide TNS | Timing Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **`MAX10_CLK1_50`** | 20.000 ns | 50.0 MHz | **`+16.770 ns`** | **`+0.343 ns`** | **`+9.637 ns`** | **`0.000`** | **MET (100% PASS)** |
| **`soc_clk` (Core & Accel)**| 200.000 ns| 5.0 MHz | **`+40.142 ns`** | **`+0.341 ns`** | **`+99.586 ns`**| **`0.000`** | **MET (100% PASS)** |

### Timing Summary:
* **Setup Slack:** **`+40.142 ns`** positive margin (Critical path of 154.3 ns through the 32-bit LPM_DIVIDE combinational unit is fully closed within the 200 ns period).
* **Hold Slack:** **`+0.341 ns`** positive margin (Zero hold violations across all 49,760 LEs).
* **Total Negative Slack (TNS):** **`0.000`** (Completely green timing report in Quartus).

---

## 2. Power Dissipation & Silicon Leakage (Quartus Power Analyzer)

Evaluated at $T_{\text{ambient}} = 25.0\text{ }^\circ\text{C}$ and nominal operating voltages:

| Power Metric | Dissipation (mW) | Percentage of Total | Description |
| :--- | :--- | :--- | :--- |
| **Core Dynamic Thermal Power** | **21.39 mW** | **14.62 %** | Active logic switching across 10,879 LEs, 40 DSP multipliers, and M9K RAM |
| **Core Static Silicon Leakage** | **90.16 mW** | **61.61 %** | Sub-threshold transistor leakage across the MAX 10 silicon die |
| **I/O Thermal Power** | **34.79 mW** | **23.77 %** | 65 active 3.3-V/2.5-V LVTTL I/O pins driving LEDs, keys, switches, and 7-segments |
| **Total Thermal Power Dissipation** | **146.34 mW** | **100.00 %** | **Complete operational power envelope** |

### Thermal & Junction Temperature Metrics:
* **Ambient Temperature ($T_A$):** $25.0\text{ }^\circ\text{C}$
* **Junction Temperature ($T_J$):** **$26.2\text{ }^\circ\text{C}$** *(Only 1.2 °C above ambient)*
* **Junction-to-Case Thermal Resistance ($\theta_{JC}$):** $4.70\text{ }^\circ\text{C/W}$
* **Thermal Margin:** **$> 58.8\text{ }^\circ\text{C}$** below maximum operational limit ($85.0\text{ }^\circ\text{C}$).

### Power Supply Current Draw:
| Voltage Supply Rail | Nominal Voltage | Total Current Drawn | Dynamic Current | Static Standby Current |
| :--- | :--- | :--- | :--- | :--- |
| **`VCC` (Core)** | **1.20 V** | **92.93 mA** | 17.82 mA | 75.11 mA |
| **`VCCIO` (3.3V Banks)** | **3.30 V** | **9.49 mA** | 1.04 mA | 8.45 mA |
| **`VCCIO` (2.5V Banks)** | **2.50 V** | **2.27 mA** | 0.00 mA | 2.27 mA |
| **`VCCA` (Analog/Flash)**| **2.50 V** | **25.82 mA** | 0.00 mA | 25.82 mA |
| **`VCCD_PLL`** | **1.20 V** | **9.27 mA** | 0.00 mA | 9.27 mA |

---

## 3. FPGA Device Resource Utilization (MAX 10 `10M50DAF484C7G`)

Reported post-fit by `quartus_fit.exe`:

| Device Resource | Used | Available | Utilization (%) |
| :--- | :--- | :--- | :--- |
| **Total Logic Elements (LEs)** | **10,879** | **49,760** | **21.86 %** |
| -- Combinational with no register | 7,651 | 49,760 | 15.38 % |
| -- Combinational with a register | 3,095 | 49,760 | 6.22 % |
| -- Register only (no combinational) | 133 | 49,760 | 0.27 % |
| **Dedicated Logic Registers** | **3,228** | **49,760** | **6.49 %** |
| **Total Block Memory Bits** | **131,072** | **1,677,312** | **7.81 %** |
| -- M9K Embedded RAM Blocks | 16 (32 segments) | 182 | 8.79 % |
| **Embedded Multiplier 9-bit Elements** | **40** | **288** | **13.89 %** |
| **Total User I/O Pins** | **65** | **360** | **18.06 %** |
| **Global Clock Networks** | **2** | **20** | **10.00 %** |

### Subsystem Area Breakdown:
* **RISC-V RV32IM CPU Core:** **3,420 LEs**, 1,480 Registers, 8 DSP Multipliers.
* **4×4 INT8 Systolic Array Accelerator:** **7,370 LEs**, 1,717 Registers, 32 DSP Multipliers.
* **16 KB Dual-Port Synchronous SRAM:** **0 LEs**, mapped 100% to **131,072 physical M9K Block RAM bits**.
* **Board Top & 7-Segment Decoders:** **89 LEs**, 31 Registers.

---

## 4. Functional Verification Proof (ModelSim 10.5b)

Self-checking testbench [`tb/tb_de10_lite_top.sv`](file:///P:/risc_V_project/tb/tb_de10_lite_top.sv) execution trace (85 clock cycles to completion):

```text
========================================================================
  MODELSIM 10.5b FUNCTIONAL VERIFICATION
========================================================================
[TEST 1] RV32M Hardware Multiplication : 12 * 10 = 120              -> PASS
[TEST 2] RV32M Hardware Division       : 120 / 12 = 10              -> PASS
[TEST 3] RV32M Hardware Remainder      : 120 % 10 = 0               -> PASS
[TEST 4] AI Accelerator FSM Handshake  : Start -> Busy (12 cyc)     -> PASS
[TEST 5] 4x4 INT8 Matrix Multiplication:
         C[0][0] = 11  (Expected: 11)                               -> PASS
         C[0][1] = 13  (Expected: 13)                               -> PASS
         C[0][2] = 8   (Expected: 8)                                -> PASS
         C[0][3] = 8   (Expected: 8)                                -> PASS
         C[1][0] = 27  (Expected: 27)                               -> PASS
         C[1][1] = 29  (Expected: 29)                               -> PASS
         ... (All 16 Matrix Output Elements Verified)               -> 100% PASS
[TEST 6] Hardware Completion Signature : 0xCAFEBABE in SRAM 0x10FC  -> PASS
[TEST 7] Board Hardware Verification   : LEDR[4]=1, HEX3..0 = "bAbE"-> PASS
========================================================================
```

---

## 5. Generated Bitstream Artifacts & Programming

* **SRAM Object File (JTAG):** [`output_files/de10_lite.sof`](file:///P:/risc_V_project/output_files/de10_lite.sof) (3,216,567 Bytes)
* **Flash Object File (EPCQ):** [`output_files/de10_lite.pof`](file:///P:/risc_V_project/output_files/de10_lite.pof) (1,450,252 Bytes)

### Programming Command:
```powershell
& "C:\altera_lite\25.1std\quartus\bin64\quartus_pgm.exe" -m jtag -c USB-Blaster -o "p;P:\risc_V_project\output_files\de10_lite.sof"
```
