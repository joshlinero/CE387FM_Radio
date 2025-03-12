setenv LMC_TIMEUNIT -9
vlib work
vmap work work

# fm_radio architecture
vlog -work work "../sv/fifo.sv"
vlog -work work "../sv/divider_work.sv"
vlog -work work "../sv/qarctan.sv"
vlog -work work "../sv/demodulate.sv"
vlog -work work "../sv/add.sv"
vlog -work work "../sv/fir_complex.sv"
vlog -work work "../sv/fir.sv"
vlog -work work "../sv/gain.sv"
vlog -work work "../sv/iir.sv"
vlog -work work "../sv/multiply.sv"
vlog -work work "../sv/read_iq.sv"
vlog -work work "../sv/sub.sv"
vlog -work work "../sv/fm_radio_top.sv"
vlog -work work "../sv/fm_radio_tb.sv"


vsim -voptargs=+acc +notimingchecks -L work work.fm_radio_tb -wlf fm_radio_tb.wlf

config wave -signalnamewidth 1

add wave -noupdate -group fm_radio_tb
add wave -noupdate -group fm_radio_tb -radix hexadecimal /fm_radio_tb/*

add wave -noupdate -group fm_radio_tb/fm_radio_top_inst
add wave -noupdate -group fm_radio_tb/fm_radio_top_inst -radix hexadecimal /fm_radio_tb/fm_radio_top_inst/*

add wave -noupdate -group fm_radio_tb/fm_radio_top_inst/demodulate_inst
add wave -noupdate -group fm_radio_tb/fm_radio_top_inst/demodulate_inst -radix hexadecimal /fm_radio_tb/fm_radio_top_inst/demodulate_inst/*

add wave -noupdate -group fm_radio_tb/fm_radio_top_inst/read_iq_inst
add wave -noupdate -group fm_radio_tb/fm_radio_top_inst/read_iq_inst -radix hexadecimal /fm_radio_tb/fm_radio_top_inst/read_iq_inst/*

add wave -noupdate -group fm_radio_tb/fm_radio_top_inst/fifo_in_inst
add wave -noupdate -group fm_radio_tb/fm_radio_top_inst/fifo_in_inst -radix hexadecimal /fm_radio_tb/fm_radio_top_inst/fifo_in_inst/*

add wave -noupdate -group fm_radio_tb/fm_radio_top_inst/fifo_out_i_inst
add wave -noupdate -group fm_radio_tb/fm_radio_top_inst/fifo_out_i_inst -radix hexadecimal /fm_radio_tb/fm_radio_top_inst/fifo_out_i_inst/*

add wave -noupdate -group fm_radio_tb/fm_radio_top_inst/fifo_out_q_inst
add wave -noupdate -group fm_radio_tb/fm_radio_top_inst/fifo_out_q_inst -radix hexadecimal /fm_radio_tb/fm_radio_top_inst/fifo_out_q_inst/*

add wave -noupdate -group fm_radio_tb/fm_radio_top_inst/fir_complex_inst
add wave -noupdate -group fm_radio_tb/fm_radio_top_inst/fir_complex_inst -radix hexadecimal /fm_radio_tb/fm_radio_top_inst/fir_complex_inst/*

add wave -noupdate -group fm_radio_tb/fm_radio_top_inst/fifo_fir_cmplx_real_out_inst
add wave -noupdate -group fm_radio_tb/fm_radio_top_inst/fifo_fir_cmplx_real_out_inst -radix hexadecimal /fm_radio_tb/fm_radio_top_inst/fifo_fir_cmplx_real_out_inst/*

add wave -noupdate -group fm_radio_tb/fm_radio_top_inst/fifo_fir_cmplx_imag_out_inst
add wave -noupdate -group fm_radio_tb/fm_radio_top_inst/fifo_fir_cmplx_imag_out_inst -radix hexadecimal /fm_radio_tb/fm_radio_top_inst/fifo_fir_cmplx_imag_out_inst/*

add wave -noupdate -group fm_radio_tb/fm_radio_top_inst/fifo_demodulate_output
add wave -noupdate -group fm_radio_tb/fm_radio_top_inst/fifo_demodulate_output -radix hexadecimal /fm_radio_tb/fm_radio_top_inst/fifo_demodulate_output/*

add wave -noupdate -group fm_radio_tb/fm_radio_top_inst/fir_lpr_inst
add wave -noupdate -group fm_radio_tb/fm_radio_top_inst/fir_lpr_inst -radix hexadecimal /fm_radio_tb/fm_radio_top_inst/fir_lpr_inst/*

add wave -noupdate -group fm_radio_tb/fm_radio_top_inst/fifo_lpr_out_inst
add wave -noupdate -group fm_radio_tb/fm_radio_top_inst/fifo_lpr_out_inst -radix hexadecimal /fm_radio_tb/fm_radio_top_inst/fifo_lpr_out_inst/*

add wave -noupdate -group fm_radio_tb/fm_radio_top_inst/fir_bp_lmr_inst
add wave -noupdate -group fm_radio_tb/fm_radio_top_inst/fir_bp_lmr_inst -radix hexadecimal /fm_radio_tb/fm_radio_top_inst/fir_bp_lmr_inst/*

add wave -noupdate -group fm_radio_tb/fm_radio_top_inst/fifo_bp_lmr_out_inst
add wave -noupdate -group fm_radio_tb/fm_radio_top_inst/fifo_bp_lmr_out_inst -radix hexadecimal /fm_radio_tb/fm_radio_top_inst/fifo_bp_lmr_out_inst/*

add wave -noupdate -group fm_radio_tb/fm_radio_top_inst/fir_pilot_bp_inst
add wave -noupdate -group fm_radio_tb/fm_radio_top_inst/fir_pilot_bp_inst -radix hexadecimal /fm_radio_tb/fm_radio_top_inst/fir_pilot_bp_inst/*

add wave -noupdate -group fm_radio_tb/fm_radio_top_inst/fifo_pilot_bp_out_inst
add wave -noupdate -group fm_radio_tb/fm_radio_top_inst/fifo_pilot_bp_out_inst -radix hexadecimal /fm_radio_tb/fm_radio_top_inst/fifo_pilot_bp_out_inst/*

add wave -noupdate -group fm_radio_tb/fm_radio_top_inst/mult_pilot_bp_inst
add wave -noupdate -group fm_radio_tb/fm_radio_top_inst/mult_pilot_bp_inst -radix hexadecimal /fm_radio_tb/fm_radio_top_inst/mult_pilot_bp_inst/*

add wave -noupdate -group fm_radio_tb/fm_radio_top_inst/fifo_mult_pilot_bp_out_inst
add wave -noupdate -group fm_radio_tb/fm_radio_top_inst/fifo_mult_pilot_bp_out_inst -radix hexadecimal /fm_radio_tb/fm_radio_top_inst/fifo_mult_pilot_bp_out_inst/*

add wave -noupdate -group fm_radio_tb/fm_radio_top_inst/fir_pilot_hp_inst
add wave -noupdate -group fm_radio_tb/fm_radio_top_inst/fir_pilot_hp_inst -radix hexadecimal /fm_radio_tb/fm_radio_top_inst/fir_pilot_hp_inst/*

add wave -noupdate -group fm_radio_tb/fm_radio_top_inst/fifo_pilot_hp_out_inst
add wave -noupdate -group fm_radio_tb/fm_radio_top_inst/fifo_pilot_hp_out_inst -radix hexadecimal /fm_radio_tb/fm_radio_top_inst/fifo_pilot_hp_out_inst/*

add wave -noupdate -group fm_radio_tb/fm_radio_top_inst/mult_pilot_lmr_inst
add wave -noupdate -group fm_radio_tb/fm_radio_top_inst/mult_pilot_lmr_inst -radix hexadecimal /fm_radio_tb/fm_radio_top_inst/mult_pilot_lmr_inst/*

add wave -noupdate -group fm_radio_tb/fm_radio_top_inst/fifo_pilot_hp_out_inst
add wave -noupdate -group fm_radio_tb/fm_radio_top_inst/fifo_pilot_hp_out_inst -radix hexadecimal /fm_radio_tb/fm_radio_top_inst/fifo_pilot_hp_out_inst/*

add wave -noupdate -group fm_radio_tb/fm_radio_top_inst/fir_lmr_inst
add wave -noupdate -group fm_radio_tb/fm_radio_top_inst/fir_lmr_inst -radix hexadecimal /fm_radio_tb/fm_radio_top_inst/fir_lmr_inst/*

add wave -noupdate -group fm_radio_tb/fm_radio_top_inst/fifo_lmr_out_inst
add wave -noupdate -group fm_radio_tb/fm_radio_top_inst/fifo_lmr_out_inst -radix hexadecimal /fm_radio_tb/fm_radio_top_inst/fifo_lmr_out_inst/*

add wave -noupdate -group fm_radio_tb/fm_radio_top_inst/add_inst
add wave -noupdate -group fm_radio_tb/fm_radio_top_inst/add_inst -radix hexadecimal /fm_radio_tb/fm_radio_top_inst/add_inst/*

add wave -noupdate -group fm_radio_tb/fm_radio_top_inst/fifo_add_out_inst
add wave -noupdate -group fm_radio_tb/fm_radio_top_inst/fifo_add_out_inst -radix hexadecimal /fm_radio_tb/fm_radio_top_inst/fifo_add_out_inst/*

add wave -noupdate -group fm_radio_tb/fm_radio_top_inst/sub_inst
add wave -noupdate -group fm_radio_tb/fm_radio_top_inst/sub_inst -radix hexadecimal /fm_radio_tb/fm_radio_top_inst/sub_inst/*

add wave -noupdate -group fm_radio_tb/fm_radio_top_inst/fifo_sub_out_inst
add wave -noupdate -group fm_radio_tb/fm_radio_top_inst/fifo_sub_out_inst -radix hexadecimal /fm_radio_tb/fm_radio_top_inst/fifo_sub_out_inst/*

add wave -noupdate -group fm_radio_tb/fm_radio_top_inst/iir_left_inst
add wave -noupdate -group fm_radio_tb/fm_radio_top_inst/iir_left_inst -radix hexadecimal /fm_radio_tb/fm_radio_top_inst/iir_left_inst/*

add wave -noupdate -group fm_radio_tb/fm_radio_top_inst/fifo_iir_left_out_inst
add wave -noupdate -group fm_radio_tb/fm_radio_top_inst/fifo_iir_left_out_inst -radix hexadecimal /fm_radio_tb/fm_radio_top_inst/fifo_iir_left_out_inst/*

add wave -noupdate -group fm_radio_tb/fm_radio_top_inst/iir_right_inst
add wave -noupdate -group fm_radio_tb/fm_radio_top_inst/iir_right_inst -radix hexadecimal /fm_radio_tb/fm_radio_top_inst/iir_right_inst/*

add wave -noupdate -group fm_radio_tb/fm_radio_top_inst/fifo_iir_right_out_inst
add wave -noupdate -group fm_radio_tb/fm_radio_top_inst/fifo_iir_right_out_inst -radix hexadecimal /fm_radio_tb/fm_radio_top_inst/fifo_iir_right_out_inst/*

add wave -noupdate -group fm_radio_tb/fm_radio_top_inst/gain_left_inst
add wave -noupdate -group fm_radio_tb/fm_radio_top_inst/gain_left_inst -radix hexadecimal /fm_radio_tb/fm_radio_top_inst/gain_left_inst/*

add wave -noupdate -group fm_radio_tb/fm_radio_top_inst/gain_right_inst
add wave -noupdate -group fm_radio_tb/fm_radio_top_inst/gain_right_inst -radix hexadecimal /fm_radio_tb/fm_radio_top_inst/gain_right_inst/*

add wave -noupdate -group fm_radio_tb/fm_radio_top_inst/fifo_left_out_audio_inst
add wave -noupdate -group fm_radio_tb/fm_radio_top_inst/fifo_left_out_audio_inst -radix hexadecimal /fm_radio_tb/fm_radio_top_inst/fifo_left_out_audio_inst/*

add wave -noupdate -group fm_radio_tb/fm_radio_top_inst/fifo_right_out_audio_inst
add wave -noupdate -group fm_radio_tb/fm_radio_top_inst/fifo_right_out_audio_inst -radix hexadecimal /fm_radio_tb/fm_radio_top_inst/fifo_right_out_audio_inst/*


run -all
#quit;