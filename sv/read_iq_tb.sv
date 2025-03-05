
`timescale 1 ns / 1 ns

module read_iq_tb;

localparam string FILE_IN_NAME = "../source/test/usrp.dat";
localparam string FILE_I_CMP_NAME = "../source/src/txt_files/read_iq_i_cmp.txt";
localparam string FILE_Q_CMP_NAME = "../source/src/txt_files/read_iq_q_cmp.txt";
localparam string FILE_I_OUT_NAME = "../source/src/out_files/read_iq_i_out.txt";
localparam string FILE_Q_OUT_NAME = "../source/src/out_files/read_iq_q_out.txt";

localparam CLOCK_PERIOD = 10;
localparam DATA_SIZE = 32;

logic clock = 1'b1;
logic reset = '0;
logic start = '0;
logic done  = '0;

logic out_read_done = '0;
logic in_write_done = '0;
integer out_errors = '0;

// CHANGE THIS PARAMETER TO CHANGE NUMBER TEST INPUT DATA IN
localparam NUMBER_OF_INPUTS = 32000;

logic i_out_empty, q_out_empty;
logic i_out_rd_en, q_out_rd_en;
logic signed [DATA_SIZE-1:0] i_out_data, q_out_data;

logic in_full;
logic in_wr_en;
logic signed [7:0] data_in;

read_iq_top #(
    .DATA_SIZE(DATA_SIZE),
    .BYTE_SIZE(8),
    .CHAR_SIZE(16),
    .BITS(10)
) read_iq_top_inst (
    .clock(clock),
    .reset(reset),
    .in_full(in_full),
    .in_wr_en(in_wr_en),
    .in_din(data_in),
    .i_out_empty(i_out_empty),
    .q_out_empty(q_out_empty),
    .i_out_rd_en(i_out_rd_en),
    .q_out_rd_en(q_out_rd_en),
    .i_out_data(i_out_data),
    .q_out_data(q_out_data)
);

always begin
    #(CLOCK_PERIOD/2) clock = ~clock;
end

initial begin
    @(posedge clock);
    reset = 1'b1;
    @(posedge clock);
    reset = 1'b0;
end

initial begin : tb_process
    longint unsigned start_time, end_time;
    @(negedge reset);
    @(posedge clock);
    start_time = $time;
    $display("@ %0t: Beginning simulation...", start_time);
    start = 1'b1;
    @(posedge clock);
    start = 1'b0;
    wait(out_read_done);
    end_time = $time;
    $display("@ %0t: Simulation completed.", end_time);
    $display("Total simulation cycle count: %0d", (end_time-start_time)/CLOCK_PERIOD);
    $display("Inputs read in: %0d", NUMBER_OF_INPUTS);
    $display("Outputs out: %0d", NUMBER_OF_INPUTS/32);
    $display("Total error count: %0d", out_errors);
    $finish;
end

initial begin : read_data_process
    int in_file;
    int i;
    @(negedge reset);
    $display("@ %0t: Loading file %s...", $time, FILE_IN_NAME);
    in_file = $fopen(FILE_IN_NAME, "rb");
    if (!in_file) $fatal("@ %0t: FAILED TO LOAD FILE %s...", $time, FILE_IN_NAME);
    in_wr_en = 1'b0;
    @(negedge clock);
    i = 0;
    while (i < NUMBER_OF_INPUTS) begin
        @(negedge clock);
        if (!in_full) begin
            in_wr_en = 1'b1;
            void'($fscanf(in_file, "%c", data_in));
            i++;
        end else in_wr_en = 1'b0;
    end
    @(negedge clock);
    in_wr_en = 1'b0;
    $fclose(in_file);
    in_write_done = 1'b1;
end

initial begin : data_write_process
    logic signed [DATA_SIZE-1:0] i_cmp_out, q_cmp_out;
    int i, j, k;
    int i_out_file, q_out_file;
    int i_cmp_file, q_cmp_file;
    @(negedge reset);
    @(negedge clock);
    $display("@ %0t: Comparing I %s...", $time, FILE_I_OUT_NAME);
    $display("@ %0t: Comparing Q %s...", $time, FILE_Q_OUT_NAME);
    i_out_file = $fopen(FILE_I_OUT_NAME, "wb");
    q_out_file = $fopen(FILE_Q_OUT_NAME, "wb");
    i_cmp_file = $fopen(FILE_I_CMP_NAME, "rb");
    q_cmp_file = $fopen(FILE_Q_CMP_NAME, "rb");
    i_out_rd_en = 1'b0;
    q_out_rd_en = 1'b0;
    i = 0;
    while (i < NUMBER_OF_INPUTS/32) begin
        @(negedge clock);
        i_out_rd_en = 1'b0;
        q_out_rd_en = 1'b0;
        if (!i_out_empty && !q_out_empty) begin
            i_out_rd_en = 1'b1;
            q_out_rd_en = 1'b1;
            j = $fscanf(i_cmp_file, "%08x", i_cmp_out);
            k = $fscanf(q_cmp_file, "%08x", q_cmp_out);
            $fwrite(i_out_file, "%08x\n", i_out_data);
            $fwrite(q_out_file, "%08x\n", q_out_data);
            if (i_cmp_out != i_out_data) begin
                out_errors++;
                $display("@ %0t: (%0d): I ERROR: %x != %x.", $time, i+1, i_out_data, i_cmp_out);
            end 
            if (q_cmp_out != q_out_data) begin
                out_errors++;
                $display("@ %0t: (%0d): Q ERROR: %x != %x.", $time, i+1, q_out_data, q_cmp_out);
            end 
            i++;
        end
    end
    @(negedge clock);
    i_out_rd_en = 1'b0;
    q_out_rd_en = 1'b0;
    $display("@ %0t: Closing I_OUT %s...", $time, FILE_I_OUT_NAME);
    $display("@ %0t: Closing Q_OUT %s...", $time, FILE_Q_OUT_NAME);
    $fclose(i_out_file);
    $fclose(q_out_file);
    $fclose(i_cmp_file);
    $fclose(q_cmp_file);
    out_read_done = 1'b1;
end

endmodule
