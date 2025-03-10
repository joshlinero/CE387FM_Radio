setenv LMC_TIMEUNIT -9
vlib work
vmap work work

# fm_radio architecture
vlog -work work "../sv/fifo.sv"
vlog -work work "../sv/read_iq.sv"
vlog -work work "../sv/read_iq_top.sv"
vlog -work work "../sv/read_iq_tb.sv"


vsim -voptargs=+acc +notimingchecks -L work work.read_iq_tb -wlf read_iq_tb.wlf

config wave -signalnamewidth 1

add wave -noupdate -group read_iq_tb
add wave -noupdate -group read_iq_tb -radix hexadecimal /read_iq_tb/*

add wave -noupdate -group read_iq_tb/read_iq_top_inst
add wave -noupdate -group read_iq_tb/read_iq_top_inst -radix hexadecimal /read_iq_tb/read_iq_top_inst/*

add wave -noupdate -group read_iq_tb/read_iq_top_inst/read_iq_inst
add wave -noupdate -group read_iq_tb/read_iq_top_inst/read_iq_inst -radix hexadecimal /read_iq_tb/read_iq_top_inst/read_iq_inst/*

add wave -noupdate -group read_iq_tb/read_iq_top_inst/fifo_in_inst
add wave -noupdate -group read_iq_tb/read_iq_top_inst/fifo_in_inst -radix hexadecimal /read_iq_tb/read_iq_top_inst/fifo_in_inst/*

add wave -noupdate -group read_iq_tb/read_iq_top_inst/fifo_out_i_inst
add wave -noupdate -group read_iq_tb/read_iq_top_inst/fifo_out_i_inst -radix hexadecimal /read_iq_tb/read_iq_top_inst/fifo_out_i_inst/*

add wave -noupdate -group read_iq_tb/read_iq_top_inst/fifo_out_q_inst
add wave -noupdate -group read_iq_tb/read_iq_top_inst/fifo_out_q_inst -radix hexadecimal /read_iq_tb/read_iq_top_inst/fifo_out_q_inst/*

run -all
#quit;