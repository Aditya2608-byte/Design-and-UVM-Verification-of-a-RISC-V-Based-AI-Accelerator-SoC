## ==============================================================================
## File: synthesis/constraints_template.xdc
## Description: FPGA Physical Constraints Template for RISC-V + AI Accelerator SoC
## Target Architecture: Xilinx 7-Series (Artix-7 / Zynq-7000)
## ==============================================================================

## -----------------------------------------------------------------------------
## 1. Primary Clock Constraint
## -----------------------------------------------------------------------------
## Adjust clock period to match your onboard oscillator (e.g., 100MHz = 10.000ns)
create_clock -period 10.000 -name sys_clk_pin -waveform {0.000 5.000} [get_ports clk]

## -----------------------------------------------------------------------------
## 2. Board Pin Mappings (Uncomment and set PACKAGE_PIN for your specific board)
## -----------------------------------------------------------------------------
## Clock Input
# set_property -dict { PACKAGE_PIN E3  IOSTANDARD LVCMOS33 } [get_ports clk]

## Active-Low Asynchronous Reset (e.g., onboard push button or CPU RESET)
# set_property -dict { PACKAGE_PIN C12 IOSTANDARD LVCMOS33 } [get_ports rst_n]

## Status LEDs
## Accel Done Indicator
# set_property -dict { PACKAGE_PIN H17 IOSTANDARD LVCMOS33 } [get_ports accel_done]

## Data Request Activity
# set_property -dict { PACKAGE_PIN K15 IOSTANDARD LVCMOS33 } [get_ports data_req]

## Write Enable Activity
# set_property -dict { PACKAGE_PIN J13 IOSTANDARD LVCMOS33 } [get_ports data_we]

## -----------------------------------------------------------------------------
## 3. Implementation & Timing Exceptions
## -----------------------------------------------------------------------------
## Asynchronous reset false path
set_false_path -from [get_ports rst_n]
