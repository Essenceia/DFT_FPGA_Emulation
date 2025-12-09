set pdk_lib_path {/home/gp/.ciel/ciel/gf180mcu/versions/0fe599b2afb6708d281543108caf8310912f54af/gf180mcuD/libs.ref/gf180mcu_fd_sc_mcu7t5v0}
set top_module tt_um_essen
set synth_verilog_path {/home/gp/asic/dft_fpga_emulation/runs/wokwi/06-yosys-synthesis}

 
read_lef $pdk_lib_path/techlef/gf180mcu_fd_sc_mcu7t5v0__nom.tlef
read_lef $pdk_lib_path/lef/gf180mcu_fd_sc_mcu7t5v0.lef
read_liberty $pdk_lib_path/lib/gf180mcu_fd_sc_mcu7t5v0__tt_025C_3v30.lib

read_verilog $synth_verilog_path/$top_module.nl.v
link_design $top_module


#report_instance ff1
#scan_replace
#report_instance ff1
#report_dft_plan -verbose
#report_instance ff1
#execute_dft_plan
#report_instance ff1
#
#set verilog_file [make_result_file one_cell_sky130.v]
#write_verilog $verilog_file
#diff_files $verilog_file one_cell_sky130.vok
#
#set def_file [make_result_file one_cell_sky130.def]
#write_def $def_file
#diff_files $def_file one_cell_sky130.defok
