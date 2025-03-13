
// optimized this file with git hub copilot to make it unrolled


module fir_complex #(
    parameter TAPS = 20,
    parameter UNROLL = 4,
    parameter DATA_SIZE = 32
) (
    input  logic        clock,
    input  logic        reset,

    input  logic [DATA_SIZE-1:0] i_in,
    input  logic [DATA_SIZE-1:0] q_in,

    output logic        fircmplx_i_rd_en,
    output logic        fircmplx_q_rd_en,

    input  logic        fircmplx_i_empty,
    input  logic        fircmplx_q_empty,

    output logic [DATA_SIZE-1:0] out_real_cmplx,
    output logic        real_wr_en_cmplx,
    input  logic        real_full_cmplx,

    output logic [DATA_SIZE-1:0] out_imag_cmplx,
    output logic        imag_wr_en_cmplx,
    input  logic        imag_full_cmplx


);

parameter logic signed [0:TAPS-1] [DATA_SIZE-1:0] CHANNEL_COEFFS_REAL = '{
    32'h00000001, 32'h00000008, 32'hfffffff3, 32'h00000009, 32'h0000000b, 32'hffffffd3, 32'h00000045, 32'hffffffd3, 
    32'hffffffb1, 32'h00000257, 32'h00000257, 32'hffffffb1, 32'hffffffd3, 32'h00000045, 32'hffffffd3, 32'h0000000b, 
    32'h00000009, 32'hfffffff3, 32'h00000008, 32'h00000001};

parameter logic signed [0:TAPS-1] [DATA_SIZE-1:0]  CHANNEL_COEFFS_IMAG = '{
	32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 
	32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 
	32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000};

function logic signed [DATA_SIZE-1:0] DEQUANTIZE(logic signed [DATA_SIZE-1:0] val);
    if (val < 0) begin
        DEQUANTIZE = DATA_SIZE'(-(-val >>> 10));
    end else begin
        DEQUANTIZE = DATA_SIZE'(val >>> 10);
    end
endfunction


typedef enum logic[2:0] {
    INIT, 
    COMPUTE, 
    WRITE
} state_t;
state_t state, next_state;


logic [0:TAPS-1] [DATA_SIZE-1:0] realshift_reg;
logic [0:TAPS-1] [DATA_SIZE-1:0] realshift_reg_c;
logic [0:TAPS-1] [DATA_SIZE-1:0] imagshift_reg;
logic [0:TAPS-1] [DATA_SIZE-1:0] imagshift_reg_c;
logic [$clog2(TAPS)-1:0] taps_counter, taps_counter_c; // Always going to need 5 bits
logic [0:UNROLL-1][DATA_SIZE-1:0] yreal_sum, yreal_sum_c; 
logic [0:UNROLL-1][DATA_SIZE-1:0] yimag_sum, yimag_sum_c;

// Tap values
logic [0:UNROLL-1][DATA_SIZE-1:0] realtap_value, realtap_value_c;
logic [0:UNROLL-1][DATA_SIZE-1:0] imagtap_value, imagtap_value_c;

// Registers to hold product value from multiplication to accumulate stage
logic signed [0:UNROLL-1][DATA_SIZE*2-1:0] real_product, real_product_c;
logic signed [0:UNROLL-1][DATA_SIZE*2-1:0] imag_product, imag_product_c;
logic signed [0:UNROLL-1][DATA_SIZE*2-1:0] realimag_product, realimag_product_c;
logic signed [0:UNROLL-1][DATA_SIZE*2-1:0] imagreal_product, imagreal_product_c;

// Last cycle flag to indicate when we should be doing the last accumulation for the MAC pipeline
logic last_cycle, last_cycle_c;

// Total sum to sum up all the partial y_sums
logic [DATA_SIZE-1:0] total_realsum, total_imagsum;

always_ff @(posedge clock or posedge reset) begin
    if (reset == 1'b1) begin
        state <= INIT;     
        taps_counter <= '0;
        yreal_sum <= '0;
        imag_product <= '0;
        realimag_product <= '0;
        realshift_reg <= '0;;
        imagshift_reg <= '0;        
        yimag_sum <= '0;
        realtap_value <= '0;
        imagreal_product <= '0;
        imagtap_value <= '0;
        real_product <= '0;        
        last_cycle <= '0;


    end else begin
        state <= next_state;    
        yimag_sum <= yimag_sum_c;
        realtap_value <= realtap_value_c;
        imagshift_reg <= imagshift_reg_c;
        taps_counter <= taps_counter_c;       
        real_product <= real_product_c;
        last_cycle <= last_cycle_c;
        imag_product <= imag_product_c;
        realimag_product <= realimag_product_c;
        realshift_reg <= realshift_reg_c;
        imagreal_product <= imagreal_product_c;
        yreal_sum <= yreal_sum_c;
    imagtap_value <= imagtap_value_c;


    end
end

always_comb begin
    next_state = state;
    fircmplx_q_rd_en = 1'b0;
    fircmplx_i_rd_en = 1'b0;   
    yreal_sum_c = yreal_sum;
    yimag_sum_c = yimag_sum;
    real_wr_en_cmplx = 1'b0;
    imag_wr_en_cmplx = 1'b0;    
    realimag_product_c = realimag_product;
    imagreal_product_c = imagreal_product;
    realshift_reg_c = realshift_reg;
    imagshift_reg_c = imagshift_reg;   
    realtap_value_c = realtap_value;
    imagtap_value_c = imagtap_value;
    taps_counter_c = taps_counter;

    real_product_c = real_product;
    imag_product_c = imag_product;
    last_cycle_c = last_cycle;
    out_real_cmplx = '0;
    out_imag_cmplx = '0;

    case(state)

        INIT: begin
            if (fircmplx_q_empty == 1'b0 && fircmplx_i_empty == 1'b0) begin
                fircmplx_q_rd_en = 1'b1;
                fircmplx_i_rd_en = 1'b1;

                realshift_reg_c[1:TAPS-1] = realshift_reg[0:TAPS-2];
                realshift_reg_c[0] = i_in;
                imagshift_reg_c[1:TAPS-1] = imagshift_reg[0:TAPS-2];
                imagshift_reg_c[0] = q_in;

                next_state = COMPUTE;
                for (int i = 0; i < UNROLL; i++) begin
                    realtap_value_c[i] = realshift_reg_c[i];
                    imagtap_value_c[i] = imagshift_reg_c[i];
                end
                taps_counter_c = taps_counter + UNROLL;
            end
        end

        COMPUTE: begin
            if (last_cycle == 1'b0) begin
                for (int i = 0; i < UNROLL; i++) begin
                    real_product_c[i] = $signed(realtap_value[i]) * $signed(CHANNEL_COEFFS_REAL[taps_counter-UNROLL+i]);
                    imag_product_c[i] = $signed(imagtap_value[i]) * $signed(CHANNEL_COEFFS_IMAG[taps_counter-UNROLL+i]);

                    realimag_product_c[i] = $signed(CHANNEL_COEFFS_REAL[taps_counter-UNROLL+i]) * $signed(imagtap_value[i]);
                    imagreal_product_c[i] = $signed(CHANNEL_COEFFS_IMAG[taps_counter-UNROLL+i]) * $signed(realtap_value[i]);
                end

                if (taps_counter != UNROLL) begin
                    for (int i = 0; i < UNROLL; i++) begin
                        yreal_sum_c[i] = $signed(yreal_sum[i]) + DEQUANTIZE($signed(real_product[i]) - $signed(imag_product[i]));
                        yimag_sum_c[i] = $signed(yimag_sum[i]) + DEQUANTIZE($signed(realimag_product[i]) - $signed(imagreal_product[i]));
                    end
                end
                taps_counter_c = taps_counter + UNROLL;

                for (int i = 0; i < UNROLL; i++) begin
                    realtap_value_c[i] = realshift_reg[taps_counter+i];
                    imagtap_value_c[i] = imagshift_reg[taps_counter+i];
                end
                if (taps_counter == TAPS) begin
                    last_cycle_c = 1'b1;
                end

            end else begin

                for (int i = 0; i < UNROLL; i++) begin
                    yreal_sum_c[i] = $signed(yreal_sum[i]) + DEQUANTIZE($signed(real_product[i]) - $signed(imag_product[i]));
                    yimag_sum_c[i] = $signed(yimag_sum[i]) + DEQUANTIZE($signed(realimag_product[i]) - $signed(imagreal_product[i]));
                end

                last_cycle_c = 1'b0;
                next_state = WRITE;
            end
        end

        WRITE: begin
            if (real_full_cmplx == 1'b0 && imag_full_cmplx == 1'b0) begin
                real_wr_en_cmplx = 1'b1;
                imag_wr_en_cmplx = 1'b1;
                total_realsum = '0;
                total_imagsum = '0;

                for (int i = 0; i < UNROLL; i++) begin
                    total_realsum = $signed(total_realsum) + $signed(yreal_sum[i]);
                    total_imagsum = $signed(total_imagsum) + $signed(yimag_sum[i]);
                end

                out_real_cmplx = total_realsum;
                out_imag_cmplx = total_imagsum;
                taps_counter_c = '0;
                yreal_sum_c = '0;
                yimag_sum_c = '0;
                next_state = INIT;
            end
        end

        default: begin
            next_state = INIT;
            fircmplx_q_rd_en = 1'bx;            
            realtap_value_c = 'x;
            imag_product_c = 'x;
            realimag_product_c = 'x;           
            imagtap_value_c = 'x;
            imagreal_product_c = 'x;
            last_cycle_c = 'x;
            realshift_reg_c = 'x;
            yimag_sum_c = 'x;            
            fircmplx_i_rd_en = 1'bx;
            real_wr_en_cmplx = 1'bx;           
            out_imag_cmplx = 'x;
            taps_counter_c = 'x;
            yreal_sum_c = 'x;
            imag_wr_en_cmplx = 1'bx;
            out_real_cmplx = 'x;            
            real_product_c = 'x;


            imagshift_reg_c = 'x;
        end
    endcase
end


endmodule



// original fir complex that works with the tb


// module fir_complex# (
//     parameter TAPS = 20,
//     parameter DECIMATION = 1,
//     parameter DATA_SIZE = 32
// )
// (
//     input  logic        clock,
//     input  logic        reset,

//     input  logic [DATA_SIZE-1:0] i_in,
//     input  logic [DATA_SIZE-1:0] q_in,

//     output logic        fircmplx_i_rd_en,
//     output logic        fircmplx_q_rd_en,

//     input  logic        fircmplx_i_empty,
//     input  logic        fircmplx_q_empty,

//     output logic [DATA_SIZE-1:0] out_real_cmplx,
//     output logic        real_wr_en_cmplx,
//     input  logic        real_full_cmplx,

//     output logic [DATA_SIZE-1:0] out_imag_cmplx,
//     output logic        imag_wr_en_cmplx,
//     input  logic        imag_full_cmplx
// );


// parameter logic signed [0:TAPS-1] [DATA_SIZE-1:0] CHANNEL_COEFFS_REAL = '{
//     32'h00000001, 32'h00000008, 32'hfffffff3, 32'h00000009, 32'h0000000b, 32'hffffffd3, 32'h00000045, 32'hffffffd3, 
//     32'hffffffb1, 32'h00000257, 32'h00000257, 32'hffffffb1, 32'hffffffd3, 32'h00000045, 32'hffffffd3, 32'h0000000b, 
//     32'h00000009, 32'hfffffff3, 32'h00000008, 32'h00000001
// };

// parameter logic signed [0:TAPS-1] [DATA_SIZE-1:0]  CHANNEL_COEFFS_IMAG = '{
//     32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 
//     32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000, 
//     32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000
// };


// typedef enum logic[2:0] {
//     INIT, 
//     COMPUTE, 
//     WRITE
// } state_t;
// state_t state, next_state;

// function logic signed [DATA_SIZE-1:0] DEQUANTIZE(logic signed [DATA_SIZE-1:0] val);
//     if (val < 0) begin
//         DEQUANTIZE = DATA_SIZE'(-(-val >>> 10));
//     end else begin
//         DEQUANTIZE = DATA_SIZE'(val >>> 10);
//     end
// endfunction


// logic [0:TAPS-1][DATA_SIZE-1:0] x_real, x_real_c;
// logic [0:TAPS-1][DATA_SIZE-1:0] x_imag, x_imag_c;
// logic [DATA_SIZE-1:0] count; 
// logic [DATA_SIZE-1:0] count_c;
// logic [DATA_SIZE-1:0] sum_real, sum_real_c;
// logic [DATA_SIZE-1:0] sum_imag, sum_imag_c;


// always_ff @( posedge clock or posedge reset ) begin 
//     if (reset == 1'b1) begin
//         x_real <= '0;
//         x_imag <= '0;

//         count <= '0;
//         state <= INIT;
//         sum_real <= '0;
//         sum_imag <= '0;

//     end else begin
//         x_real <= x_real_c;
//         x_imag <= x_imag_c;

//         count <= count_c;
//         state <= next_state;
//         sum_real <= sum_real_c;
//         sum_imag <= sum_imag_c;
//     end
// end

// always_comb begin
//     x_real_c = x_real;
//     x_imag_c = x_imag;
//     sum_real_c = sum_real;
//     sum_imag_c = sum_imag;
//     count_c = count;
//     fircmplx_i_rd_en = 1'b0;
//     fircmplx_q_rd_en = 1'b0;
//     real_wr_en_cmplx = 1'b0;
//     imag_wr_en_cmplx = 1'b0;
//     out_real_cmplx = '0;
//     out_imag_cmplx = '0;

//     case (state)
//         INIT: begin
//             sum_real_c = '0;
//             sum_imag_c = '0;

//             if (fircmplx_i_empty == 1'b0 && fircmplx_q_empty == 1'b0) begin
//                 fircmplx_i_rd_en = 1'b1;
//                 fircmplx_q_rd_en = 1'b1;
//                 x_real_c[1:TAPS-1] = x_real[0:TAPS-2];
//                 x_real_c[0] = i_in;

//                 x_imag_c[1:TAPS-1] = x_imag[0:TAPS-2];
//                 x_imag_c[0] = q_in;
                
//                 count_c = (count + 1) % DECIMATION;

//                 if (count == DECIMATION - 1) begin
//                     next_state = COMPUTE;
//                 end else begin
//                     next_state = INIT;
//                 end
//             end else begin
//                 next_state = INIT;
//             end
//         end

//         COMPUTE: begin
//             sum_real_c = sum_real + DEQUANTIZE((CHANNEL_COEFFS_REAL[count] * x_real[count]) - (CHANNEL_COEFFS_IMAG[count] * x_imag));
//             sum_imag_c = sum_imag + DEQUANTIZE((CHANNEL_COEFFS_REAL[count] * x_imag[count]) - (CHANNEL_COEFFS_IMAG[count] * x_real));

//             count_c = (count + 1) % TAPS;
//             if (count == TAPS - 1) begin
//                 next_state = WRITE;
//             end else begin
//                 next_state = COMPUTE;
//             end
//         end

//         WRITE: begin
//             if (imag_full_cmplx == 1'b0 && real_full_cmplx == 1'b0) begin
//                 real_wr_en_cmplx = 1'b1;
//                 imag_wr_en_cmplx = 1'b1;
//                 out_real_cmplx = sum_real;
//                 out_imag_cmplx = sum_imag;
//                 next_state = INIT;
//             end else begin
//                 next_state = WRITE;
//             end
//         end

//         default: begin
//             next_state = INIT;
//             x_real_c = 'x;
//             x_imag_c = 'x;
//             count_c = 'x;
//         end
//     endcase
// end

// endmodule