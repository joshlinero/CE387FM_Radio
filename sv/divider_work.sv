module divider_work #(
    parameter DIVIDEND_WIDTH = 32,
    parameter DIVISOR_WIDTH  = 32
)
(
    input logic clock,
    input logic reset,
    input logic start,
    input logic [DIVIDEND_WIDTH-1:0] numerator,
    input logic [DIVISOR_WIDTH-1:0] denominator,
    output logic [DIVIDEND_WIDTH-1:0] quotient,
    output logic [DIVISOR_WIDTH-1:0] remainder,
    output logic error,
    output logic done
);

    typedef enum logic [2:0] {
        INIT,
        CHECK,
        FIND_MSB,
        COMPUTE1,
        COMPUTE2,
        WRITE
    } state_t;
    state_t state, next_state;

    logic signed [DIVIDEND_WIDTH-1:0] reg_1_curr, reg_1_curr_c;
    logic signed [DIVISOR_WIDTH-1:0] reg_2_curr, reg_2_curr_c;
    logic signed [DIVIDEND_WIDTH-1:0] q, q_c;
    logic signed [DIVIDEND_WIDTH-1:0] p, p_c, p_temp;
    logic internal_sign;

    logic [$clog2(DIVIDEND_WIDTH)-1:0] msb_a, msb_a_c;
    logic [$clog2(DIVIDEND_WIDTH)-1:0] msb_b, msb_b_c;

    logic signed [DIVIDEND_WIDTH-1:0] remainder_condition;

    function automatic logic [$clog2(DIVIDEND_WIDTH)-1:0] get_msb(logic [DIVIDEND_WIDTH-1:0] val, logic [$clog2(DIVIDEND_WIDTH)-1:0] msb);
        logic [$clog2(DIVIDEND_WIDTH)-1:0] left;
        logic [$clog2(DIVIDEND_WIDTH)-1:0] right;

        if (val[msb] == 1'b1) begin
            return msb;
        end else if (msb == 1'b0) begin
            return 1'b0;
        end else begin
            left = get_msb(val, msb - 1);
            right = get_msb(val, (msb - 1) / 2);

            if (left >= 1'b0) begin
                return left;
            end else if (right >= 1'b0) begin
                return right;
            end else begin
                return 1'b0;
            end
        end
    endfunction

    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
            reg_1_curr <= 0;
            reg_2_curr <= 0;
            q <= 0;
            p <= 0;
            msb_a <= 0;
            msb_b <= 0;
            state <= INIT;
        end else begin
            reg_1_curr <= reg_1_curr_c;
            reg_2_curr <= reg_2_curr_c;
            q <= q_c;
            p <= p_c;
            msb_a <= msb_a_c;
            msb_b <= msb_b_c;
            state <= next_state;
        end
    end

    always_comb begin
        next_state = state;
        reg_1_curr_c = reg_1_curr;
        reg_2_curr_c = reg_2_curr;
        q_c = q;
        p_c = p;
        msb_a_c = msb_a;
        msb_b_c = msb_b;
        done = 0;
        quotient = 0;
        remainder = 0;
        error = 0;

        case (state)

            INIT: begin
                if (start) begin
                    error = 0;
                    reg_1_curr_c = (numerator[DIVIDEND_WIDTH-1] == 1'b0) ? numerator : -numerator;
                    reg_2_curr_c = (denominator[DIVISOR_WIDTH-1] == 1'b0) ? denominator : -denominator;
                    q_c = '0;
                    p_c = '0;
                    if (denominator == 1) begin
                        next_state = CHECK;
                    end else if (denominator == 0) begin
                        error = 1;
                        next_state = CHECK;
                    end else begin
                        next_state = FIND_MSB;
                    end
                end else begin
                    next_state = INIT;
                end
            end

            CHECK: begin
                q_c = numerator;
                reg_1_curr_c = 1'b0;
                reg_2_curr_c = reg_2_curr;
                next_state = WRITE;
            end

            FIND_MSB: begin
                msb_a_c = get_msb(reg_1_curr, (DIVIDEND_WIDTH-1));
                msb_b_c = get_msb(reg_2_curr, (DIVISOR_WIDTH-1));
                next_state = COMPUTE1;
            end

            COMPUTE1: begin
                p_temp = msb_a - msb_b;
                p_c = ((reg_2_curr << p_temp) > reg_1_curr) ? p_temp - 1 : p_temp;
                next_state = COMPUTE2;
            end

            COMPUTE2: begin
                q_c = q + (1 << p);
                if ((reg_2_curr != 1'b0) && (reg_2_curr <= reg_1_curr)) begin
                    reg_1_curr_c = reg_1_curr - (reg_2_curr << p);
                    next_state = FIND_MSB;
                end else begin
                    next_state = WRITE;
                end
            end

            WRITE: begin
                internal_sign = numerator[DIVIDEND_WIDTH-1] ^ denominator[DIVISOR_WIDTH-1];
                quotient = (internal_sign == 1'b0) ? q : -q;
                remainder_condition = numerator[DIVIDEND_WIDTH-1];
                remainder = (remainder_condition == 1'b0) ? reg_1_curr : -reg_1_curr;
                done = 1;
                next_state = INIT;
            end

            default: begin
                reg_1_curr_c = 'x;
                reg_2_curr_c = 'x;
                q_c = 'x;
                p_c = 'x;
                msb_a_c = 'x;
                msb_b_c = 'x;
                quotient = 'x;
                remainder = 'x;
                error = 'x;
                done = 'x;
                next_state = INIT;
            end

        endcase
    end

endmodule