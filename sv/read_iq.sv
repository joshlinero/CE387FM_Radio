
module read_iq #(
    parameter DATA_SIZE = 32,
    parameter BYTE_SIZE = 8,
    parameter CHAR_SIZE = 16,
    parameter BITS = 10
)(

    input   logic                           clock,
    input   logic                           reset,

    input   logic [BYTE_SIZE-1:0]           data_in,

    input   logic                           i_out_full,
    input   logic                           q_out_full,
    
    input   logic                           in_empty,

    output  logic                           in_rd_en,
    output  logic                           out_wr_en,

    output  logic [DATA_SIZE-1:0]           i_out,
    output  logic [DATA_SIZE-1:0]           q_out
);

function logic signed [DATA_SIZE-1:0] QUANTIZE(logic signed [DATA_SIZE-1:0] val);
    QUANTIZE = DATA_SIZE'(val << BITS);
endfunction

logic signed [BYTE_SIZE-1:0] i_low, q_low;
logic signed [BYTE_SIZE-1:0] i_low_c, q_low_c;
logic signed [CHAR_SIZE-1:0] i_sample, q_sample;
logic signed [CHAR_SIZE-1:0] i_sample_c, q_sample_c;

typedef enum logic [2:0] {
    READ_I_LOW,   // Read I low byte (IQ[i*4+0])
    READ_I_HIGH,  // Read I high byte (IQ[i*4+1])
    READ_Q_LOW,   // Read Q low byte (IQ[i*4+2])
    READ_Q_HIGH,  // Read Q high byte (IQ[i*4+3])
    WRITE         // Output the quantized sample
} state_t;
state_t state, next_state;

always_ff @(posedge clock or posedge reset) begin
    if (reset == 1'b1) begin
        i_low <= '0;
        q_low <= '0;
        i_sample <= '0;
        q_sample <= '0;
        state <= READ_I_LOW;
    end else begin
        i_low <= i_low_c;
        q_low <= q_low_c;
        i_sample <= i_sample_c;
        q_sample <= q_sample_c;
        state <= next_state;
    end 
end

always_comb begin
    in_rd_en = 1'b0;
    out_wr_en = 1'b0;
    i_low_c = i_low;
    q_low_c = q_low;
    i_sample_c = i_sample;
    q_sample_c = q_sample;
    next_state = state;

    case (state) 
        READ_I_LOW: begin
            if (in_empty == 1'b0) begin
                in_rd_en = 1'b1;
                i_low_c = data_in;
                next_state = READ_I_HIGH;
            end
        end

        READ_I_HIGH: begin
            if (in_empty == 1'b0) begin
                in_rd_en = 1'b1;
                i_sample_c = {data_in, i_low};
                next_state = READ_Q_LOW;
            end
        end

        READ_Q_LOW: begin
            if (in_empty == 1'b0) begin
                in_rd_en = 1'b1;
                q_low_c = data_in;
                next_state = READ_Q_HIGH;
            end
        end

        READ_Q_HIGH: begin
            if (in_empty == 1'b0) begin
                in_rd_en = 1'b1;
                q_sample_c = {data_in, q_low};
                next_state = WRITE;
            end
        end

        WRITE: begin
            if (i_out_full == 1'b0 && q_out_full == 1'b0) begin
                out_wr_en = 1'b1;
                in_rd_en = 1'b0;
                i_out = $signed(QUANTIZE(i_sample));    
                q_out = $signed(QUANTIZE(q_sample));    
                next_state = READ_I_LOW;
            end else begin
                next_state = WRITE;
            end
        end

        default: begin
            i_low_c = 'x;
            q_low_c = 'x;
            i_sample_c = 'x;
            q_sample_c = 'x;
            in_rd_en = 1'bx;
            out_wr_en = 1'bx;
            next_state = READ_I_LOW;
        end
    endcase
end

endmodule
