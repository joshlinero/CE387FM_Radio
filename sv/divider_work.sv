module divider_work #(
    parameter DIVIDEND_WIDTH = 32,
    parameter DIVISOR_WIDTH  = 32
)(
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

    typedef enum logic [1:0] {
        INIT,
        CHECK,
        COMPUTE,
        DONE
    } state_t;
    state_t state, next_state;

    logic [DIVIDEND_WIDTH-1:0] reg_1_curr, reg_1_next; 
    logic [DIVIDEND_WIDTH-1:0] reg_quotient, reg_q_next;
    logic [DIVISOR_WIDTH-1:0] reg_2_curr, reg_2_next;
    logic [DIVISOR_WIDTH-1:0] reg_remainder, reg_r_next;
    logic err_flag, err_flag_next;
    logic done_flag, done_flag_next;
    int pos, pos_next;
    logic sign;

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
            reg_quotient <= 0;
            reg_remainder <= 0;
            err_flag <= 0;
            pos <= 0;
            done_flag <= 0;
            state <= INIT;
        end else begin
            reg_1_curr <= reg_1_next;
            reg_2_curr <= reg_2_next;
            reg_quotient <= reg_q_next;
            reg_remainder <= reg_r_next;
            err_flag <= err_flag_next;
            done_flag <= done_flag_next;
            state <= next_state;
            pos <= pos_next;
        end
    end

    always_comb begin
        reg_1_next = reg_1_curr;
        reg_2_next = reg_2_curr;
        reg_q_next = reg_quotient;
        reg_r_next = reg_remainder;
        err_flag_next = err_flag;
        pos_next = pos;
        done_flag_next = done_flag;
        next_state = state;
        sign = 0;

        case (state)
            INIT: begin
                done_flag_next = 0;
                if (start) begin
                    reg_1_next = (numerator[DIVIDEND_WIDTH-1] ? ~numerator + 1'b1 : numerator);
                    reg_2_next = (denominator[DIVISOR_WIDTH-1] ? ~denominator + 1'b1 : denominator);
                    reg_q_next = 0;
                    err_flag_next = 0;
                    next_state = CHECK;
                end
            end

            CHECK: begin
                if (reg_2_curr == 0) begin
                    err_flag_next = 1;
                    next_state = DONE;
                end else if (reg_2_curr == 1) begin
                    reg_q_next = reg_1_curr;
                    reg_1_next = 0;
                    next_state = DONE;
                end else if (reg_1_curr >= reg_2_curr) begin
                    pos_next = get_msb(reg_1_curr, (DIVIDENT_WIDTH-1)) - get_msb(reg_2_curr, (DIVISOR_WIDTH-1));
                    next_state = COMPUTE;
                end else begin
                    next_state = DONE;
                end
            end

            COMPUTE: begin
                if ((reg_2_curr << pos) > reg_1_curr) begin
                    pos_next = pos - 1;
                end else begin
                    pos_next = pos;
                end
                reg_q_next = reg_quotient + (1 << pos_next);
                reg_1_next = reg_1_curr - (reg_2_curr << pos_next);
                next_state = CHECK;
            end

            DONE: begin
                sign = numerator[DIVIDEND_WIDTH-1] ^ denominator[DIVISOR_WIDTH-1];
                reg_q_next = sign ? ~reg_quotient + 1'b1 : reg_quotient;
                reg_r_next = numerator[DIVIDEND_WIDTH-1] ? ~reg_1_curr + 1'b1 : reg_1_curr;
                done_flag_next = 1;
                next_state = INIT;
            end

            default: begin
                reg_1_next = 'x;
                reg_2_next = 'x;
                reg_q_next = 'x;
                reg_r_next = 'x;
                err_flag_next = 'x;
                done_flag_next = 'x;
                next_state = INIT;
                pos_next = pos;
            end
        endcase
    end

    assign quotient = reg_quotient;
    assign remainder = reg_remainder;
    assign error = err_flag;
    assign done = done_flag;
endmodule
