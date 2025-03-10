setenv LMC_TIMEUNIT -9
vlib work
vmap work work

# fm_radio architecture
vlog -work work "../sv/fifo.sv"
vlog -work work "../sv/fir.sv"
vlog -work work "../sv/fir_top.sv"
vlog -work work "../sv/fir_tb.sv"


vsim -voptargs=+acc +notimingchecks -L work work.fir_tb -wlf fir_tb.wlf

config wave -signalnamewidth 1

add wave -noupdate -group fir_tb
add wave -noupdate -group fir_tb -radix hexadecimal /fir_tb/*

add wave -noupdate -group fir_tb/fir_top_inst
add wave -noupdate -group fir_tb/fir_top_inst -radix hexadecimal /fir_tb/fir_top_inst/*

add wave -noupdate -group fir_tb/fir_top_inst/fir_inst
add wave -noupdate -group fir_tb/fir_top_inst/fir_inst -radix hexadecimal /fir_tb/fir_top_inst/fir_inst/*

add wave -noupdate -group fir_tb/fir_top_inst/fifo_x_in_inst
add wave -noupdate -group fir_tb/fir_top_inst/fifo_x_in_inst -radix hexadecimal /fir_tb/fir_top_inst/fifo_x_in_inst/*

add wave -noupdate -group fir_tb/fir_top_inst/fifo_y_out_inst
add wave -noupdate -group fir_tb/fir_top_inst/fifo_y_out_inst -radix hexadecimal /fir_tb/fir_top_inst/fifo_y_out_inst/*


run -all
#quit;