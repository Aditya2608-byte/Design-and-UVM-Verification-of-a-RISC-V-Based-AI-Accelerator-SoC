# Terasic DE10-Lite FPGA Hardware Bring-Up Guide
## RISC-V (RV32IM) + AI Accelerator SoC

**Target Board:** Terasic DE10-Lite  
**FPGA Device:** Intel MAX 10 (`10M50DAF484C7G`)  
**Clock:** 50 MHz (`MAX10_CLK1_50` on `PIN_P11`)  
**Design Status:** Functionally Verified & Board Simulation Verified (100% Pass)  
**Project Review Deadline:** 28 October 2026  

---

## 1. Board Pinout & Peripheral Mapping

The top-level entity [`rtl/de10_lite_top.sv`](file:///P:/project 1/rtl/de10_lite_top.sv) integrates the SoC directly with the DE10-Lite board peripherals:

| Peripheral | Board Pin | FPGA Signal | Function / Description |
|---|---|---|---|
| **50 MHz Clock** | `PIN_P11` | `MAX10_CLK1_50` | Primary 50 MHz system clock source |
| **Pushbutton 0** | `PIN_B8` | `KEY[0]` | Active-Low Hardware Reset (Press to hold reset) |
| **Pushbutton 1** | `PIN_A7` | `KEY[1]` | User auxiliary button |
| **Switch 0** | `PIN_C10` | `SW[0]` | **Display Mode Switch**:<br>• `SW[0] = 0`: Displays CPU Program Counter on HEX displays<br>• `SW[0] = 1`: Displays test signature `bAbE` on HEX displays |
| **LED 0** | `PIN_A8` | `LEDR[0]` | **Accelerator Done** (Lights up when MatMul finishes) |
| **LED 1** | `PIN_A9` | `LEDR[1]` | **Accelerator Busy** (Lights during matrix compute) |
| **LED 2** | `PIN_A10` | `LEDR[2]` | **Accelerator Error** (High if illegal state) |
| **LED 3** | `PIN_B10` | `LEDR[3]` | **Bus Transaction Activity** (Flashes during SRAM/MMIO accesses) |
| **LED 4** | `PIN_D13` | `LEDR[4]` | **🏆 Signature Verified LED** (Lights solid when CPU successfully writes `0xCAFEBABE`) |
| **LED 8** | `PIN_A11` | `LEDR[8]` | **In-Reset Indicator** (Lit when `KEY[0]` is pressed) |
| **LED 9** | `PIN_B11` | `LEDR[9]` | **Heartbeat Blink** (1.5 Hz blink confirms active 50 MHz clock) |
| **7-Segment Displays** | `HEX5..HEX0` | `HEX[5:0]` | Shows active CPU PC or test signature `bAbE` in hexadecimal |

---

## 2. Step-by-Step FPGA Compilation in Intel Quartus Prime Lite

### Step 1: Open the Project
1. Launch **Intel Quartus Prime Lite Edition** (v20.1 or newer).
2. Go to **File -> Open Project...**
3. Browse to `P:\project 1` and select:
   ```
   P:\project 1\de10_lite.qpf
   ```
   *(All device assignments, pin locations, I/O standards, and timing constraints are automatically configured in `de10_lite.qsf` and `de10_lite.sdc`.)*

### Step 2: Compile the Design
1. In the top toolbar, click the purple **"Start Compilation"** Play button (or press `Ctrl + L`).
2. Quartus will run:
   - **Analysis & Synthesis (`quartus_map`)**
   - **Fitter (Place & Route, `quartus_fit`)**
   - **Assembler (Generate `.sof` bitstream, `quartus_asm`)**
   - **TimeQuest Timing Analyzer (`quartus_sta`)**
3. Once completed (100%), the SRAM Object File will be generated at:
   ```
   output_files/de10_lite.sof
   ```

---

## 3. Programming the DE10-Lite Board

1. Connect the DE10-Lite to your PC using the included **Type-A to Type-B USB cable**.
2. Ensure the USB-Blaster II driver is recognized under Windows Device Manager.
3. In Quartus Prime, go to **Tools -> Programmer**.
4. In the Programmer window:
   - Click **Hardware Setup...** and select **USB-Blaster [USB-0]**.
   - Mode should be set to **JTAG**.
   - If the device is not shown, click **Auto Detect** and select **10M50DA**.
   - Select the `10M50DA` chip, click **Change File...**, and navigate to:
     ```
     output_files/de10_lite.sof
     ```
   - Check the **Program/Configure** checkbox.
   - Click **Start**. The progress bar will reach 100% (Successful).

---

## 4. Live Hardware Demonstration Procedure (For Review on Oct 28)

1. **Power-On / Reset Test:**
   - Press and hold `KEY[0]`.
   - `LEDR[8]` turns ON (indicates reset is asserted).
   - Release `KEY[0]`. `LEDR[8]` turns OFF.
   - `LEDR[9]` immediately starts blinking (1.5 Hz heartbeat confirming clock is alive).

2. **Inference Execution & Success Verification:**
   - Within milliseconds, the RISC-V CPU executes the bootloader, verifies RV32M multiplier instructions, configures the 4x4 INT8 systolic array, triggers inference, reads back matrix outputs, and stores results to SRAM.
   - **`LEDR[0]`** lights up (AI Accelerator Done flag).
   - **`LEDR[4]`** lights up solid: Confirms test signature `0xCAFEBABE` written to memory!

3. **7-Segment Display Demonstration:**
   - Set **`SW[0] = 1`**:
     The four 7-segment displays `HEX3`, `HEX2`, `HEX1`, `HEX0` will display:
     ```
     [ b ] [ A ] [ b ] [ E ]
     ```
     *(Literally spelling the verified hex signature `bAbE` on physical hardware!)*
   - Set **`SW[0] = 0`**:
     The displays show the CPU's halting Program Counter value.
