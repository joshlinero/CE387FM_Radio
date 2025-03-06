`timescale 1 ns / 1 ns

module fir_complex_tb;

localparam string FILE_IN_REAL_NAME = "../source/src/txt_files/read_iq_i_cmp.txt";
localparam string FILE_IN_IMAG_NAME = "../source/src/txt_files/read_iq_q_cmp.txt";
localparam string FILE_OUT_REAL_NAME = "../source/src/out_files/fir_cmplx_real_sim_out.txt";
localparam string FILE_OUT_IMAG_NAME = "../source/src/out_files/fir_cmplx_imag_sim_out.txt";
localparam string FILE_CMP_REAL_NAME = "../source/src/txt_files/fir_cmplx_real_cmp.txt";
localparam string FILE_CMP_IMAG_NAME = "../source/src/txt_files/fir_cmplx_imag_cmp.txt";

localparam CLOCK_PERIOD = 10;

logic clock = 1'b1;
logic reset = '0;
logic start = '0;
logic done  = '0;

localparam TAPS = 20;
localparam DATA_SIZE = 32;

parameter logic signed [0:TAPS-1] [DATA_SIZE-1:0] CHANNEL_COEFFS_REAL = '{
	32'h00000001, 32'h00000008, 32'hfffffff3, 32'h00000009, 32'h0000000b, 32'hffffffd3, 32'h00000045, 32'hffffffd3, 
	32'hffffffb1, 32'h00000257, 32'h00000257, 32'hffffffb1, 32'hffffffd3, 32'h00000045, 32'hffffffd3, 32'h0000000b, 
	32'h00000009, 32'hfffffff3, 32'h00000008, 32'h00000001
};

parameter logic signed [0:TAPS-1] [DATA_SIZE-1:0] CHANNEL_COEFFS_IMAG = '{
	32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 
	32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 
	32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000
};

logic [DATA_SIZE-1:0] xreal_in_din;
logic xreal_in_full;
logic xreal_in_wr_en;

logic [DATA_SIZE-1:0] ximag_in_din;
logic ximag_in_full;
logic ximag_in_wr_en;

logic [DATA_SIZE-1:0] yreal_out_dout; 
logic yreal_out_empty;
logic yreal_out_rd_en;

logic [DATA_SIZE-1:0] yimag_out_dout;
logic yimag_out_empty;
logic yimag_out_rd_en;


logic   hold_clock    = '0;
logic   in_write_done = '0;
logic   out_read_done = '0;
integer out_errors    = '0;

fir_complex_top #(
    .DATA_SIZE(DATA_SIZE),
    .TAPS(TAPS),
    .DECIMATION(1)
) fir_complex_top_inst (
    .clock(clock),
    .reset(reset),
    .xreal_in_full(xreal_in_full),
    .xreal_in_wr_en(xreal_in_wr_en),
    .xreal_in_din(xreal_in_din),
    .ximag_in_full(ximag_in_full),
    .ximag_in_wr_en(ximag_in_wr_en),
    .ximag_in_din(ximag_in_din),
    .yreal_out_empty(yreal_out_empty),
    .yreal_out_rd_en(yreal_out_rd_en),
    .yreal_out_dout(yreal_out_dout),
    .yimag_out_empty(yimag_out_empty),
    .yimag_out_rd_en(yimag_out_rd_en),
    .yimag_out_dout(yimag_out_dout)
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



initial begin : read_process

    int imag_in_file, real_in_file, count;
    int i = 0, j_real, j_imag;

    @(negedge reset);
    $display("@ %0t: Loading file %s...", $time, FILE_IN_REAL_NAME);
    $display("@ %0t: Loading file %s...", $time, FILE_IN_IMAG_NAME);

    imag_in_file = $fopen(FILE_IN_IMAG_NAME, "rb");
    real_in_file = $fopen(FILE_IN_REAL_NAME, "rb");
    ximag_in_wr_en = 1'b0;
    xreal_in_wr_en = 1'b0;
    i = 0;

    // Read data from input angles text file
    while ( i < 1000 ) begin
        @(negedge clock);
        if (xreal_in_full == 1'b0 && ximag_in_full == 1'b0) begin
            j_real = $fscanf(real_in_file, "%h", xreal_in_din);
            j_imag = $fscanf(imag_in_file, "%h", ximag_in_din);
            xreal_in_wr_en = 1'b1;
            ximag_in_wr_en = 1'b1;
            i++;
        end else begin
            xreal_in_wr_en = 1'b0;
            ximag_in_wr_en = 1'b0;
        end
    end

    @(negedge clock);
    xreal_in_wr_en = 1'b0;
    ximag_in_wr_en = 1'b0;
    $fclose(imag_in_file);
    $fclose(real_in_file);
    in_write_done = 1'b1;
end


initial begin : data_write_process
    
    logic signed [DATA_SIZE-1:0] cmp_out_real;
    logic signed [DATA_SIZE-1:0] cmp_out_imag;
    int i, j_real, j_imag;
    int out_file_real;
    int out_file_imag;
    int cmp_file_real;
    int cmp_file_imag;

    @(negedge reset);
    @(negedge clock);

    $display("@ %0t: Comparing file %s...", $time, FILE_OUT_REAL_NAME);
    out_file_real = $fopen(FILE_OUT_REAL_NAME, "wb");
    $display("@ %0t: Comparing file %s...", $time, FILE_OUT_IMAG_NAME);
    out_file_imag = $fopen(FILE_OUT_IMAG_NAME, "wb");
    cmp_file_real = $fopen(FILE_CMP_REAL_NAME, "rb");
    cmp_file_imag = $fopen(FILE_CMP_IMAG_NAME, "rb");
    yreal_out_rd_en = 1'b0;
    yimag_out_rd_en = 1'b0;

    i = 0;
    while (i < 1000) begin
        @(negedge clock);
        yreal_out_rd_en = 1'b0;
        yimag_out_rd_en = 1'b0;
        if (yreal_out_empty == 1'b0 && yimag_out_empty == 1'b0) begin
            yreal_out_rd_en = 1'b1;
            yimag_out_rd_en = 1'b1;
            j_real = $fscanf(cmp_file_real, "%h", cmp_out_real);
            j_imag = $fscanf(cmp_file_imag, "%h", cmp_out_imag);
            $fwrite(out_file_real, "%08x\n", yreal_out_dout);
            $fwrite(out_file_imag, "%08x\n", yimag_out_dout);
            if (cmp_out_real != yreal_out_dout) begin
                out_errors += 1;
                $write("@ %0t: (%0d): REAL ERROR: %x != %x.\n", $time, i+1, yreal_out_dout, cmp_out_real);
            end
            if (cmp_out_imag != yimag_out_dout) begin
                out_errors += 1;
                $write("@ %0t: (%0d): IMAG ERROR: %x != %x.\n", $time, i+1, yimag_out_dout, cmp_out_imag);
            end
            i++;
        end
    end

    @(negedge clock);
    yreal_out_rd_en = 1'b0;
    yimag_out_rd_en = 1'b0;
    $fclose(out_file_real);
    $fclose(out_file_imag);
    $fclose(cmp_file_real);
    $fclose(cmp_file_imag);
    out_read_done = 1'b1;
end

endmodule







