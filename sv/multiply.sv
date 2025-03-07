module multiply #(
    parameter DATA_SIZE = 32
)
(
    input   logic                           clock,
    input   logic                           reset,

    input   logic signed [DATA_SIZE - 1:0]  x,
    output  logic                           x_in_rd_en,
    input   logic                           x_in_empty,

    input   logic signed [DATA_SIZE - 1:0]  y,
    output  logic                           y_in_rd_en,
    input   logic                           y_in_empty,

    output  logic signed [DATA_SIZE - 1:0]  mult_out,
    output  logic                           out_wr_en,
    input   logic                           out_full

);



typedef enum logic [1:0] {
    INIT,
    MULTIPLY,
    WRITE
} state_types;
state_types state, next_state;

function logic signed [DATA_SIZE-1:0] DEQUANTIZE(logic signed [DATA_SIZE-1:0] val);
    if (val < 0) begin
        DEQUANTIZE = DATA_SIZE'(-(-val >>> 10));
    end else begin
        DEQUANTIZE = DATA_SIZE'(val >>> 10);
    end
endfunction

logic signed [DATA_SIZE-1:0] mult, mult_c;
logic signed [DATA_SIZE-1:0] x_temp, x_temp_c, y_temp, y_temp_c;


always_ff @(posedge clock or posedge reset) begin
    if (reset == 1'b1) begin
        state <= INIT;
        mult <= '0;
        y_temp <= '0;
        x_temp <= '0;
    end else begin
        state <= next_state;
        mult <= mult_c;
        x_temp <= x_temp_c;
        y_temp <= y_temp_c;
    end
end

always_comb begin
    mult_c = mult;
    next_state = state;
    x_in_rd_en = 1'b0;
    y_in_rd_en = 1'b0;
    out_wr_en = 1'b0;
    x_temp_c = '0;
    y_temp_c = '0;
    mult_out = '0;

    case (state) 
        INIT: begin
            if (x_in_empty == 1'b0 && y_in_empty == 1'b0) begin
                next_state = MULTIPLY;
                x_in_rd_en = 1'b1;
                y_in_rd_en = 1'b1;
                x_temp_c = x;
                y_temp_c = y;
            end else begin
                next_state = INIT;
            end
        end

        MULTIPLY: begin
            mult_c = $signed(x_temp) * $signed(y_temp);
            next_state = WRITE;
        end

        WRITE: begin
            if (out_full == 1'b0) begin
                mult_out = DEQUANTIZE(mult);
                out_wr_en = 1'b1;
                next_state = INIT;
            end else 
                next_state = WRITE;
        end

        default: begin
            mult_out = 'x;
            x_in_rd_en = 1'bx;
            y_in_rd_en = 1'bx;
            out_wr_en = 1'bx;
            mult_c = 'x;
            x_temp_c = 'x;
            y_temp_c = 'x;
        end
    endcase

end


endmodule