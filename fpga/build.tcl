set project_path [lindex $argv 0]
set checkpoint_path [lindex $argv 1]
set enable_scan_chain [lindex $argv 2]
if { $argc > 3 } {
	set enable_debug_core [lindex $argv 3]
	set debug_probes_path [lindex $argv 4]
} else {
	set enable_debug_core 0
	set debug_probes_path "/tmp/dump"
}
puts "Implementation script called with project path $project_path, generating checkpoint at $checkpoint_path"

open_project $project_path 

# synth
if { $enable_scan_chain } {
	synth_design -top emulator -verilog_define VIVADO_SYNTHESIS=1 -flatten_hierarchy none -no_lc -keep_equivalent_registers -no_srlextract -max_bram 0 -max_uram 0
	source scan_chain.tcl
} else {
	synth_design -top emulator
}

if { $enable_debug_core } {
	source debug_core.tcl
} 

# implement
opt_design
place_design
route_design
phys_opt_design
report_timing_summary -no_detailed_paths

if { $enable_debug_core } {
	write_debug_probes -force $debug_probes_path
	report_debug_core
}

write_checkpoint $checkpoint_path -force 
close_project
exit 0
