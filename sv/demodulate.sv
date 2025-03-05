

module demodulate #(
    parameter DATA_SIZE = 32
)(
    input   logic                   clock,
    input   logic                   reset,

    output  logic                   real_demod_rd_en,
    input   logic                   real_empty,
    input   logic [DATA_SIZE-1:0]   real_din,

    output  logic                   imag_demod_rd_en,
    input   logic                   imag_empty,
    input   logic [DATA_SIZE-1:0]   imag_din,

    output  logic [DATA_SIZE-1:0]   demod_out,
    output  logic                   demod_wr_en_out,
    input   logic                   demod_out_full
);

const logic [DATA_SIZE-1:0] gain = 32'h000002f6;

function logic signed [DATA_SIZE-1:0] DEQUANTIZE(logic signed [DATA_SIZE-1:0] val);
    if (val < 0) begin
        DEQUANTIZE = DATA_SIZE'(-(-val >>> 10));
    end else begin
        DEQUANTIZE = DATA_SIZE'(val >>> 10);
    end
endfunction

// function logic [DATA_WIDTH-1:] DEQUANTIZE(logic [DATA_WIDTH-1:0] v);
//     logic signed [DATA_WIDTH-1:0] temp;

//     temp = $signed(v) + $signed(1 << (QUANT -1));

//     if (temp[DATA_WIDTH-1:0] == 1'b1 && $signed(temp) >= -$signed(1 << QUANT)) begin
//         return 0;
//     end

//     if (temp[DATA_WIDTH-1] == 1'b1) begin
//         temp = $signed(temp) + $signed(1 << (QUANT));
//     end
//     return $signed(temp) >>> $signed(QUANT);
// endfunction


typedef enum logic [2:0] {
    INIT,
    DOT_PRODUCT,
    QARCTAN,
    GET_QARCTAN,
    WRITE
} state_t;
state_t state, next_state;

logic [DATA_SIZE-1:0] real_curr, imag_curr;
logic [DATA_SIZE-1:0] real_curr_c, imag_curr_c;

logic [DATA_SIZE-1:0] real_last, imag_last;
logic [DATA_SIZE-1:0] real_last_c, imag_last_c;

logic [DATA_SIZE-1:0] real_real_product, imag_real_product, real_imag_product, imag_imag_product;
logic [DATA_SIZE-1:0] real_real_product_c, imag_real_product_c, real_imag_product_c, imag_imag_product_c;
logic [DATA_SIZE-1:0] qarctan_real, qarctan_imag;
logic [DATA_SIZE-1:0] demod_temp, demod_temp_c;

logic [DATA_SIZE-1:0] qarctan_output;
logic qarctan_done;
logic start_qarctan;


always_ff @(posedge clock or posedge reset) begin
    if (reset == 1'b1) begin
        state <= INIT;

        real_curr <= '0;
        imag_curr <= '0;
        real_last <= '0;
        imag_last <= '0;

        real_real_product <= '0;
        imag_imag_product <= '0;
        real_imag_product <= '0;
        imag_real_product <= '0;
        demod_temp <= '0;

        //start_qarctan = 1'b0;

    end else begin
        state <= next_state; 
        real_curr <= real_curr_c; 
        imag_curr <= imag_curr_c;
        real_last<= real_last_c;
        imag_last <= imag_last_c;
        real_real_product <= real_real_product_c;
        imag_imag_product <= imag_imag_product_c;
        real_imag_product <= real_imag_product_c;
        imag_real_product <= imag_real_product_c;
        demod_temp <= demod_temp_c;
    end
end

qarctan #(
    .DATA_SIZE(DATA_SIZE)    
)qarctan_inst (
    .clock(clock), 
    .reset(reset),
    .start_signal(start_qarctan),
    .real_(qarctan_real),
    .imag(qarctan_imag),
    .data_out(qarctan_out),
    .done_signal(qarctan_done)
);

always_comb begin
    real_demod_rd_en = 1'b0;
    imag_demod_rd_en = 1'b0;
    demod_wr_en_out = 1'b0;
    real_curr_c = real_curr;
    imag_curr_c = imag_curr;
    real_last_c = real_last;
    imag_last_c = imag_last;
    real_real_product_c = real_real_product;
    imag_imag_product_c = imag_imag_product;
    real_imag_product_c = real_imag_product;
    imag_real_product_c = imag_real_product;
    demod_temp_c = demod_temp;

    //demod_out = demod_temp;

    start_qarctan = 1'b0;

    case(state)

        INIT: begin
            if (real_empty == 1'b0 && imag_empty == 1'b0) begin
                imag_demod_rd_en = 1'b1;
                real_demod_rd_en = 1'b1;
                real_curr_c = real_din;
                imag_curr_c = imag_din;
                real_last_c = real_curr;
                imag_last_c = imag_curr;
                next_state = DOT_PRODUCT;
            end else
                next_state = INIT;
        end

        DOT_PRODUCT: begin 
            real_real_product_c = ($signed(real_last) * $signed(real_curr));
            imag_imag_product_c = (-$signed(imag_last) * $signed(imag_curr));
            real_imag_product_c = ($signed(real_last) * $signed(imag_curr));
            imag_real_product_c = (-$signed(imag_last) * $signed(real_curr));
            next_state = QARCTAN;
        end

        QARCTAN: begin
            qarctan_real = DEQUANTIZE(real_real_product) - DEQUANTIZE(imag_imag_product);
            qarctan_imag = DEQUANTIZE(real_imag_product) + DEQUANTIZE(imag_real_product);
            // Start qarctan 
            start_qarctan = 1'b1;
            next_state = GET_QARCTAN;
        end

        GET_QARCTAN: begin
            if (qarctan_done == 1'b1) begin
                demod_temp_c = ($signed(qarctan_out) * $signed(gain));
                next_state = WRITE;
            end else
                // wait for the qarctan to finish 
                next_state = GET_QARCTAN;
        end

        WRITE: begin
            // Write out demod output
            if (demod_out_full == 1'b0) begin
                demod_wr_en_out = 1'b1;
                demod_out = DEQUANTIZE(demod_temp);
                next_state = INIT;
            end
        end

        default: begin
            demod_wr_en_out = 1'bx;
            demod_out = 'x;
            real_demod_rd_en = 1'bx;
            imag_demod_rd_en = 1'bx;
            real_curr_c = 'x;
            imag_curr_c = 'x;
            real_last_c = 'x;
            imag_last_c = 'x;
            demod_temp_c = 'x;
            real_real_product_c = 'x;
            imag_imag_product_c = 'x;
            real_imag_product_c = 'x;
            imag_real_product_c = 'x;
            start_qarctan = 1'bx;
        end

    endcase
end

endmodule