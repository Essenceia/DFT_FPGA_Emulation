set mux_ref scan_mux

proc read_csv { filename } {
	set scan_chain {}
 
	return $scan_chain
}

proc new_mux { name } {
	create_cell -reference $mux_ref $name
} 
