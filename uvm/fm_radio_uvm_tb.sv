
import uvm_pkg::*;
import fm_radio_uvm_package::*;

`include "fm_radio_uvm_if.sv"

`timescale 1 ns / 1 ns

module fm_radio_uvm_tb;

    fm_radio_uvm_if vif();

    fm_radio_top #(
        .DATA_SIZE(DATA_SIZE),
        .BYTE_SIZE(BYTE_SIZE)
    ) fm_radio_top_inst (
        .clock(vif.clock),
        .reset(vif.reset),
        .in_full(vif.in_full),
        .in_wr_en(vif.in_wr_en),
        .in_din(vif.data_in),
        .left_audio_out_empty(vif.left_audio_out_empty),
        .right_audio_out_empty(vif.right_audio_out_empty),
        .left_audio_out_rd_en(vif.left_audio_out_rd_en),
        .right_audio_out_rd_en(vif.right_audio_out_rd_en),
        .left_audio_out_data(vif.left_audio_out_data),
        .right_audio_out_data(vif.right_audio_out_data),
        .volume(vif.volume)
    );
    vif.volume = VOLUME;

    initial begin
        // store the vif so it can be retrieved by the driver & monitor
        uvm_resource_db#(virtual fm_radio_uvm_if)::set
            (.scope("ifs"), .name("vif"), .val(vif));

        // run the test
        run_test("fm_radio_uvm_test");        
    end

    // reset
    initial begin
        vif.clock <= 1'b1;
        vif.reset <= 1'b0;
        @(posedge vif.clock);
        vif.reset <= 1'b1;
        @(posedge vif.clock);
        vif.reset <= 1'b0;
    end

    // 10ns clock
    always
        #(CLOCK_PERIOD/2) vif.clock = ~vif.clock;
endmodule




