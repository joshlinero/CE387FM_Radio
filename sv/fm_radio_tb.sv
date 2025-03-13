
`timescale 1 ns / 1 ns

module fm_radio_tb;

localparam string FILE_IN_NAME = "../source/test/usrp.dat";
localparam string FILE_LEFT_CMP_NAME = "../source/src/txt_files/left_audio.txt";
localparam string FILE_RIGHT_CMP_NAME = "../source/src/txt_files/right_audio.txt";
localparam string FILE_LEFT_OUT_NAME = "../source/src/out_files/left_audio_out.txt";
localparam string FILE_RIGHT_OUT_NAME = "../source/src/out_files/right_audio_out.txt";

localparam CLOCK_PERIOD = 10;
localparam DATA_SIZE = 32;

logic clock = 1'b1;
logic reset = '0;
logic start = '0;
logic done  = '0;

logic out_read_done = '0;
logic in_write_done = '0;
integer out_errors = '0;

function logic signed [DATA_SIZE-1:0] QUANTIZE(logic signed [DATA_SIZE-1:0] val);
    QUANTIZE = DATA_SIZE'(val << 10);
endfunction

logic signed [DATA_SIZE-1:0] volume = QUANTIZE(1);

// CHANGE THIS PARAMETER TO CHANGE NUMBER TEST INPUT DATA IN
localparam NUMBER_OF_INPUTS = 32000;

logic left_audio_out_empty, right_audio_out_empty;
logic left_audio_out_rd_en, right_audio_out_rd_en;
logic signed [DATA_SIZE-1:0] left_audio_out_data, right_audio_out_data;

logic in_full;
logic in_wr_en;
logic signed [7:0] data_in;

fm_radio_top #(
    .DATA_SIZE(DATA_SIZE),
    .BYTE_SIZE(8)
) fm_radio_top_inst (
    .clock(clock),
    .reset(reset),
    .in_full(in_full),
    .in_wr_en(in_wr_en),
    .in_din(data_in),
    .left_audio_out_empty(left_audio_out_empty),
    .right_audio_out_empty(right_audio_out_empty),
    .left_audio_out_rd_en(left_audio_out_rd_en),
    .right_audio_out_rd_en(right_audio_out_rd_en),
    .left_audio_out_data(left_audio_out_data),
    .right_audio_out_data(right_audio_out_data),
    .volume(volume)
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
    logic signed [DATA_SIZE-1:0] left_cmp_out, right_cmp_out;
    int i, j, k;
    int left_out_file, right_out_file;
    int left_cmp_file, right_cmp_file;
    @(negedge reset);
    @(negedge clock);
    $display("@ %0t: Comparing Left %s...", $time, FILE_LEFT_OUT_NAME);
    $display("@ %0t: Comparing Right %s...", $time, FILE_RIGHT_OUT_NAME);
    left_out_file = $fopen(FILE_LEFT_OUT_NAME, "wb");
    right_out_file = $fopen(FILE_RIGHT_OUT_NAME, "wb");
    left_cmp_file = $fopen(FILE_LEFT_CMP_NAME, "rb");
    right_cmp_file = $fopen(FILE_RIGHT_CMP_NAME, "rb");
    left_audio_out_rd_en = 1'b0;
    right_audio_out_rd_en = 1'b0;
    i = 0;
    while (i < NUMBER_OF_INPUTS/32) begin
        @(negedge clock);
        left_audio_out_rd_en = 1'b0;
        right_audio_out_rd_en = 1'b0;
        if (!left_audio_out_empty && !right_audio_out_empty) begin
            left_audio_out_rd_en = 1'b1;
            right_audio_out_rd_en = 1'b1;
            j = $fscanf(left_cmp_file, "%08x", left_cmp_out);
            k = $fscanf(right_cmp_file, "%08x", right_cmp_out);
            $fwrite(left_out_file, "%08x\n", left_audio_out_data);
            $fwrite(right_out_file, "%08x\n", right_audio_out_data);
            if (left_cmp_out != left_audio_out_data) begin
                out_errors++;
                $display("@ %0t: (%0d): Left ERROR: %x != %x.", $time, i+1, left_audio_out_data, left_cmp_out);
            end 
            if (right_cmp_out != right_audio_out_data) begin
                out_errors++;
                $display("@ %0t: (%0d): Right ERROR: %x != %x.", $time, i+1, right_audio_out_data, right_cmp_out);
            end 
            i++;
        end
    end
    @(negedge clock);
    left_audio_out_rd_en = 1'b0;
    right_audio_out_rd_en = 1'b0;
    $display("@ %0t: Closing Left_OUT %s...", $time, FILE_LEFT_OUT_NAME);
    $display("@ %0t: Closing Right_OUT %s...", $time, FILE_RIGHT_OUT_NAME);
    $fclose(left_out_file);
    $fclose(right_out_file);
    $fclose(left_cmp_file);
    $fclose(right_cmp_file);
    out_read_done = 1'b1;
end

endmodule
