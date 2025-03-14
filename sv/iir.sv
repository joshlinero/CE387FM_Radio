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

typedef enum logic[1:0] {
    INIT, 
    COMPUTE1,
    COMPUTE2,
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

// shift regs
logic [0:TAPS-1][DATA_SIZE-1:0] x, x_c;
logic [0:TAPS-1][DATA_SIZE-1:0] y, y_c;

// shift reg counters
logic [$clog2(TAPS)-1:0] count, count_c;
logic [$clog2(TAPS)-1:0] y_count, y_count_c;

// accumulated sum
logic [DATA_SIZE-1:0] y1, y1_c;
logic [DATA_SIZE-1:0] y2, y2_c;

// temp taps
logic [DATA_SIZE-1:0] x_tap, x_tap_c;
logic [DATA_SIZE-1:0] y_tap, y_tap_c;

// temp mults
logic signed [DATA_SIZE-1:0] y1_prod, y1_prod_c;
logic signed [DATA_SIZE-1:0] y2_prod, y2_prod_c;

logic last, last_c;
logic coeff, coeff_c;

always_ff @( posedge clock or posedge reset ) begin
    if (reset == 1'b1) begin
        state <= INIT;
        x <= '0;
        y <= '0;
        count <= '0;
        y_count <= '0;
        y1 <= '0;
        y2 <= '0;
        x_tap <= '0;
        y_tap <= '0;
        y1_prod <= '0;
        y2_prod <= '0;
        last <= 1'b0;
        coeff <= 1'b0;
    end else begin
        state <= next_state;
        x <= x_c;
        y <= y_c;
        count <= count_c;
        y_count <= y_count_c;
        y1 <= y1_c;
        y2 <= y2_c;
        x_tap <= x_tap_c;
        y_tap <= y_tap_c;
        y1_prod <= y1_prod_c;
        y2_prod <= y2_prod_c;
        last <= last_c;
        coeff <= coeff_c;
    end
end

always_comb begin
    next_state = state;
    x_rd_en = 1'b0;
    y_wr_en = 1'b0;
    x_c = x;
    y_c = y;
    count_c = count;
    y_count_c = y_count;
    y1_c = y1;
    y2_c = y2;
    x_tap_c = x_tap;
    y_tap_c = y_tap;
    y1_prod_c = y1_prod;
    y2_prod_c = y2_prod;
    last_c = last;
    coeff_c = coeff;

    case (state)
        INIT: begin
            if (x_empty == 1'b0) begin
                x_rd_en = 1'b1;
                x_c[1:TAPS-1] = x[0:TAPS-2];
                x_c[0] = x_in;
                x_tap_c = x_in;
                count_c = count + 1;
                next_state = COMPUTE1;
            end
        end

        COMPUTE1: begin
            if (y_count < TAPS - 1) begin
                y_c[1:TAPS-1] = y[0:TAPS-2];
                y_count_c = y_count + 1;
                next_state = COMPUTE1;
            end else begin
                y_tap_c = y[0];
                next_state = COMPUTE2;
            end
        end

        COMPUTE2: begin
            if (last == 1'b0) begin
                y1_prod_c = $signed(x_tap) * $signed(X_COEFFS[coeff]);
                y2_prod_c = $signed(y_tap) * $signed(Y_COEFFS[coeff]);
                if (count != 1'b1) begin
                    y1_c = $signed(y1) + DEQUANTIZE(y1_prod);
                    y2_c = $signed(y2) + DEQUANTIZE(y2_prod);
                end
                count_c = count + 1;
                coeff_c = coeff + 1;
                x_tap_c = x[count];
                y_tap_c = y[count];
                if (count == 1'b0) begin
                    last_c = 1'b1;
                end
            end else begin
                y1_c = $signed(y1) + DEQUANTIZE(y1_prod);
                y2_c = $signed(y2) + DEQUANTIZE(y2_prod);
                last_c = 1'b0;
                next_state = WRITE;
            end
        end

        WRITE: begin
            if (y_out_full == 1'b0) begin
                y_wr_en = 1'b1;
                y_out = y[TAPS-1];
                y_c[0] = $signed(y1) + $signed(y2);
                count_c = 0;
                y_count_c = 0;
                coeff_c = 0;
                y1_c = '0;
                y2_c = '0;
                next_state = INIT;
            end
        end

        default: begin
            next_state = INIT;
            x_rd_en = 1'b0;
            y_wr_en = 1'b0;
            y_out = '0;
            count_c = 'x;
            y_count_c = 'x;
            x_c = 'x;
            y_c = 'x;
            y1_c = 'x;
            y2_c = 'x;
            x_tap_c = 'x;
            y_tap_c = 'x;
            y1_prod_c = 'x;
            y2_prod_c = 'x;
            last_c = 'x;
            coeff_c = 'x;
        end
    endcase
end 

endmodule