// max_priority_queue_tb.sv
// SystemVerilog testbench for max_priority_queue

`timescale 1ns/1ps

module max_priority_queue_tb;
    localparam DATA_WIDTH = 8;
    localparam PQ_DEPTH = 8;

    reg clk;
    reg reset;
    reg [DATA_WIDTH-1:0] data_in;
    reg valid_in;
    reg [1:0] op;
    wire ready_out;
    wire [DATA_WIDTH-1:0] pq_out;
    wire valid_out;
    reg ready_in;

    // DUT instantiation
    max_priority_queue #(
        .DATA_WIDTH(DATA_WIDTH),
        .PQ_DEPTH(PQ_DEPTH)
    ) dut (
        .clk(clk),
        .reset(reset),
        .data_in(data_in),
        .valid_in(valid_in),
        .op(op),
        .ready_out(ready_out),
        .pq_out(pq_out),
        .valid_out(valid_out),
        .ready_in(ready_in)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;

    // Test sequence
    initial begin
        $dumpfile("max_priority_queue_tb.vcd");
        $dumpvars(0, max_priority_queue_tb);
        $display("Starting max_priority_queue testbench");
        reset = 1;
        data_in = 0;
        valid_in = 0;
        op = 2'b00;
        ready_in = 1;
        #20;
        reset = 0;
        #10;

        // Push values into the queue
        repeat (PQ_DEPTH) begin
            @(negedge clk);
            if (ready_out) begin
                data_in = $random % 256;
                valid_in = 1;
                op = 2'b01; // PUSH
            end else begin
                valid_in = 0;
                op = 2'b00; // NOP
            end
            #10;
        end
        valid_in = 0;
        op = 2'b00;
        #20;

        // TOP operation
        @(negedge clk);
        op = 2'b11; // TOP
        #10;
        $display("TOP value: %d, valid: %b", pq_out, valid_out);
        op = 2'b00;
        #10;

        // Pop all values
        repeat (PQ_DEPTH) begin
            @(negedge clk);
            if (valid_out) begin
                ready_in = 1;
                op = 2'b10; // POP
            end else begin
                ready_in = 0;
                op = 2'b00; // NOP
            end
            #10;
        end
        op = 2'b00;
        ready_in = 0;
        #20;
      
      	repeat (PQ_DEPTH) begin
            @(negedge clk);
            if (ready_out) begin
                data_in = $random % 256;
                valid_in = 1;
                op = 2'b01; // PUSH
            end else begin
                valid_in = 0;
                op = 2'b00; // NOP
            end
            #10;
        end
        valid_in = 0;
        op = 2'b00;
        #20;

        $display("Testbench finished");
        $finish;
    end
endmodule
