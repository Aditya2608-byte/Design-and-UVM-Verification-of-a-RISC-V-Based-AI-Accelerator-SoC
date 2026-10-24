## ==============================================================================
## File: synthesis/de10_lite.sdc
## Description: Synopsys Design Constraints for DE10-Lite (50 MHz Clock)
## ==============================================================================

# 50 MHz Primary Input Clock (20.000 ns period)
create_clock -period 20.000 -name MAX10_CLK1_50 [get_ports MAX10_CLK1_50]

# Automatically derive clock uncertainties
derive_clock_uncertainty

# Asynchronous inputs / user keys
set_false_path -from [get_ports {KEY[*]}]
set_false_path -from [get_ports {SW[*]}]

# User LEDs and 7-segment display outputs (display only, not timing critical)
set_false_path -to [get_ports {LEDR[*]}]
set_false_path -to [get_ports {HEX0[*]}]
set_false_path -to [get_ports {HEX1[*]}]
set_false_path -to [get_ports {HEX2[*]}]
set_false_path -to [get_ports {HEX3[*]}]
set_false_path -to [get_ports {HEX4[*]}]
set_false_path -to [get_ports {HEX5[*]}]
