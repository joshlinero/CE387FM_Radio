module fm_radio_top #(
    parameter DATA_SIZE = 32,
    parameter BYTE_SIZE = 8
) (
    input  logic                    clock,
    input  logic                    reset,

    output logic                    in_full,
    input  logic                    in_wr_en,
    input  logic [BYTE_SIZE-1:0]    in_din,

    output logic                    left_audio_out_empty,
    output logic                    right_audio_out_empty,

    input  logic                    left_audio_out_rd_en,
    input  logic                    right_audio_out_rd_en,

    output  logic [DATA_SIZE-1:0]   left_audio_out_data,
    output  logic [DATA_SIZE-1:0]   right_audio_out_data,

    input logic signed [DATA_SIZE-1:0]  volume
);

logic [BYTE_SIZE-1:0]  read_iq_in_dout;

logic         read_iq_in_rd_en;
logic         read_iq_in_empty;
logic         read_iq_out_wr_en;
logic signed [DATA_SIZE-1:0] i_out;
logic signed [DATA_SIZE-1:0] q_out;

logic         i_out_full;
logic         q_out_full;

logic i_out_rd_en, q_out_rd_en;
logic q_out_empty, i_out_empty;
logic signed [DATA_SIZE-1:0] q_out_data. i_out_data;





//input
fifo #(
    .FIFO_BUFFER_SIZE(16),
    .FIFO_DATA_WIDTH(BYTE_SIZE)
) fifo_in_inst (
    .reset(reset),
    .wr_clk(clock),
    .wr_en(in_wr_en),
    .din(in_din),
    .full(in_full),
    .rd_clk(clock),
    .rd_en(read_iq_in_rd_en),
    .dout(read_iq_in_dout),
    .empty(read_iq_in_empty)
);


// read_iq
read_iq #(
    .DATA_SIZE(DATA_SIZE),
    .BYTE_SIZE(BYTE_SIZE),
    .CHAR_SIZE(16),
    .BITS(10)
) read_iq_inst (
    .clock(clock),
    .reset(reset),
    .data_in(read_iq_in_dout),
    .i_out_full(i_out_full),
    .q_out_full(q_out_full),
    .in_empty(read_iq_in_empty),
    .in_rd_en(read_iq_in_rd_en),
    .out_wr_en(read_iq_out_wr_en),
    .i_out(i_out),
    .q_out(q_out)
);


fifo #(
    .FIFO_BUFFER_SIZE(16),
    .FIFO_DATA_WIDTH(DATA_SIZE)
) fifo_out_i_inst (
    .reset(reset),
    .wr_clk(clock),
    .wr_en(read_iq_out_wr_en),
    .din(i_out),
    .full(i_out_full),
    .rd_clk(clock),
    .rd_en(i_out_rd_en),
    .dout(i_out_data),
    .empty(i_out_empty)
);


fifo #(
    .FIFO_BUFFER_SIZE(16),
    .FIFO_DATA_WIDTH(DATA_SIZE)
) fifo_out_q_inst (
    .reset(reset),
    .wr_clk(clock),
    .wr_en(read_iq_out_wr_en),
    .din(q_out),
    .full(q_out_full),
    .rd_clk(clock),
    .rd_en(q_out_rd_en),
    .dout(q_out_data),
    .empty(q_out_empty)
);

logic fir_cmplx_real_out_wr_en;
logic fir_cmplx_real_out_full;
logic [DATA_SIZE-1:0] fir_cmplx_real_out_din;

logic fir_cmplx_imag_out_wr_en;
logic fir_cmplx_imag_out_full;
logic [DATA_SIZE-1:0] fir_cmplx_imag_out_din;


logic                   fir_cmplx_real_out_empty,
logic                   fir_cmplx_real_out_rd_en,
logic [DATA_SIZE-1:0]   fir_cmplx_real_out_dout,

logic                   fir_cmplx_imag_out_empty,
logic                   fir_cmplx_imag_out_rd_en,
logic [DATA_SIZE-1:0]   fir_cmplx_imag_out_dout

//fir_complex
fir_complex #(
    .TAPS(20),
    .DECIMATION(1),
    .DATA_SIZE(DATA_SIZE)
) fir_complex_inst (
    .clock(clock),
    .reset(reset),

    .i_in(i_out_data),
    .fircmplx_i_empty(i_out_empty),
    .fircmplx_i_rd_en(i_out_rd_en),
    .q_in(q_out_data),
    .fircmplx_q_empty(q_out_empty),
    .fircmplx_q_rd_en(q_out_rd_en),

    .real_wr_en_cmplx(fir_cmplx_real_out_wr_en),
    .real_full_cmplx(fir_cmplx_real_out_full),
    .out_real_cmplx(fir_cmplx_real_out_din),
    .imag_wr_en_cmplx(fir_cmplx_imag_out_wr_en),
    .imag_full_cmplx(fir_cmplx_imag_out_full),
    .out_imag_cmplx(fir_cmplx_imag_out_din)
);

fifo #(
    .FIFO_DATA_WIDTH(DATA_SIZE),
    .FIFO_BUFFER_SIZE(16)
) fifo_fir_cmplx_real_out_inst (
    .reset(reset),
    .wr_clk(clock),
    .wr_en(fir_cmplx_real_out_wr_en),
    .din(fir_cmplx_real_out_din),
    .full(fir_cmplx_real_out_full),
    .rd_clk(clock),
    .rd_en(fir_cmplx_real_out_rd_en),
    .dout(fir_cmplx_real_out_dout),
    .empty(fir_cmplx_real_out_empty)
);

fifo #(
    .FIFO_DATA_WIDTH(DATA_SIZE),
    .FIFO_BUFFER_SIZE(16)
) fifo_fir_cmplx_imag_out_inst (
    .reset(reset),
    .wr_clk(clock),
    .wr_en(fir_cmplx_imag_out_wr_en),
    .din(fir_cmplx_imag_out_din),
    .full(fir_cmplx_imag_out_full),
    .rd_clk(clock),
    .rd_en(fir_cmplx_imag_out_rd_en),
    .dout(fir_cmplx_imag_out_dout),
    .empty(fir_cmplx_imag_out_empty)
);



logic [DATA_SIZE-1:0] demod_out;
logic demod_wr_en_out;
logic demod_out_full;

logic [DATA_SIZE-1:0] demod_data_out;
logic demod_out_rd_en;
logic demod_out_empty;

//demodulation

demodulate #(
    .DATA_SIZE(DATA_SIZE)
) demodulate_inst (
    .clock(clock),
    .reset(reset),
    .real_demod_rd_en(fir_cmplx_real_out_rd_en),
    .real_empty(fir_cmplx_real_out_empty),
    .real_din(fir_cmplx_real_out_dout),
    .imag_demod_rd_en(fir_cmplx_imag_out_rd_en),
    .imag_empty(fir_cmplx_imag_out_empty),
    .imag_din(fir_cmplx_imag_out_dout),
    .demod_out(demod_out),
    .demod_wr_en_out(demod_wr_en_out),
    .demod_out_full(demod_out_full)
);

fifo #(
    .FIFO_DATA_WIDTH(DATA_SIZE),
    .FIFO_BUFFER_SIZE(16)
) fifo_demodulate_output (
    .reset(reset),
    .wr_clk(clock),
    .wr_en(demod_wr_en_out),
    .din(demod_out),
    .full(demod_out_full),
    .rd_clk(clock),
    .rd_en(demod_out_rd_en),
    .dout(demod_data_out),
    .empty(demod_out_empty)
);



parameter  AUDIO_LPR_COEFF_TAPS = 32;

parameter logic signed [0:AUDIO_LPR_COEFF_TAPS-1] [DATA_SIZE-1:0] AUDIO_LPR_COEFFS = '{
    32'hfffffffd, 32'hfffffffa, 32'hfffffff4, 32'hffffffed, 32'hffffffe5, 32'hffffffdf, 32'hffffffe2, 32'hfffffff3, 
    32'h00000015, 32'h0000004e, 32'h0000009b, 32'h000000f9, 32'h0000015d, 32'h000001be, 32'h0000020e, 32'h00000243, 
    32'h00000243, 32'h0000020e, 32'h000001be, 32'h0000015d, 32'h000000f9, 32'h0000009b, 32'h0000004e, 32'h00000015, 
    32'hfffffff3, 32'hffffffe2, 32'hffffffdf, 32'hffffffe5, 32'hffffffed, 32'hfffffff4, 32'hfffffffa, 32'hfffffffd
};


logic [DATA_SIZE-1:0] fir_lpr_out_din;
logic fir_lpr_out_wr_en;
logic fir_lpr_out_full;

logic [DATA_SIZE-1:0] lpr_out_dout;
logic lpr_out_rd_en;
logic lpr_out_empty;

// L+R low-pass FIR filter
fir #(
    .TAPS(AUDIO_LPR_COEFF_TAPS),
    .DECIMATION(8),
    .DATA_SIZE(DATA_SIZE),
    .GLOBAL_COEFF(AUDIO_LPR_COEFFS)
) fir_lpr_inst (
    .clock(clock),
    .reset(reset),
    .x_in(demod_data_out),
    .x_rd_en(demod_out_rd_en),
    .x_empty(demod_out_empty),
    .y_out(fir_lpr_out_din),
    .y_out_full(fir_lpr_out_full),
    .y_wr_en(fir_lpr_out_wr_en)
);

fifo #(
    .FIFO_DATA_WIDTH(DATA_SIZE),
    .FIFO_BUFFER_SIZE(16)
) fifo_lpr_out_inst (
    .reset(reset),
    .wr_clk(clock),
    .wr_en(fir_lpr_out_wr_en),
    .din(fir_lpr_out_din),
    .full(fir_lpr_out_full),
    .rd_clk(clock),
    .rd_en(lpr_out_rd_en),
    .dout(lpr_out_dout),
    .empty(lpr_out_empty)
);




parameter BP_LMR_COEFF_TAPS = 32;

parameter logic signed [0:BP_LMR_COEFF_TAPS-1] [DATA_SIZE-1:0] BP_LMR_COEFFS = '{
    32'h00000000, 32'h00000000, 32'hfffffffc, 32'hfffffff9, 32'hfffffffe, 32'h00000008, 32'h0000000c, 32'h00000002, 
    32'h00000003, 32'h0000001e, 32'h00000030, 32'hfffffffc, 32'hffffff8c, 32'hffffff58, 32'hffffffc3, 32'h0000008a, 
    32'h0000008a, 32'hffffffc3, 32'hffffff58, 32'hffffff8c, 32'hfffffffc, 32'h00000030, 32'h0000001e, 32'h00000003, 
    32'h00000002, 32'h0000000c, 32'h00000008, 32'hfffffffe, 32'hfffffff9, 32'hfffffffc, 32'h00000000, 32'h00000000
};


logic [DATA_SIZE-1:0] fir_bp_lmr_out_din;
logic fir_bp_lmr_out_wr_en;
logic fir_bp_lmr_out_full;

logic [DATA_SIZE-1:0] fir_lmr_out_dout;
logic fir_lmr_out_rd_en;
logic fir_lmr_out_empty;

//  L-R band-pass FIR filter 
fir #(
    .TAPS(BP_LMR_COEFF_TAPS),
    .DECIMATION(8),
    .DATA_SIZE(DATA_SIZE),
    .GLOBAL_COEFF(BP_LMR_COEFFS)
) fir_bp_lmr_inst (
    .clock(clock),
    .reset(reset),
    .x_in(demod_data_out),
    .x_rd_en(demod_out_rd_en),
    .x_empty(demod_out_empty),
    .y_out(fir_bp_lmr_out_din),
    .y_out_full(fir_bp_lmr_out_full),
    .y_wr_en(fir_bp_lmr_out_wr_en)
);

fifo #(
    .FIFO_DATA_WIDTH(DATA_SIZE),
    .FIFO_BUFFER_SIZE(16)
) fifo_bp_lmr_out_inst (
    .reset(reset),
    .wr_clk(clock),
    .wr_en(fir_bp_lmr_out_wr_en),
    .din(fir_bp_lmr_out_din),
    .full(fir_bp_lmr_out_full),
    .rd_clk(clock),
    .rd_en(fir_lmr_out_rd_en),
    .dout(fir_lmr_out_dout),
    .empty(fir_lmr_out_empty)
);



parameter BP_PILOT_COEFF_TAPS = 32;

parameter logic signed [0:BP_PILOT_COEFF_TAPS-1] [DATA_SIZE-1:0] BP_PILOT_COEFFS = '{
    32'h0000000e, 32'h0000001f, 32'h00000034, 32'h00000048, 32'h0000004e, 32'h00000036, 32'hfffffff8, 32'hffffff98, 
    32'hffffff2d, 32'hfffffeda, 32'hfffffec3, 32'hfffffefe, 32'hffffff8a, 32'h0000004a, 32'h0000010f, 32'h000001a1, 
    32'h000001a1, 32'h0000010f, 32'h0000004a, 32'hffffff8a, 32'hfffffefe, 32'hfffffec3, 32'hfffffeda, 32'hffffff2d, 
    32'hffffff98, 32'hfffffff8, 32'h00000036, 32'h0000004e, 32'h00000048, 32'h00000034, 32'h0000001f, 32'h0000000e
};


logic [DATA_SIZE-1:0] fir_pilot_bp_out_din;
logic fir_pilot_bp_out_wr_en;
logic fir_pilot_bp_out_full;

logic [DATA_SIZE-1:0] fir_pilot_bp_out_dout;
logic fir_pilot_bp_out_rd_en1, fir_pilot_bp_out_rd_en2, fir_pilot_bp_out_rd_en;
logic fir_pilot_bp_out_empty;

logic [DATA_SIZE-1:0] mult_pilot_bp_out;
logic mult_pilot_bp_out_wr_en;
logic mult_pilot_bp_out_full;

logic [DATA_SIZE-1:0] mult_pilot_out_dout;
logic mult_pilot_out_rd_en;
logic mult_pilot_out_empty;

// Pilot band-pass filter extracts the 19kHz pilot tone
fir #(
    .TAPS(BP_PILOT_COEFF_TAPS),
    .DECIMATION(1),
    .DATA_SIZE(DATA_SIZE),
    .GLOBAL_COEFF(BP_PILOT_COEFFS)
) fir_pilot_bp_inst (
    .clock(clock),
    .reset(reset),
    .x_in(demod_data_out),
    .x_rd_en(demod_out_rd_en),
    .x_empty(demod_out_empty),
    .y_out(fir_pilot_bp_out_din),
    .y_out_full(fir_pilot_bp_out_full),
    .y_wr_en(fir_pilot_bp_out_wr_en)
);

fifo #(
    .FIFO_DATA_WIDTH(DATA_SIZE),
    .FIFO_BUFFER_SIZE(16)
) fifo_pilot_bp_out_inst (
    .reset(reset),
    .wr_clk(clock),
    .wr_en(fir_pilot_bp_out_wr_en),
    .din(fir_pilot_bp_out_din),
    .full(fir_pilot_bp_out_full),
    .rd_clk(clock),
    .rd_en(fir_pilot_bp_out_rd_en),
    .dout(fir_pilot_bp_out_dout),
    .empty(fir_pilot_bp_out_empty)
);

assign fir_pilot_bp_out_rd_en = fir_pilot_bp_out_rd_en1 && fir_pilot_bp_out_rd_en2;

// square the pilot tone to get 38kHz
multiply #(
    .DATA_SIZE(DATA_SIZE)
) mult_pilot_bp_inst(
    .clock(clock),
    .reset(reset),

    .x(fir_pilot_bp_out_dout),
    .x_in_rd_en(fir_pilot_bp_out_rd_en1),
    .x_in_empty(fir_pilot_bp_out_empty),

    .y(fir_pilot_bp_out_dout),
    .y_in_rd_en(fir_pilot_bp_out_rd_en2),
    .y_in_empty(fir_pilot_bp_out_empty),

    .mult_out(mult_pilot_bp_out),
    .out_wr_en(mult_pilot_bp_out_wr_en),
    .out_full(mult_pilot_bp_out_full)

);


fifo #(
    .FIFO_DATA_WIDTH(DATA_SIZE),
    .FIFO_BUFFER_SIZE(16)
) fifo_mult_pilot_bp_out_inst (
    .reset(reset),
    .wr_clk(clock),
    .wr_en(mult_pilot_bp_out_wr_en),
    .din(mult_pilot_bp_out),
    .full(mult_pilot_bp_out_full),
    .rd_clk(clock),
    .rd_en(mult_pilot_out_rd_en),
    .dout(mult_pilot_out_dout),
    .empty(mult_pilot_out_empty)
);



parameter HP_COEFF_TAPS = 32;

parameter logic signed [0:HP_COEFF_TAPS-1] [DATA_SIZE-1:0] HP_COEFFS = '{
    32'hffffffff, 32'h00000000, 32'h00000000, 32'h00000002, 32'h00000004, 32'h00000008, 32'h0000000b, 32'h0000000c, 
    32'h00000008, 32'hffffffff, 32'hffffffee, 32'hffffffd7, 32'hffffffbb, 32'hffffff9f, 32'hffffff87, 32'hffffff76, 
    32'hffffff76, 32'hffffff87, 32'hffffff9f, 32'hffffffbb, 32'hffffffd7, 32'hffffffee, 32'hffffffff, 32'h00000008, 
    32'h0000000c, 32'h0000000b, 32'h00000008, 32'h00000004, 32'h00000002, 32'h00000000, 32'h00000000, 32'hffffffff
};

logic [DATA_SIZE-1:0] fir_pilot_hp_out_din;
logic fir_pilot_hp_out_wr_en;
logic fir_pilot_hp_out_full;

logic [DATA_SIZE-1:0] pilot_out_dout;
logic pilot_out_rd_en;
logic pilot_out_empty;

// high-pass filter removes the tone at 0Hz created after the pilot tone is squared
fir #(
    .TAPS(HP_COEFF_TAPS),
    .DECIMATION(1),
    .DATA_SIZE(DATA_SIZE),
    .GLOBAL_COEFF(HP_COEFFS)
) fir_pilot_hp_inst (
    .clock(clock),
    .reset(reset),
    .x_in(mult_pilot_out_dout),
    .x_rd_en(mult_pilot_out_rd_en),
    .x_empty(mult_pilot_out_empty),
    .y_out(fir_pilot_hp_out_din),
    .y_out_full(fir_pilot_hp_out_full),
    .y_wr_en(fir_pilot_hp_out_wr_en)
);


fifo #(
    .FIFO_DATA_WIDTH(DATA_SIZE),
    .FIFO_BUFFER_SIZE(16)
) fifo_pilot_hp_out_inst (
    .reset(reset),
    .wr_clk(clock),
    .wr_en(fir_pilot_hp_out_wr_en),
    .din(fir_pilot_hp_out_din),
    .full(fir_pilot_hp_out_full),
    .rd_clk(clock),
    .rd_en(pilot_out_rd_en),
    .dout(pilot_out_dout),
    .empty(pilot_out_empty)
);


logic [DATA_SIZE-1:0] mult_pilot_lmr_out;
logic mult_pilot_lmr_out_wr_en;
logic mult_pilot_lmr_out_full;


logic [DATA_SIZE-1:0] mult_pilot_lmr_out_dout;
logic mult_pilot_lmr_out_rd_en;
logic mult_pilot_lmr_out_empty;


// demodulate the L-R channel from 38kHz to baseband
multiply #(
    .DATA_SIZE(DATA_SIZE)
) mult_pilot_lmr_inst(
    .clock(clock),
    .reset(reset),

    .x(pilot_out_dout),
    .x_in_rd_en(pilot_out_rd_en),
    .x_in_empty(pilot_out_empty),

    .y(fir_lmr_out_dout),
    .y_in_rd_en(fir_lmr_out_rd_en),
    .y_in_empty(fir_lmr_out_empty),

    .mult_out(mult_pilot_lmr_out),
    .out_wr_en(mult_pilot_lmr_out_wr_en),
    .out_full(mult_pilot_lmr_out_full)

);

fifo #(
    .FIFO_DATA_WIDTH(DATA_SIZE),
    .FIFO_BUFFER_SIZE(16)
) fifo_pilot_hp_out_inst (
    .reset(reset),
    .wr_clk(clock),
    .wr_en(mult_pilot_lmr_out_wr_en),
    .din(mult_pilot_lmr_out),
    .full(mult_pilot_lmr_out_full),
    .rd_clk(clock),
    .rd_en(mult_pilot_lmr_out_rd_en),
    .dout(mult_pilot_lmr_out_dout),
    .empty(mult_pilot_lmr_out_empty)
);


parameter AUDIO_LMR_COEFF_TAPS = 32;

parameter logic signed [0:AUDIO_LMR_COEFF_TAPS-1] [DATA_SIZE-1:0] AUDIO_LMR_COEFFS = '{
    32'hfffffffd, 32'hfffffffa, 32'hfffffff4, 32'hffffffed, 32'hffffffe5, 32'hffffffdf, 32'hffffffe2, 32'hfffffff3, 
    32'h00000015, 32'h0000004e, 32'h0000009b, 32'h000000f9, 32'h0000015d, 32'h000001be, 32'h0000020e, 32'h00000243, 
    32'h00000243, 32'h0000020e, 32'h000001be, 32'h0000015d, 32'h000000f9, 32'h0000009b, 32'h0000004e, 32'h00000015, 
    32'hfffffff3, 32'hffffffe2, 32'hffffffdf, 32'hffffffe5, 32'hffffffed, 32'hfffffff4, 32'hfffffffa, 32'hfffffffd
};


logic [DATA_SIZE-1:0] fir_lmr_out_wr_en;
logic fir_lmr_out_wr_en;
logic fir_lmr_out_full;

logic [DATA_SIZE-1:0] lmr_out_dout;
logic lmr_out_rd_en;
logic lmr_out_empty;



// L-R low-pass FIR filter - reduce sampling rate from 256 KHz to 32 KHz
fir #(
    .TAPS(AUDIO_LMR_COEFF_TAPS),
    .DECIMATION(8),
    .DATA_SIZE(DATA_SIZE),
    .GLOBAL_COEFF(AUDIO_LMR_COEFFS)
) fir_lmr_inst (
    .clock(clock),
    .reset(reset),
    .x_in(mult_pilot_lmr_out_dout),
    .x_rd_en(mult_pilot_lmr_out_rd_en),
    .x_empty(mult_pilot_lmr_out_empty),
    .y_out(fir_lmr_out_din),
    .y_out_full(fir_lmr_out_full),
    .y_wr_en(fir_lmr_out_wr_en)
);


fifo #(
    .FIFO_DATA_WIDTH(DATA_SIZE),
    .FIFO_BUFFER_SIZE(16)
) fifo_lmr_out_inst (
    .reset(reset),
    .wr_clk(clock),
    .wr_en(fir_lmr_out_wr_en),
    .din(fir_lmr_out_din),
    .full(fir_lmr_out_full),
    .rd_clk(clock),
    .rd_en(lmr_out_rd_en),
    .dout(lmr_out_dout),
    .empty(lmr_out_empty)
);


logic [DATA_SIZE-1:0] add_out;
logic add_out_wr_en;
logic add_out_full;


logic [DATA_SIZE-1:0] add_out_dout;
logic add_out_rd_en;
logic add_out_empty;

// Left audio channel - (L+R) + (L-R) = 2L 
add #(
    .DATA_SIZE(DATA_SIZE)
) add_inst(
    .clock(clock),
    .reset(reset),

    .lmr_in_dout(lmr_out_dout),
    .lmr_in_empty(lmr_out_empty),
    .lmr_in_rd_en(lmr_out_rd_en),

    .lpr_in_dout(lpr_out_dout),
    .lpr_in_empty(lpr_out_empty),
    .lpr_in_rd_en(lpr_out_rd_en),

    .add_out_din(add_out),
    .add_out_wr_en(add_out_wr_en),
    .add_out_full(add_out_full)

);


fifo #(
    .FIFO_DATA_WIDTH(DATA_SIZE),
    .FIFO_BUFFER_SIZE(16)
) fifo_add_out_inst (
    .reset(reset),
    .wr_clk(clock),
    .wr_en(add_out_wr_en),
    .din(add_out),
    .full(add_out_full),
    .rd_clk(clock),
    .rd_en(add_out_rd_en),
    .dout(add_out_dout),
    .empty(add_out_empty)
);


logic [DATA_SIZE-1:0] sub_out;
logic sub_out_wr_en;
logic sub_out_full;


logic [DATA_SIZE-1:0] sub_out_dout;
logic sub_out_rd_en;
logic sub_out_empty;

// Right audio channel - (L+R) - (L-R) = 2R
sub #(
    .DATA_SIZE(DATA_SIZE)
) sub_inst(
    .clock(clock),
    .reset(reset),

    .lmr_in_dout(lmr_out_dout),
    .lmr_in_empty(lmr_out_empty),
    .lmr_in_rd_en(lmr_out_rd_en),

    .lpr_in_dout(lpr_out_dout),
    .lpr_in_empty(lpr_out_empty),
    .lpr_in_rd_en(lpr_out_rd_en),

    .sub_out_din(sub_out),
    .sub_out_wr_en(sub_out_wr_en),
    .sub_out_full(sub_out_full)

);


fifo #(
    .FIFO_DATA_WIDTH(DATA_SIZE),
    .FIFO_BUFFER_SIZE(16)
) fifo_sub_out_inst (
    .reset(reset),
    .wr_clk(clock),
    .wr_en(sub_out_wr_en),
    .din(sub_out),
    .full(sub_out_full),
    .rd_clk(clock),
    .rd_en(sub_out_rd_en),
    .dout(sub_out_dout),
    .empty(sub_out_empty)
);





parameter IIR_COEFF_TAPS = 2;
parameter logic signed [0:IIR_COEFF_TAPS-1] [DATA_SIZE-1:0] X_COEFFS = '{32'h000000b2, 32'h000000b2};
parameter logic signed [0:IIR_COEFF_TAPS-1] [DATA_SIZE-1:0] Y_COEFFS = '{32'h00000000, 32'hfffffd66};

logic [DATA_SIZE-1:0] iir_left_out_din;
logic iir_left_out_wr_en;
logic iir_left_out_full;


logic [DATA_SIZE-1:0] iir_left_out_dout;
logic iir_left_out_rd_en;
logic iir_left_out_empty;

// Left channel deemphasis
iir #(
    .TAPS(IIR_COEFF_TAPS),
    .DECIMATION(1),
    .DATA_SIZE(DATA_SIZE),
    .X_COEFFS(X_COEFFS),
    .Y_COEFFS(Y_COEFFS)
) iir_left_inst (
    .clock(clock),
    .reset(reset),
    .x_in(add_out_dout),
    .x_rd_en(add_out_rd_en),
    .x_empty(add_out_empty),
    .y_out(iir_left_out_din),
    .y_out_full(iir_left_out_full),
    .y_wr_en(iir_left_out_wr_en)
);

fifo #(
    .FIFO_DATA_WIDTH(DATA_SIZE),
    .FIFO_BUFFER_SIZE(16)
) fifo_iir_left_out_inst (
    .reset(reset),
    .wr_clk(clock),
    .wr_en(iir_left_out_wr_en),
    .din(iir_left_out_din),
    .full(iir_left_out_full),
    .rd_clk(clock),
    .rd_en(iir_left_out_rd_en),
    .dout(iir_left_out_dout),
    .empty(iir_left_out_empty)
);


logic [DATA_SIZE-1:0] iir_right_out_din;
logic iir_right_out_wr_en;
logic iir_right_out_full;

logic [DATA_SIZE-1:0] iir_right_out_dout;
logic iir_right_out_rd_en;
logic iir_right_out_empty;

// Right channel deemphasis
iir #(
    .TAPS(IIR_COEFF_TAPS),
    .DECIMATION(1),
    .DATA_SIZE(DATA_SIZE),
    .X_COEFFS(X_COEFFS),
    .Y_COEFFS(Y_COEFFS)
) iir_right_inst (
    .clock(clock),
    .reset(reset),
    .x_in(sub_out_dout),
    .x_rd_en(sub_out_rd_en),
    .x_empty(sub_out_empty),
    .y_out(iir_right_out_din),
    .y_out_full(iir_right_out_full),
    .y_wr_en(iir_right_out_wr_en)
);

fifo #(
    .FIFO_DATA_WIDTH(DATA_SIZE),
    .FIFO_BUFFER_SIZE(16)
) fifo_iir_right_out_inst (
    .reset(reset),
    .wr_clk(clock),
    .wr_en(iir_right_out_wr_en),
    .din(iir_right_out_din),
    .full(iir_right_out_full),
    .rd_clk(clock),
    .rd_en(iir_right_out_rd_en),
    .dout(iir_right_out_dout),
    .empty(iir_right_out_empty)
);

//logic signed [DATA_SIZE - 1:0] volume;

logic [DATA_SIZE-1:0] left_gain_out_din;
logic left_gain_out_wr_en;
logic left_gain_out_full;

logic [DATA_SIZE-1:0] right_gain_out_din;
logic right_gain_out_wr_en;
logic right_gain_out_full;



// Left volume control
gain #(
    .DATA_SIZE(DATA_SIZE)
) gain_left_inst (
    .clock(clock),
    .reset(reset),
    .volume(volume),
    .in(iir_left_out_dout),
    .in_rd_en(iir_left_out_rd_en),
    .in_empty(iir_left_out_empty),
    .gain_out(left_gain_out_din),
    .out_full(left_gain_out_full),
    .out_wr_en(left_gain_out_wr_en)
);

// Right volume control
gain #(
    .DATA_SIZE(DATA_SIZE)
) gain_right_inst (
    .clock(clock),
    .reset(reset),
    .volume(volume),
    .in(iir_right_out_dout),
    .in_rd_en(iir_right_out_rd_en),
    .in_empty(iir_right_out_empty),
    .gain_out(right_gain_out_din),
    .out_full(right_gain_out_full),
    .out_wr_en(right_gain_out_wr_en)
);

//output data
fifo #(
    .FIFO_DATA_WIDTH(DATA_SIZE),
    .FIFO_BUFFER_SIZE(16)
) fifo_left_out_audio_inst (
    .reset(reset),
    .wr_clk(clock),
    .wr_en(left_gain_out_wr_en),
    .din(left_gain_out_din),
    .full(left_gain_out_full),
    .rd_clk(clock),
    .rd_en(left_audio_out_rd_en),
    .dout(left_audio_out_data),
    .empty(left_audio_out_empty)
);

fifo #(
    .FIFO_DATA_WIDTH(DATA_SIZE),
    .FIFO_BUFFER_SIZE(16)
) fifo_right_out_audio_inst (
    .reset(reset),
    .wr_clk(clock),
    .wr_en(right_gain_out_wr_en),
    .din(right_gain_out_din),
    .full(right_gain_out_full),
    .rd_clk(clock),
    .rd_en(right_audio_out_rd_en),
    .dout(right_audio_out_data),
    .empty(right_audio_out_empty)
);

endmodule
