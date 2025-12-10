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

proc rework_scan_chain_names { scan_chain } {
	set newsc {}
	foreach elem $scan_chain {
		# clean up escape characters
		regsub -all {\\} $elem {} elem
		# replace names that end in '_q' with '_q_reg'
		regsub {(.*)_q(\[\d+\])*$} $elem {\1_q_reg\2\3\4\5\6} elem
		# replace names that end in '_o' with '_q_reg'
		regsub {(.*)_o(\[\d+\])*$} $elem {\1_q_reg\2\3\4\5\6} elem

		# add back escape sequences
		regsub -all {\[} $elem {\[} elem
		regsub -all {\]} $elem {\]} elem
		lappend newsc $elem
	}
	return $newsc
}

proc check_net_equivalence { scan_chain } {
	set_msg_config -id "ScanChain 1" -limit -1 -new_severity WARNING	
	set_msg_config -id "ScanChain 2" -limit -1 -new_severity INFO
	puts "Hello"	
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
