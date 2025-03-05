`timescale 1ns/1ps

module demodulate_tb;

/* files */
localparam string IN_IMAG_FILE_NAME = "../source/src/txt_files/fir_cmplx_imag_out.txt";
localparam string IN_REAL_FILE_NAME = "../source/src/txt_files/fir_cmplx_real_out.txt";
localparam string OUT_FILE_NAME = "../source/src/out_files/demodulate_out.txt";
localparam string CMP_FILE_NAME = "../source/src/txt_files/demodulate_cmp.txt";

localparam int CLOCK_PERIOD = 10;

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

demodulate_top #(
    .DATA_SIZE(32)
) demodulate_top_inst (
    .clock(clock),
    .reset(reset),
    .real_in(real_in),
    .real_wr_en(real_wr_en),
    .real_full(real_full),
    .imag_in(imag_in),
    .imag_wr_en(imag_wr_en),
    .imag_full(imag_full),
    .data_out(data_out),
    .data_out_rd_en(data_out_rd_en),
    .data_out_empty(data_out_empty)
);

always begin
    clk = 1'b0;
    #(CLOCK_PERIOD/2);
    clk = 1'b1;
    #(CLOCK_PERIOD/2);
end

/* reset */
initial begin
    @(posedge clk);
    reset = 1'b1;
    @(posedge clk);
    reset = 1'b0;
end

initial begin : tb_process
    longint unsigned start_time, end_time;

    @(negedge reset);
    @(posedge clk);
    start_time = $time;

    // start
    $display("@ %0t: Beginning simulation...", start_time);
    @(posedge clk);

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
    $display("@ %0t: Loading file %s...", $time, IN_IMAG_FILE_NAME);
    $display("@ %0t: Loading file %s...", $time, IN_REAL_FILE_NAME);

    imag_in_file = $fopen(IN_IMAG_FILE_NAME, "rb");
    real_in_file = $fopen(IN_REAL_FILE_NAME, "rb");
    real_wr_en = 1'b0;
    imag_wr_en = 1'b0;
    i = 0;

    // Read data from input angles text file
    while ( i < 50 ) begin
        @(negedge clk);
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

    @(negedge clk);
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
    @(posedge clk);

    $display("@ %0t: Comparing file %s...", $time, CMP_FILE_NAME);
    out_file = $fopen(OUT_FILE_NAME, "wb");
    cmp_file = $fopen(CMP_FILE_NAME, "rb");
    data_out_rd_en = 1'b0;
    i = 0;
    while (i < 50) begin
        @(negedge clk);
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

    @(negedge clk);
    data_out_rd_en = 1'b0;
    $display("CLOSING CMP FILE");
    $fclose(cmp_file);
    $fclose(out_file);
    out_rd_done = 1'b1;
end

endmodule;