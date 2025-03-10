module iir_top #(
    parameter TAPS = 2,
    parameter DECIMATION = 1,
    parameter DATA_SIZE = 32,
    parameter [0:TAPS-1][DATA_SIZE-1:0] X_COEFFS = 
    '{
        (32'h000000B2), (32'h000000B2)
    },
    parameter [0:TAPS-1][DATA_SIZE-1:0] Y_COEFFS = 
    '{
        (32'h00000000), (32'hFFFFFD66)
    }
)(
    input   logic                   clock,
    input   logic                   reset,

    input   logic [DATA_SIZE-1:0]   x_in_din,
    output  logic                   x_in_full,
    input   logic                   x_in_wr_en,
    
    output  logic [DATA_SIZE-1:0]   y_out_dout,
    output  logic                   y_out_empty,
    input   logic                   y_out_rd_en
);


logic x_in_rd_en;
logic x_in_empty;
logic [DATA_SIZE-1:0] x_in_dout;

logic y_out_wr_en;
logic y_out_full;
logic [DATA_SIZE-1:0] y_out_din;

fifo #(
    .FIFO_DATA_WIDTH(DATA_SIZE),
    .FIFO_BUFFER_SIZE(16)
) fifo_x_in_inst (
    .reset(reset),
    .wr_clk(clock),
    .wr_en(x_in_wr_en),
    .din(x_in_din),
    .full(x_in_full),
    .rd_clk(clock),
    .rd_en(x_in_rd_en),
    .dout(x_in_dout),
    .empty(x_in_empty)
);

// fir module
iir #(
    .TAPS(TAPS),
    .DECIMATION(DECIMATION),
    .DATA_SIZE(DATA_SIZE),
    .X_COEFFS(X_COEFFS),
    .Y_COEFFS(Y_COEFFS)
) iir_inst (
    .clock(clock),
    .reset(reset),
    .x_in(x_in_dout),
    .x_rd_en(x_in_rd_en),
    .x_empty(x_in_empty),
    .y_out(y_out_din),
    .y_out_full(y_out_full),
    .y_wr_en(y_out_wr_en)
);

fifo #(
    .FIFO_DATA_WIDTH(DATA_SIZE),
    .FIFO_BUFFER_SIZE(16)
) fifo_y_out_inst (
    .reset(reset),
    .wr_clk(clock),
    .wr_en(y_out_wr_en),
    .din(y_out_din),
    .full(y_out_full),
    .rd_clk(clock),
    .rd_en(y_out_rd_en),
    .dout(y_out_dout),
    .empty(y_out_empty)
);

endmodule