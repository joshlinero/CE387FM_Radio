setenv LMC_TIMEUNIT -9
vlib work
vmap work work

# fm_radio architecture
vlog -work work "../sv/fifo.sv"
vlog -work work "../sv/gain.sv"
vlog -work work "../sv/gain_top.sv"
vlog -work work "../sv/gain_tb.sv"


vsim -voptargs=+acc +notimingchecks -L work work.gain_tb -wlf gain_tb.wlf

config wave -signalnamewidth 1

add wave -noupdate -group gain_tb
add wave -noupdate -group gain_tb -radix hexadecimal /gain_tb/*

add wave -noupdate -group gain_tb/gain_top_inst
add wave -noupdate -group gain_tb/gain_top_inst -radix hexadecimal /gain_tb/gain_top_inst/*

add wave -noupdate -group gain_tb/gain_top_inst/gain_inst
add wave -noupdate -group gain_tb/gain_top_inst/gain_inst -radix hexadecimal /gain_tb/gain_top_inst/gain_inst/*

add wave -noupdate -group gain_tb/gain_top_inst/fifo_x_in_inst
add wave -noupdate -group gain_tb/gain_top_inst/fifo_x_in_inst -radix hexadecimal /gain_tb/gain_top_inst/fifo_x_in_inst/*

add wave -noupdate -group gain_tb/gain_top_inst/fifo_y_out_inst
add wave -noupdate -group gain_tb/gain_top_inst/fifo_y_out_inst -radix hexadecimal /gain_tb/gain_top_inst/fifo_y_out_inst/*


run -all
#quit;