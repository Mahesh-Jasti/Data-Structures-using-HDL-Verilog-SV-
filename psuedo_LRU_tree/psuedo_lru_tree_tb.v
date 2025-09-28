`timescale 1ns/1ps

module psuedo_lru_tree_tb;
    parameter NUM_WAYS = 4;
    localparam ADDR_WIDTH = $clog2(NUM_WAYS);

    reg clk;
    reg reset;
    reg [ADDR_WIDTH-1:0] access_way;
    reg access_valid;
    wire [ADDR_WIDTH-1:0] lru_way;

    // Instantiate DUT
    psuedo_lru_tree #(.NUM_WAYS(NUM_WAYS)) dut (
        .clk(clk),
        .reset(reset),
        .access_way(access_way),
        .access_valid(access_valid),
        .lru_way(lru_way)
    );

    initial begin
        $dumpfile("psuedo_lru_tree_tb.vcd");
        $dumpvars(0, psuedo_lru_tree_tb);
        clk = 0;
        reset = 1;
        access_way = 0;
        access_valid = 0;
        #10;
        reset = 0;
        #10;
        // Access way 0
        access_way = 0;
        access_valid = 1;
        #10;
        access_valid = 0;
        #10;
        // Access way 2
        access_way = 2;
        access_valid = 1;
        #10;
        access_valid = 0;
        #10;
        // Access way 1
        access_way = 1;
        access_valid = 1;
        #10;
        access_valid = 0;
        #10;
        // Access way 3
        access_way = 3;
        access_valid = 1;
        #10;
        access_valid = 0;
        #20;
        $finish;
    end

    always #5 clk = ~clk;

endmodule
