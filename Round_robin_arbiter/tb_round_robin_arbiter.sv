// SystemVerilog testbench for round_robin_arbiter
`timescale 1ns/1ps

module tb_round_robin_arbiter;
    parameter WIDTH = 8;
    reg clk;
    reg reset;
    reg [WIDTH-1:0] req_vector;
    wire [$clog2(WIDTH)-1:0] grant_idx_recursion;
    wire grant_valid_recursion;
    wire [$clog2(WIDTH)-1:0] grant_idx_for_loop;
    wire grant_valid_for_loop;

    // Instantiate the DUT
    round_robin_arbiter #(.WIDTH(WIDTH)) dut (
        .clk(clk),
        .reset(reset),
        .req_vector(req_vector),
        .grant_idx_recursion(grant_idx_recursion),
        .grant_valid_recursion(grant_valid_recursion),
        .grant_idx_for_loop(grant_idx_for_loop),
        .grant_valid_for_loop(grant_valid_for_loop)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;

    // Test sequence
    initial begin
    $dumpfile("tb_round_robin_arbiter.vcd");
    $dumpvars(0, tb_round_robin_arbiter);
    $display("Starting testbench...");
        reset = 1;
        req_vector = 0;
        #12;
        reset = 0;
        // Test 1: Single request
        req_vector = 8'b0000_0001;
        #10;
        req_vector = 8'b0000_0010;
        #10;
        req_vector = 8'b0000_0100;
        #10;
        req_vector = 8'b0000_1000;
        #10;
        // Test 2: Multiple requests
        req_vector = 8'b0000_1111;
        #10;
        req_vector = 8'b1111_0000;
        #10;
        req_vector = 8'b1010_1010;
        #10;
        // Test 3: No requests
        req_vector = 8'b0000_0000;
        #10;
        // Test 4: All requests
        req_vector = 8'b1111_1111;
        #10;
        // End simulation
        $display("Testbench completed.");
        $finish;
    end

    // Monitor outputs
    initial begin
        $monitor("%0t | reset=%b req_vector=%b | rec: valid=%b idx=%0d | for: valid=%b idx=%0d",
            $time, reset, req_vector,
            grant_valid_recursion, grant_idx_recursion,
            grant_valid_for_loop, grant_idx_for_loop);
    end
endmodule
