module iir #(
    parameter TAPS = 2,
    parameter DECIMATION = 1,
    parameter DATA_SIZE = 32,
    parameter [0:TAPS-1][DATA_SIZE-1:0] X_COEFFS = 
    '{
        (32'h000000B2), (32'h000000B2)
    },
    parameter [0:TAPS-1][DATA_SIZE-1:0] Y_COEFFS = 
    '{
        (32'h00000000), (32'hFFFFFD66)
    }
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

logic [0:TAPS-1][DATA_SIZE-1:0] x, x_c;
logic [0:TAPS-1][DATA_SIZE-1:0] y, y_c;
logic [DATA_SIZE-1:0] count;
logic [DATA_SIZE-1:0] count_c;
logic [DATA_SIZE-1:0] sum, sum_c, temp_sum_1, temp_sum_2, temp_sum_3, temp_sum_4;
//logic [DATA_SIZE-1:0] temp_sum;
logic [DATA_SIZE-1:0] y_out_c;
logic y_wr_en_c;

always_ff @( posedge clock or posedge reset ) begin
    if (reset == 1'b1) begin
        state <= INIT;
        x <= '0;
        y <= '0;
        y_out <= '0;
        count <= '0;
        sum <= '0;
        y_wr_en <= 1'b0;
    end else begin
        x <= x_c;
        y <= y_c;
        y_out <= y_out_c;
        count <= count_c;
        state <= next_state;
        sum <= sum_c;
        y_wr_en <= y_wr_en_c;
    end
end

always_comb begin
    x_c = x;
    y_c = y;
    count_c = count;
    sum_c = '0;
    //temp_sum = '0;
    temp_sum_1 = '0;
    temp_sum_2 = '0;
    temp_sum_3 = '0;
    temp_sum_4 = '0;
    x_rd_en = 1'b0;
    y_wr_en_c = 1'b0;
    y_out_c = '0;

    case (state)
        INIT: begin
            if (x_empty == 1'b0) begin
                x_rd_en = 1'b1;
                x_c[1:DATA_SIZE-1] = x[0:DATA_SIZE-2];
                x_c[0] = x_in;
                y_c[1:DATA_SIZE-1] = y[0:DATA_SIZE-2];

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
            temp_sum_1 = DEQUANTIZE($signed(X_COEFFS[0]) * $signed(x[0]));
            temp_sum_2 = DEQUANTIZE($signed(X_COEFFS[1]) * $signed(x[1]));
            temp_sum_3 = DEQUANTIZE($signed(Y_COEFFS[0]) * $signed(y[0]));
            temp_sum_4 = DEQUANTIZE($signed(Y_COEFFS[1]) * $signed(y[1]));
            sum_c = temp_sum_1 + temp_sum_2 + temp_sum_3 + temp_sum_4;

            next_state = WRITE;
        end

        WRITE: begin
            if (y_out_full == 1'b0) begin
                y_wr_en_c = 1'b1;
                y_out_c = y[1];
                y_c[0] = sum;
                next_state = INIT;
            end else begin
                next_state = WRITE;
            end
        end

        default: begin
            next_state = INIT;
            x_c = 'x;
            y_c = 'x;
            count_c = 'x;
        end
    endcase
end 

endmodule