module sub_top #(
    parameter DATA_SIZE = 32

) (
    input   logic                   clock,
    input   logic                   reset,

    input   logic [DATA_SIZE-1:0]   sub_lmr_in_din,
    output  logic                   sub_lmr_in_full,
    input   logic                   sub_lmr_in_wr_en,

    input   logic [DATA_SIZE-1:0]   sub_lpr_in_din,
    output  logic                   sub_lpr_in_full,
    input   logic                   sub_lpr_in_wr_en,
    
    output  logic [DATA_SIZE-1:0]   sub_out_dout,
    output  logic                   sub_out_empty,
    input   logic                   sub_out_rd_en
);


logic sub_lmr_rd_en, sub_lpr_rd_en;
logic sub_lpr_empty, sub_lmr_empty;
logic [DATA_SIZE-1:0] sub_lpr_din, sub_lmr_din;

logic sub_out_wr_en;
logic sub_out_full;
logic [DATA_SIZE-1:0] sub_out;


fifo #(
    .FIFO_DATA_WIDTH(DATA_SIZE),
    .FIFO_BUFFER_SIZE(16)
) fifo_lpr_in_inst (
    .reset(reset),
    .wr_clk(clock),
    .wr_en(sub_lpr_in_wr_en),
    .din(sub_lpr_in_din),
    .full(sub_lpr_in_full),
    .rd_clk(clock),
    .rd_en(sub_lpr_rd_en),
    .dout(sub_lpr_din),
    .empty(sub_lpr_empty)
);

fifo #(
    .FIFO_DATA_WIDTH(DATA_SIZE),
    .FIFO_BUFFER_SIZE(16)
) fifo_lmr_in_inst (
    .reset(reset),
    .wr_clk(clock),
    .wr_en(sub_lmr_in_wr_en),
    .din(sub_lmr_in_din),
    .full(sub_lmr_in_full),
    .rd_clk(clock),
    .rd_en(sub_lmr_rd_en),
    .dout(sub_lmr_din),
    .empty(sub_lmr_empty)
);


sub #(
    .DATA_SIZE(DATA_SIZE)
) sub_inst(
    .clock(clock),
    .reset(reset),

    .lmr_in_dout(sub_lmr_din),
    .lmr_in_empty(sub_lmr_empty),
    .lmr_in_rd_en(sub_lmr_rd_en),

    .lpr_in_dout(sub_lpr_din),
    .lpr_in_empty(sub_lpr_empty),
    .lpr_in_rd_en(sub_lpr_rd_en),

    .sub_out_din(sub_out),
    .sub_out_wr_en(sub_out_wr_en),
    .sub_out_full(sub_out_full)

);


fifo #(
    .FIFO_DATA_WIDTH(DATA_SIZE),
    .FIFO_BUFFER_SIZE(16)
) fifo_out_inst (
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

endmodule