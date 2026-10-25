package require ::quartus::sta
project_open de10_lite
create_timing_netlist
read_sdc
update_timing_netlist

puts "\n================= WORST SETUP PATHS ================="
report_timing -setup -npaths 5 -detail path_only
puts "====================================================\n"

delete_timing_netlist
project_close
