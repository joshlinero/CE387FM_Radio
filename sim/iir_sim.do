setenv LMC_TIMEUNIT -9
vlib work
vmap work work

# fm_radio architecture
vlog -work work "../sv/fifo.sv"
vlog -work work "../sv/iir.sv"
vlog -work work "../sv/iir_top.sv"
vlog -work work "../sv/iir_tb.sv"


vsim -voptargs=+acc +notimingchecks -L work work.iir_tb -wlf iir_tb.wlf

add wave -noupdate -group iir_tb
add wave -noupdate -group iir_tb -radix hexadecimal /iir_tb/*

add wave -noupdate -group iir_tb/iir_top_inst
add wave -noupdate -group iir_tb/iir_top_inst -radix hexadecimal /iir_tb/iir_top_inst/*

add wave -noupdate -group iir_tb/iir_top_inst/iir_inst
add wave -noupdate -group iir_tb/iir_top_inst/iir_inst -radix hexadecimal /iir_tb/iir_top_inst/iir_inst/*

add wave -noupdate -group iir_tb/iir_top_inst/fifo_x_in_inst
add wave -noupdate -group iir_tb/iir_top_inst/fifo_x_in_inst -radix hexadecimal /iir_tb/iir_top_inst/fifo_x_in_inst/*

add wave -noupdate -group iir_tb/iir_top_inst/fifo_y_out_inst
add wave -noupdate -group iir_tb/iir_top_inst/fifo_y_out_inst -radix hexadecimal /iir_tb/iir_top_inst/fifo_y_out_inst/*


run -all
#quit;