module add_top #(
    parameter DATA_SIZE = 32

) (
    input   logic                   clock,
    input   logic                   reset,

    input   logic [DATA_SIZE-1:0]   add_lmr_in_din,
    output  logic                   add_lmr_in_full,
    input   logic                   add_lmr_in_wr_en,

    input   logic [DATA_SIZE-1:0]   add_lpr_in_din,
    output  logic                   add_lpr_in_full,
    input   logic                   add_lpr_in_wr_en,
    
    output  logic [DATA_SIZE-1:0]   add_out_dout,
    output  logic                   add_out_empty,
    input   logic                   add_out_rd_en
);


logic add_lmr_rd_en, add_lpr_rd_en;
logic add_lpr_empty, add_lmr_empty;
logic [DATA_SIZE-1:0] add_lpr_din, add_lmr_din;

logic add_out_wr_en;
logic add_out_full;
logic [DATA_SIZE-1:0] add_out;


fifo #(
    .FIFO_DATA_WIDTH(DATA_SIZE),
    .FIFO_BUFFER_SIZE(16)
) fifo_lpr_in_inst (
    .reset(reset),
    .wr_clk(clock),
    .wr_en(add_lpr_in_wr_en),
    .din(add_lpr_in_din),
    .full(add_lpr_in_full),
    .rd_clk(clock),
    .rd_en(add_lpr_rd_en),
    .dout(add_lpr_din),
    .empty(add_lpr_empty)
);

fifo #(
    .FIFO_DATA_WIDTH(DATA_SIZE),
    .FIFO_BUFFER_SIZE(16)
) fifo_lmr_in_inst (
    .reset(reset),
    .wr_clk(clock),
    .wr_en(add_lmr_in_wr_en),
    .din(add_lmr_in_din),
    .full(add_lmr_in_full),
    .rd_clk(clock),
    .rd_en(add_lmr_rd_en),
    .dout(add_lmr_din),
    .empty(add_lmr_empty)
);


add #(
    .DATA_SIZE(DATA_SIZE)
) add_inst(
    .clock(clock),
    .reset(reset),

    .lmr_in_dout(add_lmr_din),
    .lmr_in_empty(add_lmr_empty),
    .lmr_in_rd_en(add_lmr_rd_en),

    .lpr_in_dout(add_lpr_din),
    .lpr_in_empty(add_lpr_empty),
    .lpr_in_rd_en(add_lpr_rd_en),

    .add_out_din(add_out),
    .add_out_wr_en(add_out_wr_en),
    .add_out_full(add_out_full)

);


fifo #(
    .FIFO_DATA_WIDTH(DATA_SIZE),
    .FIFO_BUFFER_SIZE(16)
) fifo_out_inst (
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

endmodule