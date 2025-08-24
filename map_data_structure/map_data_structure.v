module map_data_structure_non_pipelined #(
    parameter KEY_WIDTH = 8,
    parameter VALUE_WIDTH = 16,
    parameter MAP_SIZE = 16,
    parameter MAP_INDEX_WIDTH = $clog2(MAP_SIZE)
)(
        // Concatenated keys
        input wire [KEY_WIDTH*MAP_SIZE-1:0] keys,
        // Concatenated values
        input wire [VALUE_WIDTH*MAP_SIZE-1:0] values,
        // Valid bits for each entry
        input wire [MAP_SIZE-1:0] valid_vector,
        // Key to operate on
        input wire [KEY_WIDTH-1:0] key_in,
        // Value to operate on
        input wire [VALUE_WIDTH-1:0] value_in,

        // Index of found key
        output wire [MAP_INDEX_WIDTH-1:0] index_out,
        // Output value
        output wire [VALUE_WIDTH-1:0] value_out,
        // Output valid signal
        output wire valid_out
);

    generate
        if(MAP_SIZE == 2) begin
                // Output index if key matches
                assign index_out = (keys[KEY_WIDTH*2-1:KEY_WIDTH] == key_in) ? 1'b1 : 1'b0;
                // Output valid for match
                assign valid_out = (keys[KEY_WIDTH*2-1:KEY_WIDTH] == key_in) ? valid_vector[1] : 
                                        ((keys[KEY_WIDTH-1:0] == key_in) ? valid_vector[0] : 1'b0);
                // Output value for match
                assign value_out = (keys[KEY_WIDTH*2-1:KEY_WIDTH] == key_in) ? values[VALUE_WIDTH*2-1:VALUE_WIDTH] : 
                                        ((keys[KEY_WIDTH-1:0] == key_in) ? values[VALUE_WIDTH-1:0] : 'd0);
        end
        else begin
            localparam HALF = MAP_SIZE / 2;

            wire [MAP_INDEX_WIDTH-2:0] low_index_out;
            wire [VALUE_WIDTH-1:0] low_value_out;
            wire low_valid_out;

            wire [MAP_INDEX_WIDTH-2:0] high_index_out;
            wire [VALUE_WIDTH-1:0] high_value_out;
            wire high_valid_out;

            map_data_structure_non_pipelined #(
                .KEY_WIDTH(KEY_WIDTH),
                .VALUE_WIDTH(VALUE_WIDTH),
                .MAP_SIZE(HALF),
                .MAP_INDEX_WIDTH(MAP_INDEX_WIDTH-1)
            ) upper_half (
                .keys(keys[KEY_WIDTH*MAP_SIZE-1:KEY_WIDTH*HALF]),
                .values(values[VALUE_WIDTH*MAP_SIZE-1:VALUE_WIDTH*HALF]),
                .valid_vector(valid_vector[MAP_SIZE-1:HALF]),
                .key_in(key_in),
                .value_in(value_in),
                .index_out(high_index_out),
                .value_out(high_value_out),
                .valid_out(high_valid_out)
            );

            map_data_structure_non_pipelined #(
                .KEY_WIDTH(KEY_WIDTH),
                .VALUE_WIDTH(VALUE_WIDTH),
                .MAP_SIZE(HALF),
                .MAP_INDEX_WIDTH(MAP_INDEX_WIDTH-1)
            ) lower_half (
                .keys(keys[KEY_WIDTH*HALF-1:0]),
                .values(values[VALUE_WIDTH*HALF-1:0]),
                .valid_vector(valid_vector[HALF-1:0]),
                .key_in(key_in),
                .value_in(value_in),
                .index_out(low_index_out),
                .value_out(low_value_out),
                .valid_out(low_valid_out)
            );

            assign index_out = (high_valid_out) ? {1'b1, high_index_out} : 
                                    ((low_valid_out) ? {1'b0, low_index_out} : 'd0);
            assign valid_out = high_valid_out | low_valid_out;
            assign value_out = high_valid_out ? high_value_out : 
                                    ((low_valid_out ? low_value_out : 'd0));
            
        end
        
    endgenerate

endmodule

module map_data_structure #(
    parameter KEY_WIDTH = 8,
    parameter VALUE_WIDTH = 16,
    parameter MAP_SIZE = 16
)(
    input wire clk,
    input wire reset,

    input wire [KEY_WIDTH-1:0] key_in,
    input wire [VALUE_WIDTH-1:0] value_in,
    input wire [1:0] op, // 0 -- NOP, 1 -- insert, 2 -- delete, 3 -- lookup
    input wire valid_in,
    output wire ready_out,

    output wire [VALUE_WIDTH-1:0] value_out,
    output wire valid_out,
    input wire ready_in
);


    reg [KEY_WIDTH*MAP_SIZE-1:0] keys;
    reg [VALUE_WIDTH*MAP_SIZE-1:0] values;
    reg [MAP_SIZE-1:0] map_valid_vector;

    localparam FL_INDEX_WIDTH = $clog2(MAP_SIZE);
    reg [FL_INDEX_WIDTH-1:0] free_list [0:MAP_SIZE-1];

    reg [FL_INDEX_WIDTH-1:0] fl_rd_ptr, fl_wr_ptr;

    // Width of each key
    parameter KEY_WIDTH = 8,
    // Width of each value
    parameter VALUE_WIDTH = 16,
    // Number of entries in the map
    parameter MAP_SIZE = 16
    localparam NOP = 2'b00,
    // Clock signal
    input wire clk,
    // Reset signal
    input wire reset,

    // Key input
    input wire [KEY_WIDTH-1:0] key_in,
    // Value input
    input wire [VALUE_WIDTH-1:0] value_in,
    // Operation: 0 -- NOP, 1 -- insert, 2 -- delete, 3 -- lookup
    input wire [1:0] op,
    // Input valid signal
    input wire valid_in,
    // Output ready signal
    output wire ready_out,

    // Output value
    output wire [VALUE_WIDTH-1:0] value_out,
    // Output valid signal
    output wire valid_out,
    // Input ready signal
    input wire ready_in
            keys <= 'd0;
    // Storage for all keys
    reg [KEY_WIDTH*MAP_SIZE-1:0] keys;
    // Storage for all values
    reg [VALUE_WIDTH*MAP_SIZE-1:0] values;
    // Valid bits for each entry
    reg [MAP_SIZE-1:0] map_valid_vector;

    // Free list index width
    localparam FL_INDEX_WIDTH = $clog2(MAP_SIZE);
    // Free list for available slots
    reg [FL_INDEX_WIDTH-1:0] free_list [0:MAP_SIZE-1];

    // Read and write pointers for free list
    reg [FL_INDEX_WIDTH-1:0] fl_rd_ptr, fl_wr_ptr;

    // Index of key in map
    wire [FL_INDEX_WIDTH-1:0] map_key_index;
    // Internal valid output from lookup
    wire valid_out_internal;

    // Operation codes
    localparam NOP = 2'b00,
               INSERT = 2'b01,
               DELETE = 2'b10,
               LOOKUP = 2'b11;

    // Main sequential logic
    always@(posedge clk) begin
        if(reset) begin // On reset
            fl_rd_ptr <= 'd0; // Reset read pointer
            fl_wr_ptr <= 'd0; // Reset write pointer
            map_valid_vector <= 'd0; // Clear valid bits
            for(integer i = 0; i < MAP_SIZE; i = i + 1) begin // Initialize free list
                free_list[i] <= i;
            end
            keys <= 'd0; // Clear keys
            values <= 'd0; // Clear values
        end
        else begin // On clock edge
            case(op)
                INSERT: begin // Insert operation
                    if(valid_in && ready_out && ~valid_out_internal) begin // If valid and slot available and key not present
                        keys[KEY_WIDTH*free_list[fl_rd_ptr] +: KEY_WIDTH] <= key_in; // Store key
                        values[VALUE_WIDTH*free_list[fl_rd_ptr] +: VALUE_WIDTH] <= value_in; // Store value
                        map_valid_vector[free_list[fl_rd_ptr]] <= 1'b1; // Mark slot as valid
                        fl_rd_ptr <= fl_rd_ptr + 1; // Increment read pointer
                    end
                    else if(valid_in && ready_out && valid_out_internal) begin // If key exists, update value
                        values[VALUE_WIDTH*map_key_index +: VALUE_WIDTH] <= value_in; // Update value
                    end
                end
                DELETE: begin // Delete operation
                    if(valid_in && valid_out_internal) begin // If valid and key found
                        map_valid_vector[map_key_index] <= 1'b0; // Mark slot as invalid
                        free_list[fl_wr_ptr] <= map_key_index; // Add slot to free list
                        fl_wr_ptr <= fl_wr_ptr + 1; // Increment write pointer
                    end
                end
                default: begin // NOP or LOOKUP
                    // No action for NOP or LOOKUP
                end
            endcase
        end
    end

    // Instantiate non-pipelined map for lookup and index
    map_data_structure_non_pipelined #(
        .KEY_WIDTH(KEY_WIDTH),
        .VALUE_WIDTH(VALUE_WIDTH),
        .MAP_SIZE(MAP_SIZE)
    ) map_inst (
        .keys(keys), // All keys
        .values(values), // All values
        .valid_vector(map_valid_vector), // Valid bits
        .key_in(key_in), // Key input
        .value_in(value_in), // Value input
        .index_out(map_key_index), // Index output
        .value_out(value_out), // Value output
        .valid_out(valid_out_internal) // Valid output
    );

    // Output valid only for lookup operation
    assign valid_out = (op == LOOKUP) && valid_out_internal;
    // Output ready if any slot is free
    assign ready_out = ~&map_valid_vector;