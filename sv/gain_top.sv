module gain_top #(
    parameter DATA_SIZE = 32
) (
    input   logic                   clock,
    input   logic                   reset,

    input   logic                   volume,

    input   logic [DATA_SIZE-1:0]   x_in_din,
    output  logic                   x_in_full,
    input   logic                   x_in_wr_en,
    
    output  logic [DATA_SIZE-1:0]   y_out_dout,
    output  logic                   y_out_empty,
    input   logic                   y_out_rd_en
);

logic gain_in_rd_en;
logic gain_in_empty;
logic [DATA_SIZE-1:0] gain_in_dout;

logic gain_out_wr_en;
logic gain_out_full;
logic [DATA_SIZE-1:0] gain_out_din;

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
    .rd_en(gain_in_rd_en),
    .dout(gain_in_dout),
    .empty(gain_in_empty)
);

// gain module
gain #(
    .DATA_SIZE(DATA_SIZE)
) gain_inst (
    .clock(clock),
    .reset(reset),
    .volume(volume),
    .in(gain_in_dout),
    .in_rd_en(gain_in_rd_en),
    .in_empty(gain_in_empty),
    .gain_out(gain_out_din),
    .out_full(gain_out_full),
    .out_wr_en(gain_out_wr_en)
);

fifo #(
    .FIFO_DATA_WIDTH(DATA_SIZE),
    .FIFO_BUFFER_SIZE(16)
) fifo_y_out_inst (
    .reset(reset),
    .wr_clk(clock),
    .wr_en(gain_out_wr_en),
    .din(gain_out_din),
    .full(gain_out_full),
    .rd_clk(clock),
    .rd_en(y_out_rd_en),
    .dout(y_out_dout),
    .empty(y_out_empty)
);

endmodule