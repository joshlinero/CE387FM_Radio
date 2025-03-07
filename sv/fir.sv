module fir #(
    parameter TAPS = 32,
    parameter DECIMATION = 8,
    parameter DATA_SIZE = 32
)
(
    input  logic                    clock,
    input  logic                    reset,
    
    input  logic [DATA_SIZE-1:0]    x_in,
    output logic                    x_rd_en,
    input  logic                    x_empty,

    output logic [DATA_SIZE-1:0]    y_out,
    input  logic                    y_out_full,
    output logic                    y_wr_en
);

	
parameter logic signed [0:TAPS-1] [DATA_SIZE-1:0] CHANNEL_COEFFS = '{
	32'hfffffffd, 32'hfffffffa, 32'hfffffff4, 32'hffffffed, 32'hffffffe5, 32'hffffffdf, 32'hffffffe2, 32'hfffffff3, 
	32'h00000015, 32'h0000004e, 32'h0000009b, 32'h000000f9, 32'h0000015d, 32'h000001be, 32'h0000020e, 32'h00000243, 
	32'h00000243, 32'h0000020e, 32'h000001be, 32'h0000015d, 32'h000000f9, 32'h0000009b, 32'h0000004e, 32'h00000015, 
	32'hfffffff3, 32'hffffffe2, 32'hffffffdf, 32'hffffffe5, 32'hffffffed, 32'hfffffff4, 32'hfffffffa, 32'hfffffffd
};


typedef enum logic[2:0] {
    INIT, 
    COMPUTE, 
    WRITE
} state_t;
state_t state, next_state;

function logic signed [DATA_SIZE-1:0] DEQUANTIZE(logic signed [DATA_SIZE-1:0] val);
    if (val < 0) begin
        DEQUANTIZE = DATA_SIZE'(-(-val >>> 10));
    end else begin
        DEQUANTIZE = DATA_SIZE'(val >>> 10);
    end
endfunction

logic [0:DATA_SIZE-1][DATA_SIZE-1:0] x, x_c;
logic [DATA_SIZE-1:0] count;
logic [DATA_SIZE-1:0] count_c;
logic [DATA_SIZE-1:0] sum, sum_c, temp_sum, temp_deq;
logic [DATA_SIZE-1:0] y_out_c;
logic y_wr_en_c;

always_ff @( posedge clock or posedge reset ) begin
    if (reset == 1'b1) begin
        state <= INIT;
        x <= '0;
        y_out <= '0;
        count <= '0;
        sum <= '0;
        y_wr_en <= 1'b0;
    end else begin
        x <= x_c;
        y_out <= y_out_c;
        count <= count_c;
        state <= next_state;
        sum <= sum_c;
        y_wr_en <= y_wr_en_c;
    end
end

always_comb begin
    x_c = x;
    count_c = count;
    sum_c = sum;
    temp_sum = '0;
    x_rd_en = 1'b0;
    y_wr_en_c = 1'b0;
    y_out_c = '0;

    case (state)
        INIT: begin
            if (x_empty == 1'b0) begin
                x_rd_en = 1'b1;
                x_c[1:DATA_SIZE-1] = x[0:DATA_SIZE-2];
                x_c[0] = x_in;

                count_c = (count + 1) % DECIMATION;
                if (count == DECIMATION - 1) begin
                    next_state = COMPUTE;
                end else begin
                    next_state = INIT;
                end
            end else begin
                next_state = INIT;
            end
        end

        COMPUTE: begin
            temp_sum = CHANNEL_COEFFS[TAPS - count - 1] * x[count];
            temp_deq = DEQUANTIZE(temp_sum);
            sum_c = sum + temp_deq;

            count_c = (count + 1) % TAPS;
            if (count == TAPS - 1) begin 
                next_state = WRITE;
            end else begin
                next_state = COMPUTE;
            end
        end

        WRITE: begin
            if (y_out_full == 1'b0) begin
                y_wr_en_c = 1'b1;
                y_out_c = sum;
                next_state = INIT;
            end else begin
                next_state = WRITE;
            end
        end

        default: begin
            next_state = INIT;
            x_c = 'x;
            count_c = 'x;
        end
    endcase
end 

endmodule