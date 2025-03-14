import uvm_pkg::*;

interface  fm_radio_uvm_if;
    logic                    clock;
    logic                    reset;
    logic                    in_full;
    logic                    in_wr_en;
    logic [BYTE_SIZE-1:0]    in_din;
    logic                    left_audio_out_empty;
    logic                    right_audio_out_empty;
    logic                    left_audio_out_rd_en;
    logic                    right_audio_out_rd_en;
    logic [DATA_SIZE-1:0]    left_audio_out_data;
    logic [DATA_SIZE-1:0]    right_audio_out_data;
    logic signed [DATA_SIZE-1:0]  volume;
endinterface