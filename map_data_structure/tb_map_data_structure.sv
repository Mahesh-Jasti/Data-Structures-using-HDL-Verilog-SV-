module tb_map_data_structure;

  // Parameters
  localparam KEY_WIDTH = 8;
  localparam VALUE_WIDTH = 16;
  localparam MAP_SIZE = 8;

  // DUT signals
  reg clk, reset;
  reg [KEY_WIDTH-1:0] key_in;
  reg [VALUE_WIDTH-1:0] value_in;
  reg [1:0] op;
  reg valid_in;
  wire ready_out;
  wire [VALUE_WIDTH-1:0] value_out;
  wire valid_out;
  reg ready_in;

  // Instantiate DUT
  map_data_structure #(
    .KEY_WIDTH(KEY_WIDTH),
    .VALUE_WIDTH(VALUE_WIDTH),
    .MAP_SIZE(MAP_SIZE)
  ) dut (
    .clk(clk),
    .reset(reset),
    .key_in(key_in),
    .value_in(value_in),
    .op(op),
    .valid_in(valid_in),
    .ready_out(ready_out),
    .value_out(value_out),
    .valid_out(valid_out),
    .ready_in(ready_in)
  );

  // Clock generation
  initial clk = 0;
  always #5 clk = ~clk;

  // Test sequence
  initial begin
    $dumpfile("tb_map_data_structure.vcd");
    $dumpvars(0, tb_map_data_structure);
    // Initialize
    reset = 1;
    key_in = 0;
    value_in = 0;
    op = 2'b00; // NOP
    valid_in = 0;
    ready_in = 1;
    #20;
    reset = 0;

    // Insert key-value pairs
    repeat (7) begin
      @(negedge clk);
      key_in = $random;
      value_in = $random;
      op = 2'b01; // INSERT
      valid_in = 1;
      @(negedge clk);
      valid_in = 0;
      op = 2'b00; // NOP
      #10;
    end
    
    // Insert key-value pairs
    //repeat (7) begin
      @(negedge clk);
      key_in = 9;
      value_in = $random;
      op = 2'b01; // INSERT
      valid_in = 1;
      @(negedge clk);
      valid_in = 0;
      op = 2'b00; // NOP
      #10;
    //end

    // Lookup a key
    @(negedge clk);
    key_in = key_in; // Use last inserted key
    op = 2'b11; // LOOKUP
    valid_in = 1;
    @(negedge clk);
    valid_in = 0;
    op = 2'b00;
    #10;

    // Delete a key
    @(negedge clk);
    key_in = key_in; // Use last inserted key
    op = 2'b10; // DELETE
    valid_in = 1;
    @(negedge clk);
    valid_in = 0;
    op = 2'b00;
    #10;
    
    // Insert key-value pairs
    //repeat (7) begin
      @(negedge clk);
      key_in = 9;
      value_in = $random;
      op = 2'b01; // INSERT
      valid_in = 1;
      @(negedge clk);
      valid_in = 0;
      op = 2'b00; // NOP
      #10;
    //end
    
    // Insert key-value pairs
    repeat (2) begin
      @(negedge clk);
      key_in = $random;
      value_in = $random;
      op = 2'b01; // INSERT
      valid_in = 1;
      @(negedge clk);
      valid_in = 0;
      op = 2'b00; // NOP
      #10;
    end
    
    // Lookup a key
    @(negedge clk);
    key_in = key_in; // Use last inserted key
    op = 2'b11; // LOOKUP
    valid_in = 1;
    @(negedge clk);
    valid_in = 0;
    op = 2'b00;
    #10;
    
    // Lookup a key
    @(negedge clk);
    key_in = 9; // Use last inserted key
    op = 2'b11; // LOOKUP
    valid_in = 1;
    @(negedge clk);
    valid_in = 0;
    op = 2'b00;
    #10;

    // Finish simulation
    #50;
    $finish;
  end

  // Monitor outputs
  initial begin
    $monitor("Time=%0t, op=%0d, key_in=%0d, value_in=%0d, value_out=%0d, valid_out=%0b", $time, op, key_in, value_in, value_out, valid_out);
  end

endmodule
