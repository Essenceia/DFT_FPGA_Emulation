LIBERTY_PATH=/home/gp/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib
V_CODE=$(wildcard ../src/*.v)
TOP_NAME=tt_um_essen
.PHONY: synth

synth: 
	yosys -p 'read_liberty -ignore_miss_func $(LIBERTY_PATH)' \
	-p 'read -sv ${V_CODE}' \
	-p 'hierarchy -check -top ${TOP_NAME} ' \
	-p 'proc_clean' \
	-p 'proc_rmdead' \
	-p 'proc_init' \
	-p 'proc_arst' \
	-p 'proc_mux' \
	-p 'proc_dff' \
	-p 'proc_clean' \
	-p 'opt_expr' \
	-p 'check' \
	-p 'opt_clean' \
	-p 'flatten' \
	-p 'fsm' \
	-p 'share' \
	-p 'memory -nomap' \
	-p 'techmap' \
	-p 'abc -fast' \
	-p 'opt -fast' \
	-p 'check' \
	-p 'stat' \
	-p 'write_json ${TOP_NAME}.rpt.json' \
	-p 'write_table ${TOP_NAME}.rpt.table' \
	-p 'write_verilog -attr2comment ${TOP_NAME}.rpt.v' 

