// Testbench for lru_doubly_linked_list
`timescale 1ns/1ps

module tb_lru_doubly_linked_list;
    parameter NUM_WAYS = 4;
    localparam PTR_WIDTH = $clog2(NUM_WAYS);

    reg clk;
    reg reset;
    reg [PTR_WIDTH-1:0] access_way;
    reg access_valid;
    wire [PTR_WIDTH-1:0] lru_way;

    lru_doubly_linked_list #(.NUM_WAYS(NUM_WAYS)) dut (
        .clk(clk),
        .reset(reset),
        .access_way(access_way),
        .access_valid(access_valid),
        .lru_way(lru_way)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;

    // Test sequence
    initial begin
    $dumpfile("lru_linked_list_tb.vcd");
    $dumpvars(0, tb_lru_doubly_linked_list);
    $display("Starting LRU Doubly Linked List Testbench");
        reset = 1;
        access_way = 0;
        access_valid = 0;
        #12;
        reset = 0;
        #10;

        // Access way 3
        access_way = 3;
        access_valid = 1;
        #10;
        access_valid = 0;
        #10;
        $display("Accessed way 2, LRU way: %0d", lru_way);

        // Access way 2
        access_way = 2;
        access_valid = 1;
        #10;
        access_valid = 0;
        #10;
        $display("Accessed way 1, LRU way: %0d", lru_way);

        // Access way 1
        access_way = 1;
        access_valid = 1;
        #10;
        access_valid = 0;
        #10;
        $display("Accessed way 3, LRU way: %0d", lru_way);

        // Access way 0
        access_way = 0;
        access_valid = 1;
        #10;
        access_valid = 0;
        #10;
        $display("Accessed way 0, LRU way: %0d", lru_way);

        // Access way 2 again
        access_way = 2;
        access_valid = 1;
        #10;
        access_valid = 0;
        #10;
        $display("Accessed way 2 again, LRU way: %0d", lru_way);

        $display("Testbench completed");
        $finish;
    end
endmodule
