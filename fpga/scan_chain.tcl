set design_offset m_top
set mux_ref scan_mux

proc init_scan_chain_logging { } {
	set_msg_config -id "ScanChain 0" -limit -1 -new_severity ERROR	
	set_msg_config -id "ScanChain 1" -limit -1 -new_severity WARNING	
	set_msg_config -id "ScanChain 2" -limit -1 -new_severity INFO
	set_msg_config -id "ScanChain 3" -limit -1 -new_severity WARNING	
	set_msg_config -id "ScanChain 4" -limit -1 -new_severity ERROR	
	set_msg_config -id "ScanChain 5" -limit -1 -new_severity WARNING	
	set_msg_config -id "ScanChain 6" -limit -1 -new_severity ERROR
	set_msg_config -id "ScanChain 7" -limit -1 -new_severity INFO
	set_msg_config -id "ScanChain 8" -limit -1 -new_severity ERROR
	set_msg_config -id "ScanChain 9" -limit -1 -new_severity INFO
	set_msg_config -id "ScanChain 10" -limit -1 -new_severity INFO
	set_msg_config -id "ScanChain 11" -limit -1 -new_severity ERROR
}


# scan chain signal remappings, these equivalences are hand written
proc scan_chain_remapping_read_csv { filename } {
	set sc_remap [dict create]
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
			puts "\[ScanChain 7\] Info: remapping '$orig' -> '$target'"
			dict set sc_remap $orig $target
		}
	}
	return $sc_remap	
}

proc scan_chain_remapping_apply { remap_dict sc_list } {
	set new_sc {}
	foreach elem $sc_list {
		if { [dict exists $remap_dict $elem] } {
			set elem [ dict get $remap_dict $elem ]
		}
		lappend new_sc $elem
	}
	return $new_sc
}

proc scan_chain_read_csv { filename } {
	set scan_chain {}
	set fp [open $filename r]

	while {[gets $fp line] >= 0} {
    	if {[string trim $line] eq ""} continue
       
		set fields [split $line ","]
		if { [llength $fields] != 3} {
			puts "\[ScanChain 0\] Error: missformed csv line found ! $fields"
		} else {
			# trim : remove whitescapes
			lappend scan_chain [string trim [lindex $fields 1]]
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

proc set_net_equivalence { scan_chain } {
	set sc_dict [dict create]
	foreach elem $scan_chain {
		set pattern {.*}
		set cell [get_nets -hierarchical -regexp $pattern$elem$pattern ]
		if {[string compare $cell "" ] == 0 } {
			# check generate blocks
			set elem2 ""
			set elem3 ""
			regsub -all {\.} $elem {.*} elem2
			regsub -all {_q} $elem2 {_q_reg.*} elem3
			regsub -all {_q} $elem2 {_o.*} elem4
			set cell2 [get_nets -hierarchical -regexp $pattern$elem2$pattern ]
			if {[string compare $cell2 "" ] == 0} {
				set cell [get_nets -hierarchical -regexp $pattern$elem3$pattern ]
				if {[string compare $cell "" ] == 0} {
					set cell [get_nets -hierarchical -regexp $pattern$elem4$pattern ]
					if {[string compare $cell "" ] == 0} {
						puts "\[ScanChain 4\] Error: cell not found after rework $elem4 ( $elem )"
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
		}
	}
	return $sc_dict
}

proc log_dict { d } {
	dict for {key value} $d {
    	puts "$key $value"
	}
}

proc identify_parent_ff { net cells } {
	foreach c $cells {
		set p [get_pins -of_objects $net -filter "PARENT_CELL == $c"]
 		set pin_name [get_property "REF_PIN_NAME" $p]
		if { [string compare $pin_name "Q"] == 0 } {
			return $c
		} 
	}	
}

proc search_through_output_port { net } {
	# get pin connected to net 
	set p [get_pins -of_object $net] 
	# go down one level of hierarchy
	set nl [get_nets -boundary_type lower -of_object $p]
	# search for the flop driving this net
	set ff [ get_cells -of_object $nl -filter { PRIMITIVE_GROUP == "FLOP_LATCH" }]

	if { [llength $ff ] != 1 } {
		#puts "\[ScanChain 11\] Info: can't find flops when puching though module for driving $net got $ff"		
		return
	}	
	return $ff
}

proc validate_net_is_ff_q { ff net } {
	set q_pin [get_pin -of_object $ff -filter { REF_PIN_NAME == "Q" }]
	set q_net [get_nets -of_object $q_pin]
	set net_name [get_property "NAME" $net]
	set q_net_name [get_property "NAME" $q_net]	
	if { [string compare $net_name $q_net_name] != 0 } {
		puts "\[ScanChain 12\] Info: flops $ff doesn't have $net connected to Q,\ngot $net_name\nexpecting $q_net_name"
		return 0		
	}  
	return 1
}

proc search_upstream { net } { 
	# input pin should have the same name as the net
	#set p [get_pins -of_object $n -filter "NAME == [get_property "NAME" $n]"]
	#segments gives an ordered list, where the first ellement is the root of the tree
	set segs [get_nets $net -segments]
	set seg [lindex $segs 0]
	set ffs [get_cells -of_object $seg -filter { PRIMITIVE_GROUP == "FLOP_LATCH" }]
	foreach ff $ffs {
		# for a ciruit with a single wire between multiple ff : ff0 -> net -> ff1
		# select ff- for which the net is downstream of
		if { [validate_net_is_ff_q $ff $seg] == 1 } {
			return $ff
		}
	} 
	puts "\[ScanChain 13\] Info: Failed to find ff connected to $seg got : $ffs, original net $net"
	return
}

proc get_upstream_ff { net } {
	set cell [get_cells -of_object $net -filter { PRIMITIVE_GROUP == "FLOP_LATCH" }]
	if { [ llength $cell ] == 1 } {
		return $cell 
	} 
	if { [llength $cell ] > 1 } {
		set cell [identify_parent_ff $net $cell]
		if { [llength $cell ] == 1 } { 
			return $cell 
		}
	}
	set cell [ search_through_output_port $net ]
	if { [llength $cell] == 1 } {
		return $cell
	}
	set cell [ search_upstream $net ]
	if { [llength $cell ] == 1 } {
		return $cell
	}
	puts "\[ScanChain 8\] Error: didn't find identifiable ff parent for net $net got ([llength $cell]) $cell"
	return
}

proc add_scan_chain { sc_filename sc_equivalence_filename } {
	# read ASIC implementation rendered scan chain
	set sc [ scan_chain_read_csv $sc_filename ]
	if { [string compare $sc_equivalence_filename "" ] != 0 } {
		set sc [ scan_chain_remapping_apply [ scan_chain_remapping_read_csv $sc_equivalence_filename ] $sc ]
	}
	set sc [ rework_scan_chain_names $sc ]
	set net_map [set_net_equivalence $sc]
	#log_dict $net_map
	dict for {net_name fpga_net} $net_map {
		get_upstream_ff $fpga_net
	} 
}
