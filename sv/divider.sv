module divider #(
    parameter DIVIDEND_WIDTH = 32,
    parameter DIVISOR_WIDTH  = 32
) (
    input  logic                         clock,
    input  logic                         reset,
    input  logic                         start,
    input  logic [DIVIDEND_WIDTH-1:0]      dividend,
    input  logic [DIVISOR_WIDTH-1:0]       divisor,
    output logic [DIVIDEND_WIDTH-1:0]      quotient,
    output logic [DIVISOR_WIDTH-1:0]      remainder,
    output logic                         done,
    output logic                         overflow
);

    // Simple state machine with three states
    typedef enum logic [1:0] {
        INIT,
        CALC,
        DONE
    } state_t;
    state_t state, next_state;

    // Registers for the division algorithm
    logic [DIVIDEND_WIDTH-1:0] dividend_reg, dividend_next;
    logic [DIVIDEND_WIDTH-1:0] quotient_reg, quotient_next;
    logic [DIVIDEND_WIDTH-1:0] remainder_reg, remainder_next;
    logic [$clog2(DIVIDEND_WIDTH+1)-1:0] count, count_next;
    logic overflow_reg, overflow_next;

    // Sequential logic: update state and registers
    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
            state         <= INIT;
            dividend_reg  <= '0;
            quotient_reg  <= '0;
            remainder_reg <= '0;
            count         <= '0;
            overflow_reg  <= 1'b0;
        end else begin
            state         <= next_state;
            dividend_reg  <= dividend_next;
            quotient_reg  <= quotient_next;
            remainder_reg <= remainder_next;
            count         <= count_next;
            overflow_reg  <= overflow_next;
        end
    end

    // Combinational logic: determine next state and next register values
    always_comb begin
        // Default assignments (hold current values)
        //next_state      = state;
        dividend_next   = dividend_reg;
        quotient_next   = quotient_reg;
        remainder_next  = remainder_reg;
        count_next      = count;
        overflow_next   = overflow_reg;
        done       = 1'b0;

        case (state)
            INIT: begin
                if (start == 1'b1) begin
                    // Check for division by zero
                    if (divisor == 0) begin
                        overflow_next = 1'b1;
                        quotient_next = '0;
                        remainder_next = '0;
                        next_state = DONE;
                    end else begin
                        overflow_next = 1'b0;
                        dividend_next = dividend;
                        quotient_next = '0;
                        remainder_next = '0;
                        count_next = DIVIDEND_WIDTH;
                        next_state = CALC;
                    end
                end else begin
                    next_state = INIT;
                end
            end

            CALC: begin : calc_block
                // Create a temporary value by concatenating the current remainder and
                // the MSB of the dividend_reg. (This makes temp one bit wider than remainder_reg.)
                logic [DIVIDEND_WIDTH:0] temp;
                temp = {remainder_reg, dividend_reg[DIVIDEND_WIDTH-1]};
                // Shift dividend left by 1 bit for the next iteration.
                dividend_next = dividend_reg << 1;
                // Shift quotient left by 1 bit (to make room for the new bit).
                quotient_next = quotient_reg << 1;
                // Compare temp with divisor. If temp is large enough,
                // subtract the divisor and set the new quotient LSB to 1.
                if (temp >= divisor) begin
                    remainder_next = temp - divisor;
                    quotient_next = quotient_next | 1;
                end else begin
                    remainder_next = temp;
                end
                count_next = count - 1;
                if (count == 1)
                    next_state = DONE;
                else
                    next_state = CALC;
            end

            DONE: begin
                done = 1'b1;
                next_state = INIT;
            end

            default: begin
                next_state = INIT;
            end
        endcase
    end

    // Output assignments
    assign quotient = quotient_reg;
    assign remainder = remainder_reg;
    assign overflow = overflow_reg;

endmodule
