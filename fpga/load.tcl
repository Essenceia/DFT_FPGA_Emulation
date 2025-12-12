open_project emulator/emulator.xpr
synth_design -top emulator -verilog_define VIVADO_SYNTHESIS=1 -flatten_hierarchy none -no_lc -keep_equivalent_registers -no_srlextract -max_bram 0 -max_uram 0
source scan_chain.tcl
