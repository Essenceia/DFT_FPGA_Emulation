set asic_dff_csv_path "../dft/results/translation-tcl.csv"
set remap_csv_path "scan_chain_remapping.csv"
set mux_ref scan_mux
set sci_pin [get_pins -hier -regexp  ".*m_jtag_tap.scan_in_o"]
set sco_pin [get_pins -hier -regexp  ".*m_jtag_tap.scan_out_i"]
set sce_pin [get_pins -hier -regexp  ".*m_jtag_tap.scan_enable_o"]
 

source sc_remap_utils.tcl
source sc_netlist_utils.tcl

set ff_dict [read_scan_chain $asic_dff_csv_path $remap_csv_path]

puts "sci pin $sci_pin"
puts "sco pin $sco_pin"
puts "sce pin $sce_pin"
puts "mux ref $mux_ref"
insert_scan_chain $ff_dict $mux_ref $sci_pin $sco_pin $sce_pin

write_checkpoint -force emulator/post_scan_chain_insert.dcp
