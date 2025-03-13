module gain #(
    parameter DATA_SIZE = 32
)
(
    input   logic                           clock,
    input   logic                           reset,

    input   logic signed [DATA_SIZE - 1:0]  volume,

    input   logic signed [DATA_SIZE - 1:0]  in,
    output  logic                           in_rd_en,
    input   logic                           in_empty,

    output  logic signed [DATA_SIZE - 1:0]  gain_out,
    output  logic                           out_wr_en,
    input   logic                           out_full

);



typedef enum logic [1:0] {
    INIT,
    GAIN
} state_types;
state_types state, next_state;

function logic signed [DATA_SIZE-1:0] DEQUANTIZE(logic signed [DATA_SIZE-1:0] val);
    if (val < 0) begin
        DEQUANTIZE = DATA_SIZE'(-(-val >>> 10));
    end else begin
        DEQUANTIZE = DATA_SIZE'(val >>> 10);
    end
endfunction

logic signed [DATA_SIZE-1:0] gain, gain_c;
logic signed [DATA_SIZE-1:0] in_temp, in_temp_c;


always_ff @(posedge clock or posedge reset) begin
    if (reset == 1'b1) begin
        state <= INIT;
        gain <= '0;
        in_temp <= '0;
    end else begin
        state <= next_state;
        gain <= gain_c;
        in_temp <= in_temp_c;
    end
end

always_comb begin
    gain_c = gain;
    next_state = state;
    in_rd_en = 1'b0;
    out_wr_en = 1'b0;
    in_temp_c = in_temp;
    gain_out = '0;

    case (state) 
        INIT: begin
            if (in_empty == 1'b0) begin
                next_state = GAIN;
                in_rd_en = 1'b1;
                in_temp_c = in;
            end else begin
                next_state = INIT;
            end
        end

        GAIN: begin
            if (out_full == 1'b0) begin
                gain_out = DEQUANTIZE(in_temp * volume) << 4;
                //gain_out = in_temp << 4;
                in_temp_c = '0;
                out_wr_en = 1'b1;
                next_state = INIT;
            end else begin
                next_state = GAIN;
            end
        end

        default: begin
            gain_out = 'x;
            in_rd_en = 1'bx;
            out_wr_en = 1'bx;
            gain_c = 'x;
            in_temp_c = 'x;
        end
    endcase

end


endmodule