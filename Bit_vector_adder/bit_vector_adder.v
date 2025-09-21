module bit_vector_adder_recursion #(
    parameter VECTOR_SIZE = 16
)(
    input wire [VECTOR_SIZE-1:0] vector,
    output wire [$clog2(VECTOR_SIZE):0] sum
);

    generate
        if(VECTOR_SIZE == 2) begin
            assign sum = vector[0] + vector[1];
        end
        else begin
            localparam HALF = VECTOR_SIZE/2;
            localparam SUM_WIDTH = $clog2(HALF) + 1;

            wire [SUM_WIDTH-1:0] sum_msb, sum_lsb;

            bit_vector_adder_recursion #(
                .VECTOR_SIZE(HALF)
            ) bit_vector_adder_recursion_msb(
                .vector(vector[VECTOR_SIZE-1:HALF]),
                .sum(sum_msb)
            );

            bit_vector_adder_recursion #(
                .VECTOR_SIZE(HALF)
            ) bit_vector_adder_recursion_lsb(
                .vector(vector[HALF-1:0]),
                .sum(sum_lsb)
            );

            assign sum = sum_msb + sum_lsb;
        end
    endgenerate

endmodule

module bit_vector_adder_for_loop #(
    parameter VECTOR_SIZE = 16
)(
    input wire [VECTOR_SIZE-1:0] vector,
    output wire [$clog2(VECTOR_SIZE):0] sum
);

    localparam NUM_LEVELS = $clog2(VECTOR_SIZE);

    wire [$clog2(VECTOR_SIZE):0] sum_level [NUM_LEVELS:0][VECTOR_SIZE-1:0];    // big vector -- wasted space

    /*generate
        genvar i;
        for(i=0; i<VECTOR_SIZE; i=i+1) begin : LEVEL_0
            assign sum_level[0][i] = vector[i];
        end
    endgenerate*/

    generate
        genvar j,k;
        for(j=0; j<=NUM_LEVELS; j=j+1) begin : LEVELS
            for(k=0; k<(VECTOR_SIZE >> j); k=k+1) begin
                if(j == 0) begin
                    assign sum_level[0][k] = vector[k];
                end
                else begin
                    assign sum_level[j][k] = sum_level[j-1][2*k] + sum_level[j-1][2*k+1];
                end
            end
        end
    endgenerate

    assign sum = sum_level[NUM_LEVELS][0];

endmodule

module bit_vector_adder #(
    parameter VECTOR_SIZE = 16
)(
    input wire [VECTOR_SIZE-1:0] vector,
    output wire [$clog2(VECTOR_SIZE):0] sum_recursion,
    output wire [$clog2(VECTOR_SIZE):0] sum_for_loop
);

    bit_vector_adder_recursion #(
        .VECTOR_SIZE(VECTOR_SIZE)
    ) bit_vector_adder_recursion_inst (
        .vector(vector),
        .sum(sum_recursion)
    );

    bit_vector_adder_for_loop #(
        .VECTOR_SIZE(VECTOR_SIZE)
    ) bit_vector_adder_for_loop_inst (
        .vector(vector),
        .sum(sum_for_loop)
    );

endmodule