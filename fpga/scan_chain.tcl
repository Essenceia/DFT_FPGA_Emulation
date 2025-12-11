set design_offset m_top
set mux_ref scan_mux

# scan chain signal remappings, these equivalences are hand written
proc scan_chain_remapping_read_csv { filename } {
	set_msg_config -id "ScanChain 6" -limit -1 -new_severity ERROR
	dict create sc_remap
	set fp [open $filename r]

	while {[gets $fp line] >= 0} {
    	if {[string trim $line] eq ""} continue
       
		set fields [split $line ","]
		if { [llength $fields] != 2} {
			puts "\[ScanChain 6\] Error: missformed csv line found, execpting 2 ellements ! $fields"
		} else {
			# trim : remove whitescapes
			set orig [string trim [lindex $fields 0]]
			set target [string trim [lindex $fields 1]]
			dict set sc_renamp $orig $target
		}
	}
	return $sc_remap	
}

proc scan_chain_remapping_apply { remap_dict sc_list }{
	set new_sc {}
	foreach elem $sc_list {
		if { dict exists remap_dict $elem } {
			set elem [ dict get $elem ]
		}
		lapend new_sc $elem
	}
	return $new_sc
}

proc scan_chain_read_csv { filename } {
	set_msg_config -id "ScanChain 0" -limit -1 -new_severity ERROR	
	set scan_chain {}
	set clk_domain {}
	set instances_id {}
	set fp [open $filename r]

	while {[gets $fp line] >= 0} {
    	if {[string trim $line] eq ""} continue
       
		set fields [split $line ","]
		if { [llength $fields] != 3} {
			puts "\[ScanChain 0\] Error: missformed csv line found ! $fields"
		} else {
			# trim : remove whitescapes
			lappend instances_id [string trim [lindex $fields 0]]
			lappend scan_chain [string trim [lindex $fields 1]]
			lappend clk_domain [string trim [lindex $fields 2]]
		}
	}
	return $scan_chain
}

proc rework_scan_chain_names { scan_chain } {
	set newsc {}
	foreach elem $scan_chain {
		# clean up escape characters
		regsub -all {\\} $elem {} elem
		# replace names that end in '_o' with '_q'
		regsub {(.*)_o(\[\d+\])*$} $elem {\1_q\2\3\4\5\6} elem

		# remove all generate hierarchical delimiter

		# add back escape sequences
		regsub -all {\[} $elem {\[} elem
		regsub -all {\]} $elem {\]} elem
		lappend newsc $elem
	}
	return $newsc
}

proc search_net_pattern { original_elem elem dic } {
	set pattern {.*}
	set cell [get_nets -hierarchical -regexp $pattern$elem$pattern ]
	if {[string compare $cell "" ] == 0} {
		puts "\[ScanChain 3\] Warning: net not found for pattern $elem"
	} else {
		dict set dic $original_elem $cell 
	}
	return $dic
}

proc check_net_equivalence { scan_chain } {
	set sc_dict [dict create]
	set_msg_config -id "ScanChain 1" -limit -1 -new_severity WARNING	
	set_msg_config -id "ScanChain 3" -limit -1 -new_severity WARNING	
	set_msg_config -id "ScanChain 4" -limit -1 -new_severity WARNING	
	set_msg_config -id "ScanChain 5" -limit -1 -new_severity WARNING	
	set_msg_config -id "ScanChain 2" -limit -1 -new_severity INFO
	puts "Hello"	
	foreach elem $scan_chain {
		set pattern {.*}
		set cell [get_nets -hierarchical -regexp $pattern$elem$pattern ]
		if {[string compare $cell "" ] == 0 } {
			#puts "\[ScanChain 1\] Warning: cell not found for scan chain ellement $elem"
			# check generate blocks
			set elem2 ""
			set elem3 ""
			regsub -all {\.} $elem {.*} elem2
			regsub -all {_q} $elem2 {_q_reg.*} elem3
			regsub -all {_q} $elem2 {_o.*} elem4
			set cell2 [get_nets -hierarchical -regexp $pattern$elem2$pattern ]
			if {[string compare $cell2 "" ] == 0} {
				#puts "\[ScanChain 3\] Warning: cell not found after rework $elem2 ( $elem )"
				set cell [get_nets -hierarchical -regexp $pattern$elem3$pattern ]
				if {[string compare $cell "" ] == 0} {
					#puts "\[ScanChain 4\] Warning: cell not found after rework $elem3 ( $elem )"
					set cell [get_nets -hierarchical -regexp $pattern$elem4$pattern ]
					if {[string compare $cell "" ] == 0} {
						puts "\[ScanChain 4\] Warning: cell not found after rework $elem4 ( $elem )"
					} else { 
						dict set sc_dict $elem $cell
					}
				} else { 
					dict set sc_dict $elem $cell
				}
			} else {
				dict set sc_dict $elem $cell2
			}
			
		} else {
			dict set sc_dict $elem $cell
			#puts "\[ScanChain 2\] Info: cell match found for scan chain ellement $elem got $cell"
		}
	}
	#return $sc_dict
}

proc add_scan_chain { sc_filename sc_equivalence_filename } {
	# read ASIC implementation rendered scan chain
	set sc [ scan_chain_read_cvs $sc_filename ]
	if { [string compares $sc_equivalence_filename "" ] == 0 } {
		set sc [ scan_chain_remapping_apply [ scan_chain_read_cvs $sc_equivalence_filename ] $sc ]
	}
	set sc [ rework_scan_chain_names $sc ]
	check_net_equivalence $sc
}
