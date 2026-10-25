# Intel MAX 10 FPGA Power Dissipation & Thermal Report (5 MHz Timing-Closed Core)

**Project Name:** `de10_lite`  
**Target Part:** Intel MAX 10 `10M50DAF484C7G`  
**EDA Tool:** Intel Quartus Prime Lite Edition 25.1std Power Analyzer (`quartus_pow.exe`)  
**Design Top Entity:** `de10_lite_top` (RISC-V RV32IM CPU + 4×4 INT8 Systolic AI Accelerator)  
**Operating Conditions:** $T_{\text{ambient}} = 25.0\text{ }^\circ\text{C}$, $V_{\text{CC}} = 1.20\text{ V}$, $V_{\text{CCIO}} = 3.3\text{ V}$ / $2.5\text{ V}$  
**Timing Status:** **100% Timing Closed (Setup Slack: +40.142 ns, TNS = 0.000)**  

---

## 1. Executive Power Dissipation Summary

| Power Metric | Dissipation (mW) | Percentage of Total | Comparison with 50 MHz Baseline |
| :--- | :--- | :--- | :--- |
| **Core Dynamic Thermal Power** | **21.39 mW** | **14.62 %** | **-89.4 % reduction** (down from 201.33 mW) |
| **Core Static Thermal Power** | **90.16 mW** | **61.61 %** | Constant silicon sub-threshold leakage |
| **I/O Thermal Power** | **34.79 mW** | **23.77 %** | **-34.6 % reduction** (down from 53.17 mW) |
| **Total Thermal Power Dissipation** | **146.34 mW** | **100.00 %** | **-57.6 % overall power reduction** (down from 345.59 mW) |

---

## 2. Thermal & Junction Temperature Analysis

* **Ambient Operating Temperature ($T_A$):** $25.0\text{ }^\circ\text{C}$
* **Junction Temperature ($T_J$):** **$26.2\text{ }^\circ\text{C}$** *(Barely 1.2 °C above ambient!)*
* **Junction-to-Case Thermal Resistance ($\theta_{JC}$):** $4.70\text{ }^\circ\text{C/W}$
* **Thermal Margin:** **$> 58.8\text{ }^\circ\text{C}$** below maximum operational rating ($85.0\text{ }^\circ\text{C}$).

---

## 3. Power Supply Voltage & Current Breakdown

| Voltage Rail | Nominal Voltage | Total Current Drawn | Dynamic Current | Static Standby Current |
| :--- | :--- | :--- | :--- | :--- |
| **`VCC` (Core Logic)** | **1.20 V** | **92.93 mA** | 17.82 mA | 75.11 mA |
| **`VCCIO` (3.3V)** | **3.30 V** | **9.49 mA** | 1.04 mA | 8.45 mA |
| **`VCCIO` (2.5V)** | **2.50 V** | **2.27 mA** | 0.00 mA | 2.27 mA |
| **`VCCA` (Analog/Flash)** | **2.50 V** | **25.82 mA** | 0.00 mA | 25.82 mA |
| **`VCCD_PLL`** | **1.20 V** | **9.27 mA** | 0.00 mA | 9.27 mA |
