`timescale 1ns/1ps // Set simulation time units and precision

module priority_matrix_tb; // Testbench module declaration

    parameter N = 3; // Matrix size parameter

    reg clk; // Clock signal
    reg rst_n; // Active-low reset signal
    reg [N-1:0] matrix_in [N-1:0]; // Input matrix for DUT
    reg [N-1:0] req; // Request vector for DUT
    wire valid_gnt; // Grant valid output from DUT
    wire [N-1:0] gnt; // Grant vector output from DUT

    // Instantiate the DUT (Device Under Test)
    priority_matrix #(.N(N)) dut (
        .clk(clk), // Connect clock
        .rst_n(rst_n), // Connect reset
        .matrix_in(matrix_in), // Connect input matrix
        .req(req), // Connect request vector
        .valid_gnt(valid_gnt), // Connect valid grant output
        .gnt(gnt) // Connect grant vector output
    );

    // Clock generation: toggle clk every 5ns
    initial clk = 0; // Initialize clock to 0
    always #5 clk = ~clk; // Toggle clock every 5ns

    // Test sequence
    initial begin
        $dumpfile("dump.vcd"); $dumpvars; // Enable waveform dump
        // Initialize inputs
        rst_n = 0; // Assert reset
        req = 0; // Clear request vector
        for (int i = 0; i < N; i++) begin // Loop over matrix rows
            for (int j = 0; j < N; j++) begin // Loop over matrix columns
                matrix_in[i][j] = 0; // Clear matrix input
            end
        end

        // Reset
        #12; // Wait 12ns
        rst_n = 1; // Deassert reset

        // Load matrix
        matrix_in[0] = 3'b110; // Set row 0 of matrix
        matrix_in[1] = 3'b000; // Set row 1 of matrix
        matrix_in[2] = 3'b010; // Set row 2 of matrix

        // Print matrix values after loading
        $display("Matrix loaded:"); // Display message
        for (int i = 0; i < N; i++) begin // Loop over rows
            $write("Row %0d: ", i); // Print row index
            for (int j = 0; j < N; j++) begin // Loop over columns
                $write("%b ", matrix_in[i][j]); // Print matrix value
            end
            $write("\n"); // Newline after each row
        end

        // Request pattern 1
        req = 3'b110; // Set request vector
        #20; // Wait 20ns

        // Print matrix values after REQ_COMPUTE
        $display("Matrix after REQ_COMPUTE (req = 3'b110): %0t",$time); // Display message with time
        for (int i = 0; i < N; i++) begin // Loop over rows
            $write("Row %0d: ", i); // Print row index
            for (int j = 0; j < N; j++) begin // Loop over columns
                $write("%b ", dut.matrix[i][j]); // Print DUT matrix value
            end
            $write("\n"); // Newline after each row
        end

        // Request pattern 2
        req = 3'b100; // Set request vector
        #30; // Wait 30ns

        // Print matrix values after REQ_COMPUTE
        $display("Matrix after REQ_COMPUTE (req = 3'b100): %0t",$time); // Display message with time
        for (int i = 0; i < N; i++) begin // Loop over rows
            $write("Row %0d: ", i); // Print row index
            for (int j = 0; j < N; j++) begin // Loop over columns
                $write("%b ", dut.matrix[i][j]); // Print DUT matrix value
            end
            $write("\n"); // Newline after each row
        end

        // Request pattern 3
        req = 3'b010; // Set request vector
        #30; // Wait 30ns

        // Print matrix values after REQ_COMPUTE
        $display("Matrix after REQ_COMPUTE (req = 3'b101): %0t",$time); // Display message with time
        for (int i = 0; i < N; i++) begin // Loop over rows
            $write("Row %0d: ", i); // Print row index
            for (int j = 0; j < N; j++) begin // Loop over columns
                $write("%b ", dut.matrix[i][j]); // Print DUT matrix value
            end
            $write("\n"); // Newline after each row
        end

        #40 // Wait 40ns
        // End simulation
        $finish; // Finish simulation
    end

    // Monitor outputs
    initial begin
        $monitor("Time=%0t | rst_n=%b | req=%b | gnt=%b | valid_gnt=%b", $time, rst_n, req, gnt, valid_gnt); // Print monitored signals on change
    end

endmodule // End