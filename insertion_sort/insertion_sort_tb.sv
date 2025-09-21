`timescale 1ns/1ps

module insertion_sort_tb;

    parameter ARRAY_SIZE = 8;
    logic clk;
    logic rst_n;
    logic [31:0] data_in [0:ARRAY_SIZE-1];
    logic [31:0] sorted_data;
    logic done;

    // Instantiate the DUT
    insertion_sort #(.ARRAY_SIZE(ARRAY_SIZE)) dut (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .sorted_data(sorted_data),
        .done(done)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;

    // Test data
    //logic [31:0] test_vec [0:ARRAY_SIZE-1] = '{32'd23, 32'd5, 32'd17, 32'd9, 32'd1, 32'd12, 32'd3, 32'd8};

    integer i;

    initial begin
        $dumpfile("dump.vcd"); $dumpvars;
        // Initialize inputs
        rst_n = 0;
        for (i = 0; i < ARRAY_SIZE; i = i + 1)
            data_in[i] = 0;

        // Apply reset
        #12;
        rst_n = 1;

        // Apply test vector
        data_in[0] = 32'd23;
        data_in[1] = 32'd5;
        data_in[2] = 32'd17;
        data_in[3] = 32'd9;
        data_in[4] = 32'd1;
        data_in[5] = 32'd12;   
        data_in[6] = 32'd3;
        data_in[7] = 32'd8;

        // Wait for sorting to complete
        wait(done);

        // Display internal array values after sorting
        $display("Internal array values after sorting:");
        for (i = 0; i < ARRAY_SIZE; i = i + 1)
            $display("array[%0d] = %0d", i, dut.array[i]);

        #100;
        $finish;
    end

    // Monitor DUT state and print array at ITER_INIT
    always @(posedge clk) begin
        if (dut.state == dut.ITER_INIT) begin
            $display("ITER_INIT: array values:");
            for (int j = 0; j < ARRAY_SIZE; j = j + 1)
                $display("array[%0d] = %0d", j, dut.array[j]);
        end

        // Print sorted data when state == DONE
        if (dut.state == dut.DONE) begin
            $display("Sorted data output:");
            $display("sorted_data = %0d", sorted_data);
        end
    end

endmodule