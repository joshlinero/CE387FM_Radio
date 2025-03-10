setenv LMC_TIMEUNIT -9
vlib work
vmap work work

# fm_radio architecture
vlog -work work "../sv/fifo.sv"
vlog -work work "../sv/add.sv"
vlog -work work "../sv/add_top.sv"
vlog -work work "../sv/add_tb.sv"


vsim -voptargs=+acc +notimingchecks -L work work.add_tb -wlf add_tb.wlf

config wave -signalnamewidth 1

add wave -noupdate -group add_tb
add wave -noupdate -group add_tb -radix hexadecimal /add_tb/*

add wave -noupdate -group add_tb/add_top_inst
add wave -noupdate -group add_tb/add_top_inst -radix hexadecimal /add_tb/add_top_inst/*

add wave -noupdate -group add_tb/add_top_inst/add_inst
add wave -noupdate -group add_tb/add_top_inst/add_inst -radix hexadecimal /add_tb/add_top_inst/add_inst/*

add wave -noupdate -group add_tb/add_top_inst/fifo_lpr_in_inst
add wave -noupdate -group add_tb/add_top_inst/fifo_lpr_in_inst -radix hexadecimal /add_tb/add_top_inst/fifo_lpr_in_inst/*

add wave -noupdate -group add_tb/add_top_inst/fifo_lmr_in_inst
add wave -noupdate -group add_tb/add_top_inst/fifo_lmr_in_inst -radix hexadecimal /add_tb/add_top_inst/fifo_lmr_in_inst/*

add wave -noupdate -group add_tb/add_top_inst/fifo_out_inst
add wave -noupdate -group add_tb/add_top_inst/fifo_out_inst -radix hexadecimal /add_tb/add_top_inst/fifo_out_inst/*

run -all
#quit;