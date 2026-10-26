# Terasic DE10-Standard (Cyclone V SX 5CSXFC6D6F31C6) Master Results Report

**Target Board:** Terasic DE10-Standard Development Kit  
**FPGA Device:** Intel Cyclone V SX SoC FPGA (`5CSXFC6D6F31C6N`)  
**Package:** 896-pin FineLine BGA  
**JTAG Programming Cable:** `DE-SoC [USB-1]` (Device Index 2: Cyclone V FPGA)  
**Programming Status:** **Successfully Programmed on Silicon (`quartus_pgm`)**  

---

## 1. Static Timing Analysis (Quartus Timing Analyzer)

Evaluated across Slow 1100mV 85°C, Slow 1100mV 0°C, Fast 1100mV 85°C, and Fast 1100mV 0°C:

| Clock Domain | Period | Target Freq | Worst-Case Setup Slack | Worst-Case Hold Slack | Minimum Pulse Width | Design-Wide TNS | Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **`CLOCK_50` (Oscillator)** | 20.000 ns | 50.0 MHz | **`+16.225 ns`** | **`+0.369 ns`** | **`+8.816 ns`** | **`0.000`** | **100% MET (GREEN)** |
| **`soc_clk` (Core & Accel)**| 200.000 ns| 5.0 MHz | **`+97.834 ns`** | **`+0.175 ns`** | **`+98.871 ns`**| **`0.000`** | **100% MET (GREEN)** |

* **Zero timing violations** across all PVT corners.
* **Setup margin:** Near 100 ns of positive timing margin on the SoC core.

---

## 2. Power Dissipation (Quartus Power Analyzer)

* **Total Thermal Power Dissipation:** **474.86 mW**
* **Device Power Characteristics:** Typical, $T_{\text{ambient}} = 25.0\text{ }^\circ\text{C}$
* **Average Toggle Rate:** 7.133 million transitions / sec

---

## 3. FPGA Resource Utilization (Cyclone V 110K LEs)

| Resource | Used | Available on 5CSXFC6D6F31C6 | Utilization (%) |
| :--- | :--- | :--- | :--- |
| **Logic Cells (ALMs/LEs)** | ~10,707 | 110,000 | **~9.7 %** |
| **Block Memory Bits** | 131,072 | 5,761,000 | **2.27 %** |
| **DSP Elements** | 25 | 224 | **11.16 %** |
| **I/O Pins** | 67 | 499 | **13.43 %** |

---

## 4. Hardware Verification & Board Output Mapping

* **`LEDR[9]` (PIN_AC22):** 1.5 Hz Heartbeat indicator.
* **`LEDR[4]` (PIN_AG25):** Success signature `0xCAFEBABE` verified in SRAM.
* **`LEDR[0]` (PIN_AA24):** AI accelerator matrix multiplication done flag.
* **`SW[0]` (PIN_AB30):** Flip UP to decode `"bAbE"` on `HEX3..HEX0`; Flip DOWN to show CPU Program Counter.
* **`KEY[0]` (PIN_AJ4):** Master system reset (active-low).
