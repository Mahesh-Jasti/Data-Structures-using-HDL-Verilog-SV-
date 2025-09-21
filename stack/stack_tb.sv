`timescale 1ns/1ps // Set time unit and precision
module stack_tb; // Testbench module
    parameter SIZE = 8; // Stack size parameter
    reg clk; // Clock signal
    reg rst_n; // Active-low reset
    reg push; // Push control signal
    reg pop; // Pop control signal
    reg [31:0] data_in; // Data input for stack
    wire [31:0] data_out; // Data output from stack
    wire ready; // Ready signal from stack
    wire valid; // Valid signal from stack

    // Instantiate the stack module
    stack #(SIZE) uut (
        .clk(clk), // Connect clock
        .rst_n(rst_n), // Connect reset
        .push(push), // Connect push
        .data_in(data_in), // Connect data input
        .pop(pop), // Connect pop
        .data_out(data_out), // Connect data output
        .ready(ready), // Connect ready
        .valid(valid) // Connect valid
    );

    // Clock generation
    initial clk = 0; // Initialize clock
    always #5 clk = ~clk; // Toggle clock every 5ns

    initial begin // Test sequence
        $dumpfile("dump.vcd"); $dumpvars; // Enable waveform dump
        $display("Starting stack testbench..."); // Print start message
        rst_n = 0; // Assert reset
        push = 0; // Deassert push
        pop = 0; // Deassert pop
        data_in = 0; // Clear data input
        #12; // Wait for reset
        rst_n = 1; // Deassert reset
        #10; // Wait before starting

        // Push values onto the stack
        repeat (SIZE) begin // Loop to push SIZE values
            @(negedge clk); // Wait for clock edge
            push = 1; // Assert push
            data_in = $random; // Provide random data
            pop = 0; // Deassert pop
            @(negedge clk); // Wait for clock edge
            push = 0; // Deassert push
            $display("Pushed: %0d, ready: %b, valid: %b", data_in, ready, valid); // Print status
        end

        // Pop values from the stack
        repeat (SIZE) begin // Loop to pop SIZE values
            @(negedge clk); // Wait for clock edge
            pop = 1; // Assert pop
            push = 0; // Deassert push
            @(negedge clk); // Wait for clock edge
            pop = 0; // Deassert pop
            $display("Popped: %0d, ready: %b, valid: %b", data_out, ready, valid); // Print status
        end

        // Test underflow
        @(negedge clk); // Wait for clock edge
        pop = 1; // Assert pop
        @(negedge clk); // Wait for clock edge
        pop = 0; // Deassert pop
        $display("Underflow test, data_out: %0d, valid: %b", data_out, valid); // Print underflow status

        // Test overflow
        repeat (SIZE+2) begin // Loop to push beyond stack size
            @(negedge clk); // Wait for clock edge
            push = 1; // Assert push
            data_in = $random; // Provide random data
            pop = 0; // Deassert pop
            @(negedge clk); // Wait for clock edge
            push = 0; // Deassert push
        end
        $display("Overflow test, ready: %b", ready); // Print overflow status

        $finish; // End simulation
    end
endmodule // End of testbench module
