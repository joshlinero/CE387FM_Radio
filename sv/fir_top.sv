module fir_top #(
    parameter TAPS = 32,
    parameter DECIMATION = 8,
    parameter DATA_SIZE = 32,
    parameter [0:TAPS-1][DATA_SIZE-1:0] GLOBAL_COEFF =
    '{
        (32'hfffffffd), (32'hfffffffa), (32'hfffffff4), (32'hffffffed), (32'hffffffe5), (32'hffffffdf), (32'hffffffe2), (32'hfffffff3), 
        (32'h00000015), (32'h0000004e), (32'h0000009b), (32'h000000f9), (32'h0000015d), (32'h000001be), (32'h0000020e), (32'h00000243), 
        (32'h00000243), (32'h0000020e), (32'h000001be), (32'h0000015d), (32'h000000f9), (32'h0000009b), (32'h0000004e), (32'h00000015), 
        (32'hfffffff3), (32'hffffffe2), (32'hffffffdf), (32'hffffffe5), (32'hffffffed), (32'hfffffff4), (32'hfffffffa), (32'hfffffffd)
    }
) (
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
fir #(
    .TAPS(TAPS),
    .DECIMATION(DECIMATION),
    .DATA_SIZE(DATA_SIZE),
    .GLOBAL_COEFF(GLOBAL_COEFF)
) fir_inst (
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