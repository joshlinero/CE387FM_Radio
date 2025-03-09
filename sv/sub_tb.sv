`timescale 1ns/1ps

module sub_tb;

/* files */
localparam string IN_LMR_FILE_NAME = "../source/src/txt_files/audio_lmr_cmp.txt";
localparam string IN_LPR_FILE_NAME = "../source/src/txt_files/audio_lpr_cmp.txt";
localparam string OUT_FILE_NAME = "../source/src/out_files/sub_out.txt";
localparam string CMP_FILE_NAME = "../source/src/txt_files/sub_cmp.txt";

localparam CLOCK_PERIOD = 10;
localparam DATA_SIZE = 32;

logic clock, reset;

logic [DATA_SIZE-1:0] real_in;
logic [DATA_SIZE-1:0] imag_in;
logic [DATA_SIZE-1:0] data_out;

logic real_wr_en;
logic real_full;
logic imag_wr_en;
logic imag_full;
logic data_out_rd_en;
logic data_out_empty;

logic out_rd_done = '0;
logic in_write_done = '0;

integer out_errors = 0;

sub_top #(
    .DATA_SIZE(DATA_SIZE)
) sub_top_inst (
    .clock(clock),
    .reset(reset),

    .sub_lmr_in_din(real_in),
    .sub_lmr_in_full(real_full),
    .sub_lmr_in_wr_en(real_wr_en),

    .sub_lpr_in_din(imag_in),
    .sub_lpr_in_full(imag_full),
    .sub_lpr_in_wr_en(imag_wr_en),
    
    .sub_out_dout(data_out),
    .sub_out_empty(data_out_empty),
    .sub_out_rd_en(data_out_rd_en)
);

always begin
    clock = 1'b0;
    #(CLOCK_PERIOD/2);
    clock = 1'b1;
    #(CLOCK_PERIOD/2);
end

/* reset */
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

    // start
    $display("@ %0t: Beginning simulation...", start_time);
    @(posedge clock);

    wait(out_rd_done && in_write_done);
    end_time = $time;

    // report metrics
    $display("@ %0t: Simulation completed.", end_time);
    $display("Total simulation cycle count: %0d", (end_time-start_time)/CLOCK_PERIOD);
    $display("Total error count: %0d", out_errors);

    // end the simulation
    $finish;
end

initial begin : read_process

    int i, imag_in_file, real_in_file, count;

    @(negedge reset);
    $display("@ %0t: Loading file %s...", $time, IN_LMR_FILE_NAME);
    $display("@ %0t: Loading file %s...", $time, IN_LPR_FILE_NAME);

    imag_in_file = $fopen(IN_LPR_FILE_NAME, "rb");
    real_in_file = $fopen(IN_LMR_FILE_NAME, "rb");
    real_wr_en = 1'b0;
    imag_wr_en = 1'b0;
    i = 0;

    // Read data from input angles text file
    while ( i < 1000 ) begin
        @(negedge clock);
        if (real_full == 1'b0 && imag_full == 1'b0) begin
            count = $fscanf(imag_in_file,"%h", imag_in);
            count = $fscanf(real_in_file,"%h", real_in);
            real_wr_en = 1'b1;
            imag_wr_en = 1'b1;
            i++;
        end else begin
            real_wr_en = 1'b0;
            imag_wr_en = 1'b0;
        end
    end

    @(negedge clock);
    real_wr_en = 1'b0;
    imag_wr_en = 1'b0;
    // $display("CLOSING IN FILE");
    $fclose(real_in_file);
    $fclose(imag_in_file);
    in_write_done = 1'b1;
end

initial begin : comp_process
    int i, r;
    int cmp_file;
    logic [DATA_SIZE-1:0] cmp_dout;
    int out_file;

    @(negedge reset);
    @(posedge clock);

    $display("@ %0t: Comparing file %s...", $time, CMP_FILE_NAME);
    out_file = $fopen(OUT_FILE_NAME, "wb");
    cmp_file = $fopen(CMP_FILE_NAME, "rb");
    data_out_rd_en = 1'b0;
    i = 0;
    while (i < 1000) begin
        @(negedge clock);
        data_out_rd_en = 1'b0;
        if (data_out_empty == 1'b0) begin
            data_out_rd_en = 1'b1;
            r = $fscanf(cmp_file, "%h", cmp_dout);
            $fwrite(out_file, "%08x\n", data_out);
            if (cmp_dout != data_out) begin
                out_errors++;
                $display("@ %0t: (%0d): ERROR: %x != %x.", $time, i+1, data_out, cmp_dout);
            end else
                $display("@ %0t: (%0d): CORRECT: %x == %x.", $time, i+1, data_out, cmp_dout);
            i++;
        end 
    end

    @(negedge clock);
    data_out_rd_en = 1'b0;
    $display("CLOSING CMP FILE");
    $fclose(cmp_file);
    $fclose(out_file);
    out_rd_done = 1'b1;
end

endmodule;