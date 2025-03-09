module add #(
    parameter DATA_SIZE = 32
)(
    input   logic clock,
    input   logic reset,

    input   logic [DATA_SIZE-1:0] lmr_in_dout,   
    input   logic lmr_in_empty,
    output  logic lmr_in_rd_en,

    input   logic [DATA_SIZE-1:0] lpr_in_dout,   
    input   logic lpr_in_empty,
    output  logic lpr_in_rd_en,

    output  logic [DATA_SIZE-1:0] add_out_din,
    input   logic add_out_full,
    output  logic add_out_wr_en
);

typedef enum logic {
    ADD, 
    WRITE
} state_types;
state_types state, next_state;

logic [DATA_SIZE-1:0] sum, sum_c; 

always_ff @(posedge clock or posedge reset) begin
    if (reset == 1'b1) begin
        state <= ADD;
        sum <= '0;
    end else begin
        state <= next_state;
        sum <= sum_c;
    end
end


always_comb begin
    lmr_in_rd_en = 1'b0;
    lpr_in_rd_en = 1'b0;
    add_out_wr_en = 1'b0;
    next_state = state;
    sum_c = sum;
    add_out_din = '0;

    case(state)

    ADD: begin
        if (lmr_in_empty == 1'b0 && lpr_in_empty == 1'b0) begin
            lmr_in_rd_en = 1'b1;
            lpr_in_rd_en = 1'b1;
            sum_c = $signed(lmr_in_dout) + $signed(lpr_in_dout);
            next_state = WRITE;
        end else begin
            lmr_in_rd_en = 1'b0;
            lpr_in_rd_en =1'b0;
            sum_c = '0;
            next_state = ADD;
        end
    end

    WRITE: begin
        if (add_out_full == 1'b0) begin
            add_out_wr_en = 1'b1;
            add_out_din = sum;
            next_state = ADD;
        end else begin
            //add_out_wr_en = 1'b0;
            //add_out_din = '0;
            next_state = WRITE;
        end
    end

    default: begin
        next_state = ADD;
        lmr_in_rd_en = 1'bx;
        lpr_in_rd_en = 1'bx;
        add_out_wr_en = 1'bx;
        sum_c = 'X;
        add_out_din = 'X;
    end
    
    endcase
end

endmodule