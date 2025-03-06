module fir_complex_top #(
    parameter DATA_SIZE = 32,
    parameter TAPS = 20,
    parameter DECIMATION = 1
) (
    input   logic                   clock,
    input   logic                   reset,

    output  logic                   xreal_in_full,
    input   logic                   xreal_in_wr_en,
    input   logic [DATA_SIZE-1:0]   xreal_in_din,

    output  logic                   ximag_in_full,
    input   logic                   ximag_in_wr_en,
    input   logic [DATA_SIZE-1:0]   ximag_in_din,

    output  logic                   yreal_out_empty,
    input   logic                   yreal_out_rd_en,
    output  logic [DATA_SIZE-1:0]   yreal_out_dout,

    output  logic                   yimag_out_empty,
    input   logic                   yimag_out_rd_en,
    output  logic [DATA_SIZE-1:0]   yimag_out_dout
);


logic xreal_in_rd_en;
logic xreal_in_empty;
logic [DATA_SIZE-1:0] xreal_in_dout;

logic ximag_in_rd_en;
logic ximag_in_empty;
logic [DATA_SIZE-1:0] ximag_in_dout;

logic yreal_out_wr_en;
logic yreal_out_full;
logic [DATA_SIZE-1:0] yreal_out_din;

logic yimag_out_wr_en;
logic yimag_out_full;
logic [DATA_SIZE-1:0] yimag_out_din;


fifo #(
    .FIFO_DATA_WIDTH(DATA_SIZE),
    .FIFO_BUFFER_SIZE(16)
) fifo_xreal_in_inst (
    .reset(reset),
    .wr_clk(clock),
    .wr_en(xreal_in_wr_en),
    .din(xreal_in_din),
    .full(xreal_in_full),
    .rd_clk(clock),
    .rd_en(xreal_in_rd_en),
    .dout(xreal_in_dout),
    .empty(xreal_in_empty)
);

fifo #(
    .FIFO_DATA_WIDTH(DATA_SIZE),
    .FIFO_BUFFER_SIZE(16)
) fifo_ximag_in_inst (
    .reset(reset),
    .wr_clk(clock),
    .wr_en(ximag_in_wr_en),
    .din(ximag_in_din),
    .full(ximag_in_full),
    .rd_clk(clock),
    .rd_en(ximag_in_rd_en),
    .dout(ximag_in_dout),
    .empty(ximag_in_empty)
);



// fir module
fir_complex #(
    .TAPS(TAPS),
    .DECIMATION(DECIMATION),
    .DATA_SIZE(DATA_SIZE)
) fir_complex_inst (
    .clock(clock),
    .reset(reset),

    .i_in(xreal_in_dout),
    .fircmplx_i_empty(xreal_in_empty),
    .fircmplx_i_rd_en(xreal_in_rd_en),
    .q_in(ximag_in_dout),
    .fircmplx_q_empty(ximag_in_empty),
    .fircmplx_q_rd_en(ximag_in_rd_en),

    .real_wr_en_cmplx(yreal_out_wr_en),
    .real_full_cmplx(yreal_out_full),
    .out_real_cmplx(yreal_out_din),
    .imag_wr_en_cmplx(yimag_out_wr_en),
    .imag_full_cmplx(yimag_out_full),
    .out_imag_cmplx(yimag_out_din)
);

fifo #(
    .FIFO_DATA_WIDTH(DATA_SIZE),
    .FIFO_BUFFER_SIZE(16)
) fifo_yreal_out_inst (
    .reset(reset),
    .wr_clk(clock),
    .wr_en(yreal_out_wr_en),
    .din(yreal_out_din),
    .full(yreal_out_full),
    .rd_clk(clock),
    .rd_en(yreal_out_rd_en),
    .dout(yreal_out_dout),
    .empty(yreal_out_empty)
);

fifo #(
    .FIFO_DATA_WIDTH(DATA_SIZE),
    .FIFO_BUFFER_SIZE(16)
) fifo_yimag_out_inst (
    .reset(reset),
    .wr_clk(clock),
    .wr_en(yimag_out_wr_en),
    .din(yimag_out_din),
    .full(yimag_out_full),
    .rd_clk(clock),
    .rd_en(yimag_out_rd_en),
    .dout(yimag_out_dout),
    .empty(yimag_out_empty)
);

endmodule