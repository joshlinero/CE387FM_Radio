setenv LMC_TIMEUNIT -9
vlib work
vmap work work

# fm_radio architecture
vlog -work work "../sv/fifo.sv"
vlog -work work "../sv/fir.sv"
vlog -work work "../sv/multiply.sv"
vlog -work work "../sv/stereo_pilot_mult_top.sv"
vlog -work work "../sv/stereo_pilot_mult_tb.sv"


vsim -voptargs=+acc +notimingchecks -L work work.stereo_pilot_mult_tb -wlf stereo_pilot_mult_tb.wlf

config wave -signalnamewidth 1

add wave -noupdate -group stereo_pilot_mult_tb
add wave -noupdate -group stereo_pilot_mult_tb -radix hexadecimal /stereo_pilot_mult_tb/*

add wave -noupdate -group stereo_pilot_mult_tb/spm_top_inst
add wave -noupdate -group stereo_pilot_mult_tb/spm_top_inst -radix hexadecimal /stereo_pilot_mult_tb/spm_top_inst/*

add wave -noupdate -group stereo_pilot_mult_tb/spm_top_inst/fir_spm_inst
add wave -noupdate -group stereo_pilot_mult_tb/spm_top_inst/fir_spm_inst -radix hexadecimal /stereo_pilot_mult_tb/spm_top_inst/fir_spm_inst/*

add wave -noupdate -group stereo_pilot_mult_tb/spm_top_inst/fifo_spm_fir_in_inst
add wave -noupdate -group stereo_pilot_mult_tb/spm_top_inst/fifo_spm_fir_in_inst -radix hexadecimal /stereo_pilot_mult_tb/spm_top_inst/fifo_spm_fir_in_inst/*

add wave -noupdate -group stereo_pilot_mult_tb/spm_top_inst/fifo_spm_fir_out_inst
add wave -noupdate -group stereo_pilot_mult_tb/spm_top_inst/fifo_spm_fir_out_inst -radix hexadecimal /stereo_pilot_mult_tb/spm_top_inst/fifo_spm_fir_out_inst/*

add wave -noupdate -group stereo_pilot_mult_tb/spm_top_inst/mult_spm_inst
add wave -noupdate -group stereo_pilot_mult_tb/spm_top_inst/mult_spm_inst -radix hexadecimal /stereo_pilot_mult_tb/spm_top_inst/mult_spm_inst/*

add wave -noupdate -group stereo_pilot_mult_tb/spm_top_inst/fifo_spm_mult_out_inst
add wave -noupdate -group stereo_pilot_mult_tb/spm_top_inst/fifo_spm_mult_out_inst -radix hexadecimal /stereo_pilot_mult_tb/spm_top_inst/fifo_spm_mult_out_inst/*


run -all
#quit;