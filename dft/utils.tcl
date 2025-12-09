proc get_driving_dff_inst { net } {
	foreach p [get_pins -of_object $net] {
		set driver_pin [get_name $p] 
		if {$driver_pin == "Q"} {
			return [$p instance]
		}
	}
	puts "WARNING: driving ff not found for [get_name $net]"
}

proc get_all_jtag_ff { match } {
	set ff_inst {}
	set nets [get_nets $match]
	foreach n $nets {
		lappend ff_inst [get_driving_dff_inst $n]
	}
	return $ff_inst
}

proc set_dont_touch_instance_list { ilist } {
	foreach i $ilist {
		set_dont_touch $i
	}
}

proc clear_dont_touch_instance_list { ilist } {
foreach i $ilist {
		unset_dont_touch $i
	}	
}

proc add_scan_chain { } {
	# exclude jtag from scan chain
	set jtag_inst_list [get_all_jtag_ff m_jtag*]
	set_dont_touch_instance_list $jtag_inst_list 
	report_dont_touch 
	
	scan_replace

	report_dft_plan -verbose 

	execute_dft_plan 

	clear_dont_touch_instance_list $jtag_inst_list

	report_dont_touch
}

	
	 

