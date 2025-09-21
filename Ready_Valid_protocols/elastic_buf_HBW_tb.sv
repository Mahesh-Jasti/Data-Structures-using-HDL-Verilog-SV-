`timescale 1ns/1ps

module elastic_buf_HBW_tb;

    // DUT signals
    reg clk;
    reg rst_n;
    reg in_srdy;
    reg [7:0] in_data;
    wire in_rrdy;
    reg out_rrdy;
    wire out_srdy;
    wire [7:0] out_data;

    // Instantiate DUT
    elastic_buf dut (
        .clk(clk),
        .rst_n(rst_n),
        .in_srdy(in_srdy),
        .in_data(in_data),
        .in_rrdy(in_rrdy),
        .out_rrdy(out_rrdy),
        .out_srdy(out_srdy),
        .out_data(out_data)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;

    // Test sequence
    initial begin
        $display("Starting elastic_buf testbench...");
        rst_n = 0;
        in_srdy = 0;
        in_data = 8'h00;
        out_rrdy = 0;
        #12;
        rst_n = 1;

        // Test 1: Write data when buffer is empty
        @(negedge clk);
        in_srdy = 1;
        in_data = 8'hA5;
        @(negedge clk);
        in_srdy = 0;
        in_data = 8'h00;

        // Test 2: Try to write when buffer is full (should not accept new data)
        @(negedge clk);
        in_srdy = 1;
        in_data = 8'h5A;
        @(negedge clk);
        in_srdy = 0;

        // Test 3: Read data out
        @(negedge clk);
        out_rrdy = 1;
        @(negedge clk);
        out_rrdy = 0;

        // Test 4: Simultaneous read and write
        @(negedge clk);
        in_srdy = 1;
        in_data = 8'h3C;
        out_rrdy = 1;
        @(negedge clk);
        in_srdy = 0;
        out_rrdy = 0;

        // Test 5: Reset during operation
        @(negedge clk);
        in_srdy = 1;
        in_data = 8'hFF;
        @(negedge clk);
        rst_n = 0;
        @(negedge clk);
        rst_n = 1;
        in_srdy = 0;

        // Finish
        #20;
        $display("Testbench completed.");
        $finish;
    end

    // Monitor outputs
    initial begin
        $monitor("T=%0t | rst_n=%b | in_srdy=%b | in_data=%h | in_rrdy=%b | out_rrdy=%b | out_srdy=%b | out_data=%h",
            $time, rst_n, in_srdy, in_data, in_rrdy, out_rrdy, out_srdy, out_data);
    end

endmodule