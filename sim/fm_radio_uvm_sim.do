setenv LMC_TIMEUNIT -9
vlib work
vmap work work

# udp architecture
vlog -work work "../sv/fifo.sv"
vlog -work work "../sv/add.sv"
vlog -work work "../sv/divider_work.sv"
vlog -work work "../sv/qarctan.sv"
vlog -work work "../sv/demodulate.sv"
vlog -work work "../sv/fir.sv"
vlog -work work "../sv/fir_complex.sv"
vlog -work work "../sv/gain.sv"
vlog -work work "../sv/iir.sv"
vlog -work work "../sv/multiply.sv"
vlog -work work "../sv/read_iq.sv"
vlog -work work "../sv/sub.sv"
vlog -work work "../sv/fm_radio_top.sv"

# uvm library
vlog -work work +incdir+$env(UVM_HOME)/src $env(UVM_HOME)/src/uvm.sv
vlog -work work +incdir+$env(UVM_HOME)/src $env(UVM_HOME)/src/uvm_macros.svh
vlog -work work +incdir+$env(UVM_HOME)/src $env(MTI_HOME)/verilog_src/questa_uvm_pkg-1.2/src/questa_uvm_pkg.sv

# uvm package
vlog -work work +incdir+$env(UVM_HOME)/src "../uvm/fm_radio_uvm_pkg.sv"
vlog -work work +incdir+$env(UVM_HOME)/src "../uvm/fm_radio_uvm_tb.sv"

# start uvm simulation
vsim -classdebug -voptargs=+acc +notimingchecks -L work work.fm_radio_uvm_tb -wlf fm_radio_uvm_tb.wlf -sv_lib lib/uvm_dpi -dpicpppath /usr/bin/gcc +incdir+$env(MTI_HOME)/verilog_src/questa_uvm_pkg-1.2/src/

do fm_radio_uvm_wave.do

run -all