// optimized this file with git hub copilot to make it unrolled

module fir #(
    parameter TAPS = 32,
    parameter DECIMATION = 8,
    parameter DATA_SIZE = 32,
    parameter logic [0:TAPS-1][DATA_SIZE-1:0] GLOBAL_COEFF = '0,
    parameter UNROLL = 16
) (
    input   logic clock,
    input   logic reset,
    input   logic [DATA_SIZE-1:0] x_in,   
    output   logic x_rd_en,
    input  logic x_empty,
    output  logic y_wr_en,
    input   logic y_out_full,
    output  logic [DATA_SIZE-1:0] y_out 
);

typedef enum logic[2:0] {
    INIT, 
    COMPUTE, 
    WRITE
} state_t;
state_t state, next_state;

logic [0:TAPS-1] [DATA_SIZE-1:0] shift_reg;
logic [0:TAPS-1][DATA_SIZE-1:0] shift_reg_c;
logic [$clog2(DECIMATION)-1:0] decimation_counter, decimation_counter_c;
logic [$clog2(TAPS)-1:0] taps_counter, taps_counter_c;
logic [0:UNROLL-1][DATA_SIZE-1:0] tap_value, tap_value_c;
logic signed [0:UNROLL-1][DATA_SIZE-1:0] product, product_c;
logic [0:UNROLL-1][DATA_SIZE-1:0] y_sum, y_sum_c; 
logic last_cycle, last_cycle_c;
logic [$clog2(TAPS)-1:0] coefficient_counter, coefficient_counter_c;
logic [DATA_SIZE-1:0] total_sum;


function logic signed [DATA_SIZE-1:0] DEQUANTIZE(logic signed [DATA_SIZE-1:0] val);
    if (val < 0) begin
        DEQUANTIZE = DATA_SIZE'(-(-val >>> 10));
    end else begin
        DEQUANTIZE = DATA_SIZE'(val >>> 10);
    end
endfunction

always_ff @(posedge clock or posedge reset) begin
    if (reset == 1'b1) begin
        state <= INIT;       
        product <= '0;
        last_cycle <= '0;
        coefficient_counter <= '0;
        taps_counter <= '0;        
        decimation_counter <= '0;       
        y_sum <= '0;
        tap_value <= '0;
        shift_reg <= '0;

    end else begin
        taps_counter <= taps_counter_c;
        coefficient_counter <= coefficient_counter_c;
        shift_reg <= shift_reg_c;
        state <= next_state;  
        y_sum <= y_sum_c;
        tap_value <= tap_value_c;
        product <= product_c;
        last_cycle <= last_cycle_c;        
        decimation_counter <= decimation_counter_c;

    end
end

always_comb begin
    next_state = state;
    x_rd_en = 1'b0;
    y_wr_en = 1'b0;
    decimation_counter_c = decimation_counter;
    shift_reg_c = shift_reg;
    taps_counter_c = taps_counter;
    y_sum_c = y_sum;
    tap_value_c = tap_value;
    product_c = product;
    last_cycle_c = last_cycle;
    coefficient_counter_c = coefficient_counter;

    case(state)

        INIT: begin
            if (x_empty == 1'b0) begin
                x_rd_en = 1'b1;
                shift_reg_c[1:TAPS-1] = shift_reg[0:TAPS-2];
                shift_reg_c[0] = x_in;
                decimation_counter_c = decimation_counter + 1'b1;

                if (decimation_counter == DECIMATION - 1) begin
                    next_state = COMPUTE;
                    for (int i = 0; i < UNROLL; i++) begin
                        tap_value_c[i] = shift_reg_c[i];
                    end //look sat this line
                    taps_counter_c = taps_counter + UNROLL;
                end else begin
                    next_state = INIT;
                end
            end
            
        end

        COMPUTE: begin
            if (last_cycle == 1'b0) begin
                for (int i = 0; i < UNROLL; i++) begin 
                    product_c[i] = $signed(tap_value[i]) * $signed(GLOBAL_COEFF[TAPS-coefficient_counter-i-1]);
                end

                if (taps_counter != UNROLL) begin
                    for (int i = 0; i < UNROLL; i++) begin
                        y_sum_c[i] = $signed(y_sum[i]) + DEQUANTIZE(product[i]);
                    end
                end

                taps_counter_c = taps_counter + UNROLL;
                coefficient_counter_c = coefficient_counter + UNROLL;

                for (int i = 0; i < UNROLL; i++)
                    tap_value_c[i] = shift_reg[taps_counter+i];

                if (taps_counter == 0) begin
                    last_cycle_c = 1'b1;
                end
            end else begin
                for (int i = 0; i < UNROLL; i++) begin
                    y_sum_c[i] = $signed(y_sum[i]) + DEQUANTIZE(product[i]);
                end //look at this line
                last_cycle_c = 1'b0;
                next_state = WRITE;
            end            
        end

        WRITE: begin
            if (y_out_full == 1'b0) begin
                y_wr_en = 1'b1;
                total_sum = '0;
                for (int i = 0; i < UNROLL; i++) begin
                    total_sum = $signed(total_sum) + $signed(y_sum[i]);
                end
                y_out = total_sum;
                taps_counter_c = '0;
                coefficient_counter_c = '0;
                decimation_counter_c = '0;
                y_sum_c = '0;
                next_state = INIT;
            end
        end

        default: begin
            next_state = INIT;
            x_rd_en = 1'bx;
            y_wr_en = 1'bx;
            y_out = 'x;
            decimation_counter_c = 'x;
            taps_counter_c = 'x;
            y_sum_c = 'x;
            shift_reg_c = 'x;
            product_c = 'x;
            last_cycle_c = 'x;
            coefficient_counter_c = 'x;
            tap_value_c = 'x;
        end
    endcase
end


endmodule





/// original unrolled fir that worked with the testbench


// module fir #(
//     parameter TAPS = 32,
//     parameter DECIMATION = 8,
//     parameter DATA_SIZE = 32,
//     parameter [0:TAPS-1][DATA_SIZE-1:0] GLOBAL_COEFF =
//     '{
//         (32'hfffffffd), (32'hfffffffa), (32'hfffffff4), (32'hffffffed), (32'hffffffe5), (32'hffffffdf), (32'hffffffe2), (32'hfffffff3), 
//         (32'h00000015), (32'h0000004e), (32'h0000009b), (32'h000000f9), (32'h0000015d), (32'h000001be), (32'h0000020e), (32'h00000243), 
//         (32'h00000243), (32'h0000020e), (32'h000001be), (32'h0000015d), (32'h000000f9), (32'h0000009b), (32'h0000004e), (32'h00000015), 
//         (32'hfffffff3), (32'hffffffe2), (32'hffffffdf), (32'hffffffe5), (32'hffffffed), (32'hfffffff4), (32'hfffffffa), (32'hfffffffd)
//     }
// )
// (
//     input  logic                    clock,
//     input  logic                    reset,
    
//     input  logic [DATA_SIZE-1:0]    x_in,
//     output logic                    x_rd_en,
//     input  logic                    x_empty,

//     output logic [DATA_SIZE-1:0]    y_out,
//     input  logic                    y_out_full,
//     output logic                    y_wr_en
// );

// // first test with 	AUDIO_LPR_COEFF_TAPS  to confirm its right
// // parameter logic signed [0:TAPS-1] [DATA_SIZE-1:0] AUDIO_LPR_COEFFS = '{
// // 	32'hfffffffd, 32'hfffffffa, 32'hfffffff4, 32'hffffffed, 32'hffffffe5, 32'hffffffdf, 32'hffffffe2, 32'hfffffff3, 
// // 	32'h00000015, 32'h0000004e, 32'h0000009b, 32'h000000f9, 32'h0000015d, 32'h000001be, 32'h0000020e, 32'h00000243, 
// // 	32'h00000243, 32'h0000020e, 32'h000001be, 32'h0000015d, 32'h000000f9, 32'h0000009b, 32'h0000004e, 32'h00000015, 
// // 	32'hfffffff3, 32'hffffffe2, 32'hffffffdf, 32'hffffffe5, 32'hffffffed, 32'hfffffff4, 32'hfffffffa, 32'hfffffffd
// // };
// // make is global for the fm radio top

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

// logic [0:DATA_SIZE-1][DATA_SIZE-1:0] x, x_c;
// logic [DATA_SIZE-1:0] count;
// logic [DATA_SIZE-1:0] count_c;
// logic [DATA_SIZE-1:0] sum, sum_c, temp_sum, temp_deq;
// logic [DATA_SIZE-1:0] y_out_c;
// logic y_wr_en_c;

// always_ff @( posedge clock or posedge reset ) begin
//     if (reset == 1'b1) begin
//         state <= INIT;
//         x <= '0;
//         y_out <= '0;
//         count <= '0;
//         sum <= '0;
//         y_wr_en <= 1'b0;
//     end else begin
//         x <= x_c;
//         y_out <= y_out_c;
//         count <= count_c;
//         state <= next_state;
//         sum <= sum_c;
//         y_wr_en <= y_wr_en_c;
//     end
// end

// always_comb begin
//     x_c = x;
//     count_c = count;
//     sum_c = '0;
//     temp_sum = '0;
//     x_rd_en = 1'b0;
//     y_wr_en_c = 1'b0;
//     y_out_c = '0;

//     case (state)
//         INIT: begin
//             if (x_empty == 1'b0) begin
//                 x_rd_en = 1'b1;
//                 x_c[1:DATA_SIZE-1] = x[0:DATA_SIZE-2];
//                 x_c[0] = x_in;

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
//             temp_sum = GLOBAL_COEFF[TAPS - count - 1] * x[count];
//             temp_deq = DEQUANTIZE(temp_sum);
//             sum_c = sum + temp_deq;

//             count_c = (count + 1) % TAPS;
//             if (count == TAPS - 1) begin 
//                 next_state = WRITE;
//             end else begin
//                 next_state = COMPUTE;
//             end
//         end

//         WRITE: begin
//             if (y_out_full == 1'b0) begin
//                 y_wr_en_c = 1'b1;
//                 y_out_c = sum;
//                 next_state = INIT;
//             end else begin
//                 next_state = WRITE;
//             end
//         end

//         default: begin
//             next_state = INIT;
//             x_c = 'x;
//             count_c = 'x;
//         end
//     endcase
// end 

// endmodule