setenv LMC_TIMEUNIT -9
vlib work
vmap work work

# fm_radio architecture
vlog -work work "../sv/fifo.sv"
vlog -work work "../sv/sub.sv"
vlog -work work "../sv/sub_top.sv"
vlog -work work "../sv/sub_tb.sv"


vsim -voptargs=+acc +notimingchecks -L work work.sub_tb -wlf sub_tb.wlf

config wave -signalnamewidth 1

add wave -noupdate -group sub_tb
add wave -noupdate -group sub_tb -radix hexadecimal /sub_tb/*

add wave -noupdate -group sub_tb/sub_top_inst
add wave -noupdate -group sub_tb/sub_top_inst -radix hexadecimal /sub_tb/sub_top_inst/*

add wave -noupdate -group sub_tb/sub_top_inst/sub_inst
add wave -noupdate -group sub_tb/sub_top_inst/sub_inst -radix hexadecimal /sub_tb/sub_top_inst/sub_inst/*

add wave -noupdate -group sub_tb/sub_top_inst/fifo_lpr_in_inst
add wave -noupdate -group sub_tb/sub_top_inst/fifo_lpr_in_inst -radix hexadecimal /sub_tb/sub_top_inst/fifo_lpr_in_inst/*

add wave -noupdate -group sub_tb/sub_top_inst/fifo_lmr_in_inst
add wave -noupdate -group sub_tb/sub_top_inst/fifo_lmr_in_inst -radix hexadecimal /sub_tb/sub_top_inst/fifo_lmr_in_inst/*

add wave -noupdate -group sub_tb/sub_top_inst/fifo_out_inst
add wave -noupdate -group sub_tb/sub_top_inst/fifo_out_inst -radix hexadecimal /sub_tb/sub_top_inst/fifo_out_inst/*

run -all
#quit;