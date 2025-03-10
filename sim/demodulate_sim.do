setenv LMC_TIMEUNIT -9
vlib work
vmap work work

# fm_radio architecture
vlog -work work "../sv/fifo.sv"
vlog -work work "../sv/divider_work.sv"
vlog -work work "../sv/qarctan.sv"
vlog -work work "../sv/demodulate.sv"
vlog -work work "../sv/demodulate_top.sv"
vlog -work work "../sv/demodulate_tb.sv"


vsim -voptargs=+acc +notimingchecks -L work work.demodulate_tb -wlf demodulate_tb.wlf

config wave -signalnamewidth 1

add wave -noupdate -group demodulate_tb
add wave -noupdate -group demodulate_tb -radix hexadecimal /demodulate_tb/*

add wave -noupdate -group demodulate_tb/demodulate_top_inst
add wave -noupdate -group demodulate_tb/demodulate_top_inst -radix hexadecimal /demodulate_tb/demodulate_top_inst/*

add wave -noupdate -group demodulate_tb/demodulate_top_inst/demodulate_inst
add wave -noupdate -group demodulate_tb/demodulate_top_inst/demodulate_inst -radix hexadecimal /demodulate_tb/demodulate_top_inst/demodulate_inst/*

add wave -noupdate -group demodulate_tb/demodulate_top_inst/demodulate_inst/qarctan_inst
add wave -noupdate -group demodulate_tb/demodulate_top_inst/demodulate_inst -radix hexadecimal /demodulate_tb/demodulate_top_inst/demodulate_inst/qarctan_inst/*

add wave -noupdate -group demodulate_tb/demodulate_top_inst/demodulate_inst/qarctan_inst/divider_inst
add wave -noupdate -group demodulate_tb/demodulate_top_inst/demodulate_inst -radix hexadecimal /demodulate_tb/demodulate_top_inst/demodulate_inst/qarctan_inst/divider_inst/*

add wave -noupdate -group demodulate_tb/demodulate_top_inst/real_input_fifo
add wave -noupdate -group demodulate_tb/demodulate_top_inst/real_input_fifo -radix hexadecimal /demodulate_tb/demodulate_top_inst/real_input_fifo/*

add wave -noupdate -group demodulate_tb/demodulate_top_inst/imag_input_fifo
add wave -noupdate -group demodulate_tb/demodulate_top_inst/imag_input_fifo -radix hexadecimal /demodulate_tb/demodulate_top_inst/imag_input_fifo/*

add wave -noupdate -group demodulate_tb/demodulate_top_inst/output_fifo
add wave -noupdate -group demodulate_tb/demodulate_top_inst/output_fifo -radix hexadecimal /demodulate_tb/demodulate_top_inst/output_fifo/*

run -all
#quit;