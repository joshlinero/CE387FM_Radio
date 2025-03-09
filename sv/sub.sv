module sub #(
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

    output  logic [DATA_SIZE-1:0] sub_out_din,
    input   logic sub_out_full,
    output  logic sub_out_wr_en
);

typedef enum logic {
    SUB, 
    WRITE
} state_types;
state_types state, next_state;

logic [DATA_SIZE-1:0] dif, dif_c; 

always_ff @(posedge clock or posedge reset) begin
    if (reset == 1'b1) begin
        state <= SUB;
        dif <= '0;
    end else begin
        state <= next_state;
        dif <= dif_c;
    end
end


always_comb begin
    lmr_in_rd_en = 1'b0;
    lpr_in_rd_en = 1'b0;
    sub_out_wr_en = 1'b0;
    next_state = state;
    dif_c = dif;
    sub_out_din = '0;

    case(state)

    SUB: begin
        if (lmr_in_empty == 1'b0 && lpr_in_empty == 1'b0) begin
            lmr_in_rd_en = 1'b1;
            lpr_in_rd_en = 1'b1;
            dif_c = $signed(lpr_in_dout) - $signed(lmr_in_dout);
            next_state = WRITE;
        end else begin
            lmr_in_rd_en = 1'b0;
            lpr_in_rd_en =1'b0;
            dif_c = '0;
            next_state = SUB;
        end
    end

    WRITE: begin
        if (sub_out_full == 1'b0) begin
            sub_out_wr_en = 1'b1;
            sub_out_din = dif;
            next_state = SUB;
        end else begin
            //sub_out_wr_en = 1'b0;
            //sub_out_din = '0;
            next_state = WRITE;
        end
    end

    default: begin
        next_state = SUB;
        lmr_in_rd_en = 1'bx;
        lpr_in_rd_en = 1'bx;
        sub_out_wr_en = 1'bx;
        dif_c = 'X;
        sub_out_din = 'X;
    end
    
    endcase
end

endmodule