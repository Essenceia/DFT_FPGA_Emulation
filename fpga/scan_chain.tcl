set design_offset m_top
set mux_ref scan_mux


proc read_csv { filename } {
	set_msg_config -id "ScanChain 0" -limit -1 -new_severity WARNING	
	set scan_chain {}
	set clk_domain {}
	set instances_id {}
	set fp [open $filename r]

	while {[gets $fp line] >= 0} {
    	if {[string trim $line] eq ""} continue
       
		set fields [split $line ","]
		if { [llength $fields] != 3} {
			puts "\[ScanChain 0\] Warning: missformed csv line found ! $fields"
		} else {
			# trim : remove whitescapes
			lappend instances_id [string trim [lindex $fields 0]]
			lappend scan_chain [string trim [lindex $fields 1]]
			lappend clk_domain [string trim [lindex $fields 2]]
		}
	}
	return $scan_chain
}

proc new_mux { name } {
	create_cell -reference $mux_ref $name
} 

proc check_net_equivalence { scan_chain } {
	set_msg_config -id "ScanChain 1" -limit -1 -new_severity WARNING	
	set_msg_config -id "ScanChain 2" -limit -1 -new_severity INFO	
	foreach elem $scan_chain {
		set pattern {.*}
		set cell [get_cells -hierarchical -regexp $pattern$elem$pattern ]
		if {[string compare $cell "" ] == 0 } {
			puts "\[ScanChain 1\] Warning: cell not found for scan chain ellement $elem"
		} else {
			puts "\[ScanChain 2\] Info: cell match found for scan chain ellement $elem got $cell"
		}
	}
}
