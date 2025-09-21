`timescale 1ns/1ps

module bit_vector_adder_tb;
    parameter VECTOR_SIZE = 16;
    reg [VECTOR_SIZE-1:0] vector;
    wire [$clog2(VECTOR_SIZE):0] sum_recursion;
    wire [$clog2(VECTOR_SIZE):0] sum_for_loop;

    // Instantiate the DUT
    bit_vector_adder #(
        .VECTOR_SIZE(VECTOR_SIZE)
    ) dut (
        .vector(vector),
        .sum_recursion(sum_recursion),
        .sum_for_loop(sum_for_loop)
    );

    initial begin
        $dumpfile("bit_vector_adder_tb.vcd");
        $dumpvars(0, bit_vector_adder_tb);

        // Test 1: All zeros
        vector = 0;
        #10;
        
        // Test 2: All ones
        vector = {VECTOR_SIZE{1'b1}};
        #10;

        // Test 3: Alternating bits
        vector = 16'b1010101010101010;
        #10;
        vector = 16'b0101010101010101;
        #10;

        // Test 4: Single bit set
        vector = 16'b0000000000000001;
        #10;
        vector = 16'b1000000000000000;
        #10;

        // Test 5: Random value
        vector = 16'b0011001100110011;
        #10;

        $finish;
    end
endmodule
