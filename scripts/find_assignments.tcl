package require ::quartus::project
project_open de10_lite
set test_vals {
    "INTERNAL CONFIGURATION"
    "Internal Configuration"
    "Single Image with ERAM"
    "Single uncompressed image with Memory Initialization"
}
foreach v $test_vals {
    catch {set_global_assignment -name MAX10FPGA_CONFIGURATION_SCHEME $v} err
    if {$err == ""} {
        puts "SUCCESS: $v is legal for MAX10FPGA_CONFIGURATION_SCHEME!"
    }
}
project_close
