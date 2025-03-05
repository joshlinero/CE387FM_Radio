
module qarctan #(
    parameter DATA_SIZE = 32
)(
    input   logic                   clock,
    input   logic                   reset,
    input   logic                   start_signal,
    input   logic [DATA_SIZE-1:0]   real_,
    input   logic [DATA_SIZE-1:0]   imag,

    output  logic [DATA_SIZE-1:0]   data_out,
    output  logic                   done_signal   
);

    
const logic [DATA_SIZE-1:0] QUAD_ONE = 32'h00000324;
const logic [DATA_SIZE-1:0] QUAD_THREE = 32'h0000096c;

function logic signed [DATA_SIZE-1:0] DEQUANTIZE(logic signed [DATA_SIZE-1:0] val);
    if (val < 0) begin
        DEQUANTIZE = DATA_SIZE'(-(-val >>> 10));
    end else begin
        DEQUANTIZE = DATA_SIZE'(val >>> 10);
    end
endfunction

function logic signed [DATA_SIZE-1:0] QUANTIZE(logic signed [DATA_SIZE-1:0] val);
    QUANTIZE = DATA_SIZE'(val << 10);
endfunction

function automatic logic signed [DATA_SIZE-1:0] abs_val(input logic signed [DATA_SIZE-1:0] val);
    if (val < 0) begin
        abs_val = -val;
    end else begin 
        abs_val = val;
    end
endfunction

typedef enum logic [1:0] {
    INIT,
    MULT,
    ANGLE,
    WRITE
} state_t;
state_t state, next_state;

logic div_start, div_overflow_out, div_done;
logic [DATA_SIZE-1:0] dividend;
logic [DATA_SIZE-1:0] divisor;
logic [DATA_SIZE-1:0] div_quotient_out;
logic [DATA_SIZE-1:0] div_remainder_out;

logic [DATA_SIZE-1:0] angle;
logic [DATA_SIZE-1:0] abs_imag;
logic [DATA_SIZE-1:0] real_minus_imag, real_plus_imag, imag_minus_real;
logic [DATA_SIZE-1:0] q_real_minus_imag, q_real_plus_imag;

logic [DATA_SIZE-1:0] quad_product, data_out_temp;
logic [DATA_SIZE-1:0] quad_product_c, data_out_temp_c;


always_ff @(posedge clock or posedge reset) begin
    if (reset == 1'b1) begin
        state <= INIT;
        quad_product <= '0;
        data_out_temp <= '0;
    end else begin
        state <= next_state;
        quad_product <= quad_product_c;
        data_out_temp <= data_out_temp_c;
    end
end

divider #(
    .DIVIDEND_WIDTH(DATA_SIZE*2),
    .DIVISOR_WIDTH(DATA_SIZE)
) divider_inst (
    .clock(clock),
    .reset(reset),
    .start(div_start),
    .dividend(dividend),
    .divisor(divisor),
    .quotient(div_quotient_out),
    .remainder(div_remainder_out),
    .overflow(div_overflow_out),
    .done(div_done)
);

always_comb begin
    // Output the current readiness of the divider
    done_signal = 1'b0;;
    data_out = '0;
    quad_product_c = quad_product;
    data_out_temp_c = data_out_temp;

    // Default start_div assignment
    div_start = 1'b0;

    case(state)
        INIT: begin
            if (start_signal == 1'b1) begin
                div_start = 1'b1;

                abs_imag = abs_val(imag) + 32'h00000001;

                real_minus_imag = $signed(real_) - $signed(abs_imag);
                real_plus_imag = $signed(real_) + $signed(abs_imag);
                imag_minus_real = $signed(abs_imag) - $signed(real_);

                q_real_minus_imag = QUANTIZE(real_minus_imag);
                q_real_plus_imag = QUANTIZE(real_plus_imag);

                // Assign dividend and divisor 
                if ($signed(real_) >= 0) begin
                    if ($signed(q_real_minus_imag) >= 0) begin
                        dividend = {32'h0, q_real_minus_imag};
                    end else begin
                        dividend = {32'hffffffff, q_real_minus_imag};
                    end
                    divisor = real_minus_imag;
                end else begin
                    if ($signed(q_real_plus_imag) >= 0) begin
                        dividend = {32'h0, q_real_plus_imag};
                    end else begin
                        dividend = {32'hffffffff, q_real_plus_imag}; 
                    end
                    divisor = imag_minus_real;
                end
                next_state = MULT;
            end
            else begin
                next_state = INIT;
            end

        end

        MULT: begin
            // Division complete
            if (div_done == 1'b1) begin
                //if ($signed(real) >= 0) begin
                    quad_product_c = $signed(QUAD_ONE) * $signed(div_quotient_out);
                    next_state = ANGLE;
               // end
            end else begin
                next_state = MULT;
            end
        end

        ANGLE: begin
            if (real_ == '0 && imag == '0) 
                angle = 32'h648;
            else if ($signed(real_) >= 0) 
                angle = ($signed(QUAD_ONE) - $signed(DEQUANTIZE(quad_product)));
            else 
                angle = ($signed(QUAD_THREE) - $signed(DEQUANTIZE(quad_product)));

            data_out_temp_c = ($signed(imag) < 0) ? -$signed(angle) : angle;
            next_state = WRITE;
        end

        WRITE: begin
            done_signal = 1'b1;
            data_out = data_out_temp;
            next_state = INIT;
        end

        default: begin
            data_out = 'x;
            done_signal = 1'bx;
            quad_product_c = 'x;
            div_start = 1'bx;
            data_out_temp_c = 'x;
        end

    endcase
end

endmodule

