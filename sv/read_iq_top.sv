
module read_iq_top #(
    parameter DATA_SIZE = 32,
    parameter BYTE_SIZE = 8,
    parameter CHAR_SIZE = 16,
    parameter BITS = 10
) (
    input  logic                    clock,
    input  logic                    reset,

    output logic                    in_full,
    
    input  logic                    in_wr_en,
    input  logic [BYTE_SIZE-1:0]    in_din,

    output logic                    i_out_empty,
    output logic                    q_out_empty,

    input  logic                    i_out_rd_en,
    input  logic                    q_out_rd_en,

    output  logic [DATA_SIZE-1:0]   i_out_data,
    output  logic [DATA_SIZE-1:0]   q_out_data
);

logic [BYTE_SIZE-1:0]  in_dout;

logic         in_rd_en;
logic         in_empty;

// Signals from read_iq to the output FIFOs:
logic         out_wr_en;
logic signed [DATA_SIZE-1:0] i_out;
logic signed [DATA_SIZE-1:0] q_out;

// Full flags from the output FIFOs fed back to read_iq:
logic         i_out_full;
logic         q_out_full;


fifo #(
    .FIFO_BUFFER_SIZE(256),
    .FIFO_DATA_WIDTH(BYTE_SIZE)
) fifo_in_inst (
    .reset(reset),
    .wr_clk(clock),
    .wr_en(in_wr_en),
    .din(in_din),
    .full(in_full),
    .rd_clk(clock),
    .rd_en(in_rd_en),
    .dout(in_dout),
    .empty(in_empty)
);

read_iq #(
    .DATA_SIZE(DATA_SIZE),
    .BYTE_SIZE(BYTE_SIZE),
    .CHAR_SIZE(CHAR_SIZE),
    .BITS(BITS)
) read_iq_inst (
    .clock(clock),
    .reset(reset),

    .data_in(in_dout),

    .i_out_full(i_out_full),
    .q_out_full(q_out_full),

    .in_empty(in_empty),

    .in_rd_en(in_rd_en),
    .out_wr_en(out_wr_en),

    .i_out(i_out),
    .q_out(q_out)
);


fifo #(
    .FIFO_BUFFER_SIZE(256),
    .FIFO_DATA_WIDTH(DATA_SIZE)
) fifo_out_i_inst (
    .reset(reset),
    .wr_clk(clock),
    .wr_en(out_wr_en),
    .din(i_out),
    .full(i_out_full),
    .rd_clk(clock),
    .rd_en(i_out_rd_en),
    .dout(i_out_data),
    .empty(i_out_empty)
);


fifo #(
    .FIFO_BUFFER_SIZE(256),
    .FIFO_DATA_WIDTH(DATA_SIZE)
) fifo_out_q_inst (
    .reset(reset),
    .wr_clk(clock),
    .wr_en(out_wr_en),
    .din(q_out),
    .full(q_out_full),
    .rd_clk(clock),
    .rd_en(q_out_rd_en),
    .dout(q_out_data),
    .empty(q_out_empty)
);
endmodule
