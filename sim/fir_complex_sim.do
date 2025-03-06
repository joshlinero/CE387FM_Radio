setenv LMC_TIMEUNIT -9
vlib work
vmap work work

# fm_radio architecture
vlog -work work "../sv/fifo.sv"
vlog -work work "../sv/fir_complex.sv"
vlog -work work "../sv/fir_complex_top.sv"
vlog -work work "../sv/fir_complex_tb.sv"


vsim -voptargs=+acc +notimingchecks -L work work.fir_complex_tb -wlf fir_complex_tb.wlf

add wave -noupdate -group fir_complex_tb
add wave -noupdate -group fir_complex_tb -radix hexadecimal /fir_complex_tb/*

add wave -noupdate -group fir_complex_tb/fir_complex_top_inst
add wave -noupdate -group fir_complex_tb/fir_complex_top_inst -radix hexadecimal /fir_complex_tb/fir_complex_top_inst/*

add wave -noupdate -group fir_complex_tb/fir_complex_top_inst/fir_complex_inst
add wave -noupdate -group fir_complex_tb/fir_complex_top_inst/fir_complex_inst -radix hexadecimal /fir_complex_tb/fir_complex_top_inst/fir_complex_inst/*

add wave -noupdate -group fir_complex_tb/fir_complex_top_inst/fifo_xreal_in_inst
add wave -noupdate -group fir_complex_tb/fir_complex_top_inst/fifo_xreal_in_inst -radix hexadecimal /fir_complex_tb/fir_complex_top_inst/fifo_xreal_in_inst/*

add wave -noupdate -group fir_complex_tb/fir_complex_top_inst/fifo_ximag_in_inst
add wave -noupdate -group fir_complex_tb/fir_complex_top_inst/fifo_ximag_in_inst -radix hexadecimal /fir_complex_tb/fir_complex_top_inst/fifo_ximag_in_inst/*

add wave -noupdate -group fir_complex_tb/fir_complex_top_inst/fifo_yreal_out_inst
add wave -noupdate -group fir_complex_tb/fir_complex_top_inst/fifo_yreal_out_inst -radix hexadecimal /fir_complex_tb/fir_complex_top_inst/fifo_yreal_out_inst/*

add wave -noupdate -group fir_complex_tb/fir_complex_top_inst/fifo_yimag_out_inst
add wave -noupdate -group fir_complex_tb/fir_complex_top_inst/fifo_yimag_out_inst -radix hexadecimal /fir_complex_tb/fir_complex_top_inst/fifo_yimag_out_inst/*

run -all
#quit;