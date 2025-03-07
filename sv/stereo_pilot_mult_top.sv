module stereo_pilot_mult_top #(
    parameter TAPS = 32,
    parameter DECIMATION = 1,
    parameter DATA_SIZE = 32,
    parameter [0:TAPS-1][DATA_SIZE-1:0] GLOBAL_COEFF =
    '{
        (32'h0000000e), (32'h0000001f), (32'h00000034), (32'h00000048), (32'h0000004e), (32'h00000036), (32'hfffffff8), (32'hffffff98), 
        (32'hffffff2d), (32'hfffffeda), (32'hfffffec3), (32'hfffffefe), (32'hffffff8a), (32'h0000004a), (32'h0000010f), (32'h000001a1), 
        (32'h000001a1), (32'h0000010f), (32'h0000004a), (32'hffffff8a), (32'hfffffefe), (32'hfffffec3), (32'hfffffeda), (32'hffffff2d), 
        (32'hffffff98), (32'hfffffff8), (32'h00000036), (32'h0000004e), (32'h00000048), (32'h00000034), (32'h0000001f), (32'h0000000e)
    }
) (
    input   logic                   clock,
    input   logic                   reset,

    input   logic [DATA_SIZE-1:0]   spm_in_din,
    output  logic                   spm_in_full,
    input   logic                   spm_in_wr_en,
    
    output  logic [DATA_SIZE-1:0]   spm_out_dout,
    output  logic                   spm_out_empty,
    input   logic                   spm_out_rd_en
);


logic fir_in_rd_en;
logic fir_empty;
logic [DATA_SIZE-1:0] fir_din;

logic fir_out_wr_en;
logic fir_out_full;
logic [DATA_SIZE-1:0] fir_out_din;

logic fir_out_rd_en, fir_out_rd_en1, fir_out_rd_en2;
logic fir_out_empty;
logic [DATA_SIZE-1:0] fir_out_dout;

logic [DATA_SIZE-1:0] spm_mult_out;
logic spm_out_wr_en;
logic spm_out_full;

fifo #(
    .FIFO_DATA_WIDTH(DATA_SIZE),
    .FIFO_BUFFER_SIZE(16)
) fifo_spm_fir_in_inst (
    .reset(reset),
    .wr_clk(clock),
    .wr_en(spm_in_wr_en),
    .din(spm_in_din),
    .full(spm_in_full),
    .rd_clk(clock),
    .rd_en(fir_in_rd_en),
    .dout(fir_din),
    .empty(fir_empty)
);

fir #(
    .TAPS(TAPS),
    .DECIMATION(DECIMATION),
    .DATA_SIZE(DATA_SIZE),
    .GLOBAL_COEFF(GLOBAL_COEFF)
) fir_spm_inst (
    .clock(clock),
    .reset(reset),
    .x_in(fir_din),
    .x_rd_en(fir_in_rd_en),
    .x_empty(fir_empty),
    .y_out(fir_out_din),
    .y_out_full(fir_out_full),
    .y_wr_en(fir_out_wr_en)
);

fifo #(
    .FIFO_DATA_WIDTH(DATA_SIZE),
    .FIFO_BUFFER_SIZE(16)
) fifo_spm_fir_out_inst (
    .reset(reset),
    .wr_clk(clock),
    .wr_en(fir_out_wr_en),
    .din(fir_out_din),
    .full(fir_out_full),
    .rd_clk(clock),
    .rd_en(fir_out_rd_en),
    .dout(fir_out_dout),
    .empty(fir_out_empty)
);

assign fir_out_rd_en = fir_out_rd_en1 && fir_out_rd_en2;


multiply #(
    .DATA_SIZE(DATA_SIZE)
) mult_spm_inst(
    .clock(clock),
    .reset(reset),

    .x(fir_out_dout),
    .x_in_rd_en(fir_out_rd_en1),
    .x_in_empty(fir_out_empty),

    .y(fir_out_dout),
    .y_in_rd_en(fir_out_rd_en2),
    .y_in_empty(fir_out_empty),

    .mult_out(spm_mult_out),
    .out_wr_en(spm_out_wr_en),
    .out_full(spm_out_full)

);


fifo #(
    .FIFO_DATA_WIDTH(DATA_SIZE),
    .FIFO_BUFFER_SIZE(16)
) fifo_spm_mult_out_inst (
    .reset(reset),
    .wr_clk(clock),
    .wr_en(spm_out_wr_en),
    .din(spm_mult_out),
    .full(spm_out_full),
    .rd_clk(clock),
    .rd_en(spm_out_rd_en),
    .dout(spm_out_dout),
    .empty(spm_out_empty)
);





endmodule