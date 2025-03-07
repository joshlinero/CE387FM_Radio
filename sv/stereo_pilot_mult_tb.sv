`timescale 1 ns / 1 ns

module stereo_pilot_mult_tb;

localparam string FILE_IN_NAME = "../source/src/txt_files/demodulate_cmp.txt";
localparam string FILE_OUT_NAME = "../source/src/out_files/spm_out.txt";
localparam string FILE_CMP_NAME = "../source/src/txt_files/spm_pilot_mult_cmp.txt";

localparam CLOCK_PERIOD = 10;

logic clock = 1'b1;
logic reset = '0;
logic start = '0;
logic done  = '0;

localparam DECIMATION = 1;
localparam TAPS = 32;
localparam DATA_SIZE = 32;


parameter logic signed [0:TAPS-1] [DATA_SIZE-1:0] BP_PILOT_COEFFS = '{
    32'h0000000e, 32'h0000001f, 32'h00000034, 32'h00000048, 32'h0000004e, 32'h00000036, 32'hfffffff8, 32'hffffff98, 
    32'hffffff2d, 32'hfffffeda, 32'hfffffec3, 32'hfffffefe, 32'hffffff8a, 32'h0000004a, 32'h0000010f, 32'h000001a1, 
    32'h000001a1, 32'h0000010f, 32'h0000004a, 32'hffffff8a, 32'hfffffefe, 32'hfffffec3, 32'hfffffeda, 32'hffffff2d, 
    32'hffffff98, 32'hfffffff8, 32'h00000036, 32'h0000004e, 32'h00000048, 32'h00000034, 32'h0000001f, 32'h0000000e
};

logic spm_in_full;
logic spm_in_wr_en = '0;
logic signed [DATA_SIZE-1:0] spm_in_din = '0;
logic spm_out_empty;
logic spm_out_rd_en = '0;
logic signed [DATA_SIZE-1:0] spm_out_dout;

logic   hold_clock    = '0;
logic   in_write_done = '0;
logic   out_read_done = '0;
integer out_errors    = '0;

stereo_pilot_mult_top #(
    .TAPS(TAPS),
    .DECIMATION(DECIMATION),
    .DATA_SIZE(DATA_SIZE),
    .GLOBAL_COEFF(BP_PILOT_COEFFS)

) spm_top_inst (
    .clock(clock),
    .reset(reset),
    .spm_in_din(spm_in_din),
    .spm_in_full(spm_in_full),
    .spm_in_wr_en(spm_in_wr_en),
    .spm_out_empty(spm_out_empty),
    .spm_out_rd_en(spm_out_rd_en),
    .spm_out_dout(spm_out_dout)
);

always begin
    clock = 1'b1;
    #(CLOCK_PERIOD/2);
    clock = 1'b0;
    #(CLOCK_PERIOD/2);
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

    // start
    $display("@ %0t: Beginning simulation...", start_time);
    start = 1'b1;
    @(posedge clock);
    start = 1'b0;

    wait(out_read_done);
    end_time = $time;

    // report metrics
    $display("@ %0t: Simulation completed.", end_time);
    $display("Total simulation cycle count: %0d", (end_time-start_time)/CLOCK_PERIOD);
    $display("Total error count: %0d", out_errors);

    // end the simulation
    $finish;
end

initial begin : data_read_process

    int in_file;
    int i, j;

    @(negedge reset);
    $display("@ %0t: Loading file %s...", $time, FILE_IN_NAME);
    in_file = $fopen(FILE_IN_NAME, "rb");

    spm_in_wr_en = 1'b0;
    @(negedge clock);

    i = 0;
    while (i < 1000) begin
 
        @(negedge clock);
        if (spm_in_full == 1'b0) begin
            spm_in_wr_en = 1'b1;
            j = $fscanf(in_file, "%h", spm_in_din);
            // $display("(%0d) Input value %x",i,x_in_din);
            i++;
        end else
            spm_in_wr_en = 1'b0;
    end

    @(negedge clock);
    spm_in_wr_en = 1'b0;
    $fclose(in_file);
    in_write_done = 1'b1;
end

initial begin : data_write_process
    
    logic signed [DATA_SIZE-1:0] cmp_out;
    int i, j;
    int out_file;
    int cmp_file;

    @(negedge reset);
    @(negedge clock);

    $display("@ %0t: Comparing file %s...", $time, FILE_CMP_NAME);
    out_file = $fopen(FILE_OUT_NAME, "wb");
    cmp_file = $fopen(FILE_CMP_NAME, "rb");
    spm_out_rd_en = 1'b0;

    i = 0;
    while (i < 1000/DECIMATION) begin
        @(negedge clock);
        spm_out_rd_en = 1'b0;
        if (spm_out_empty == 1'b0) begin
            spm_out_rd_en = 1'b1;
            j = $fscanf(cmp_file, "%h", cmp_out);
            $fwrite(out_file, "%08x\n", spm_out_dout);
            if (cmp_out != spm_out_dout) begin
                out_errors += 1;
                $write("@ %0t: (%0d): ERROR: %x != %x.\n", $time, i+1, spm_out_dout, cmp_out);
            end else 
                $write("@ %0t: (%0d): CORRECT RESULT: %x == %x.\n", $time, i+1, spm_out_dout, cmp_out);
            i++;
        end
    end

    @(negedge clock);
    spm_out_rd_en = 1'b0;
    $fclose(out_file);
    $fclose(cmp_file);
    out_read_done = 1'b1;
end

endmodule