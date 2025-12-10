# DFT Scan Chain Emulation on FPGA

The objective of this project is to create a set of tools to replicate a scan chain inserted post placement 
by the ASIC OpenRoad flow to an FPGA netlist in order to proprty emulate the scan chain.

## OpenRoad to Vivado 

The goal is to extract an dft scan chain topology defined during the OpenRoad implementation and replicate
it in an Vivado FPGA netlist. 

### OpenRoad output 

Utilities in the `dft/utils.tcl` file are used to extract a scan chain toplogy and store it to a the `csv` 
format. 
In our example flow, this file will be rendered in `dft/results/translation-tcl.csv`. 

### Vivado input

Vivado will take this `csv` as an input to manipulate the netlist. 
