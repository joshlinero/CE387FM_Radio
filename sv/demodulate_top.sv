
module demodulate_top #(
    parameter DATA_SIZE = 32
) (
    input   logic                   clock,
    input   logic                   reset,
    
    input   logic [DATA_SIZE-1:0]   real_in,
    input   logic                   real_wr_en,
    output  logic                   real_full,

    input   logic [DATA_SIZE-1:0]   imag_in,
    input   logic                   imag_wr_en,
    output  logic                   imag_full,

    output  logic [DATA_SIZE-1:0]   data_out,
    input   logic                   data_out_rd_en,
    output  logic                   data_out_empty
);

// Wires from FIFOs to demod
logic real_demod_rd_en;
logic real_empty;
logic [DATA_SIZE-1:0] real_dout;

logic imag_demod_rd_en;
logic imag_empty;
logic [DATA_SIZE-1:0] imag_dout;

logic [DATA_SIZE-1:0] demod_out;
logic demod_wr_en_out;
logic demod_out_full;

fifo #(
    .FIFO_DATA_WIDTH(DATA_SIZE),
    .FIFO_BUFFER_SIZE(16)
) real_input_fifo (
    .reset(reset),
    .wr_clk(clock),
    .wr_en(real_wr_en),
    .din(real_in),
    .full(real_full),
    .rd_clk(clock),
    .rd_en(real_demod_rd_en),
    .dout(real_dout),
    .empty(real_empty)
);

fifo #(
    .FIFO_DATA_WIDTH(DATA_SIZE),
    .FIFO_BUFFER_SIZE(16)
) imag_input_fifo (
    .reset(reset),
    .wr_clk(clock),
    .wr_en(imag_wr_en),
    .din(imag_in),
    .full(imag_full),
    .rd_clk(clock),
    .rd_en(imag_demod_rd_en),
    .dout(imag_dout),
    .empty(imag_empty)
);


demodulate #(
    .DATA_SIZE(DATA_SIZE)
) demodulate_inst (
    .clock(clock),
    .reset(reset),
    .real_demod_rd_en(real_demod_rd_en),
    .real_empty(real_empty),
    .real_din(real_dout),
    .imag_demod_rd_en(imag_demod_rd_en),
    .imag_empty(imag_empty),
    .imag_din(imag_dout),
    .demod_out(demod_out),
    .demod_wr_en_out(demod_wr_en_out),
    .demod_out_full(demod_out_full)
);

fifo #(
    .FIFO_DATA_WIDTH(DATA_SIZE),
    .FIFO_BUFFER_SIZE(16)
) output_fifo (
    .reset(reset),
    .wr_clk(clock),
    .wr_en(demod_wr_en_out),
    .din(demod_out),
    .full(demod_out_full),
    .rd_clk(clock),
    .rd_en(data_out_rd_en),
    .dout(data_out),
    .empty(data_out_empty)
);

    
endmodule