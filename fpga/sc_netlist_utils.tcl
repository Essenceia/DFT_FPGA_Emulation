# netlist manipulation scripts

# get a ff 
# get the D pin net 
# disconnect the D pin net 
# create a new scan mux cell
# connect the output of the scan mux cell to the D ff pin 
# connect the data_i port of the scan mux with the pervious D ff net
# connect the scan enable to the mux select
# connect the previous scan out to the scan_data_i port of the mux
# get the net connected to the ff Q pin, this will be the scan out for the next connection

proc get_cell_pin { ff pin_name } {
	return [get_pins -of_object $ff -filter { REF_PIN_NAME == $pin_name }] 
} 

proc get_pin_net { pin } {
	return [get_nets -of_object $pin]
}

proc insert_scan_mux { ff mux_ref sce sci } {
	puts "Inserting scan mux for $ff"
	set d_pin [get_cell_pin $ff "D"]
	set d_net [get_pin_net $d_pin]
	# disconnect
	disconnect_net -objects $d_pin 
	
	puts "0"	
	# create smux
	set smux_name "[get_property "NAME" $ff]_scanmux" 
	set smux [create_cell -reference $mux_ref $smux_name]
	
	puts "1"
	# connect smux to D
	set smux_ff_d_net_name "${smux_name}_d_net"
	set smux_ff_d_net [create_net $smux_ff_d_net_name]
	# get smux out pin
	set smux_o_pin [get_cell_pin $smux "res_o"]
	connect_net -net $smux_ff_d_net -objects [$smux_o_pin $d_pin]

	puts "2"
	# connect old D net to smux
	set smux_data_i_pin	[get_cell_pin $smux "data_i" ]
	connect_net -net $d_net -objects $smux_data_i_pin

	puts "3"
	# connect scan enable	
	set smux_sce_pin [get_cell_pin $smux "scan_enable_i" ]
	connect_net -hierarchical -net $sce -object $smux_sce_ppin 

	puts "4"
	# connect scan_i 
	set smux_sci_pin [get_cell_pin $smux "scan_i" ]
	connect_net -hierarchical -net $sci -object $smux_sci_pin

	# return ff Q net 
	set q_pin [get_cell_pin $ff "Q"]
	return [get_pin_net $q_pin]
}  

proc insert_scan_chain { ff_dict smux_ref sci_pin sco_pin sce_pin } {
	puts "0 pin $sci_pin"
	set sci_net_name "[get_property "NAME" $sci_pin]_net"
	set sci_net [create_net $sci_net_name]
	disconnect_net -object $sci_pin
	connect_net -net $sci_net -object $sci_pin

	puts "1 pin $sce_pin"
	set sce_net_name "[get_property "NAME" $sce_pin]_net"
	set sce_net [create_net $sce_net_name]
	disconnect_net -object $sce_pin
	connect_net -net $sce_net -object $sce_pin
 
	set sci $sci_net
	set sce $sce_net
	dict for {net ff_cell} $ff_dict {
		set sci [ insert_scan_mux $ff_cell $smux_ref $sce $sci ]
	}
	# get pin connected to sco
	disconnect_net -object $sco_pin
	connect_net -hierarchical -net $sci -object $sco_pin
}	


