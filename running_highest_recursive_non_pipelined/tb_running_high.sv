// Testbench for running_high module
`timescale 1ns/1ps

module tb_running_high;
    reg clk;
    reg reset;
    reg [3:0] data_in;
    wire [3:0] high_out;

    // Instantiate the DUT
    running_high uut (
        .clk(clk),
        .reset(reset),
        .data_in(data_in),
        .high_out(high_out)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;

    // Stimulus
    initial begin
        reset = 1;
        data_in = 0;
        #12;
        reset = 0;
        // Apply a sequence of inputs
        repeat(10) begin
            @(posedge clk);
            data_in = $random % 16;
        end
        // Wait and finish
        #50;
        $finish;
    end

    // Monitor output
    initial begin
        $monitor("%0t | reset=%b data_in=%h high_out=%h", $time, reset, data_in, high_out);
    end
endmodule
