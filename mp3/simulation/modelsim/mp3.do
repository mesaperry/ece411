transcript on
if {[file exists rtl_work]} {
    vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

set mp3_path [pwd]

vlog -reportprogress 300 -work work $mp3_path/../../hdl/rv32i_mux_types.sv
vlog -reportprogress 300 -work work $mp3_path/../../hdl/rv32i_types.sv
vlog -reportprogress 300 -work work $mp3_path/../../hdl/*.sv
vlog -reportprogress 300 -work work $mp3_path/../../hdl/cache/*.sv
vlog -reportprogress 300 -work work $mp3_path/../../hdl/cpu/cpu_golden_modelsim.vp
vlog -reportprogress 300 -work work $mp3_path/../../hvl/*.sv
vlog -reportprogress 300 -work work $mp3_path/../../hvl/*.v

vsim -t 1ps -gui -L rtl_work -L work mp3_tb

add wave sim:/mp3_tb/clk
add wave -group {Cache} -radix hexadecimal sim:/mp3_tb/dut/cache/*
add wave -group {RVFI Monitor} -radix hexadecimal sim:/mp3_tb/monitor/rvfi_*
view structure
view signals
run -all