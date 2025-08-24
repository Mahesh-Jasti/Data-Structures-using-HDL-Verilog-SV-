// Pipelined data structure for max priority queue
module max_priority_queue_data_structure_pipelined #(
    parameter DATA_WIDTH = 8, // Width of each data element
    parameter PQ_DEPTH = 8, // Number of elements in the queue
    parameter INDEX_OUT_WIDTH = $clog2(PQ_DEPTH) // Width of index output
)(
    input wire clk, // Clock input
    input wire reset, // Reset input

    input wire [DATA_WIDTH*PQ_DEPTH-1:0] data_in, // Input data vector
    input wire [PQ_DEPTH-1:0] valid_vector_in, // Valid bits for each element

    output reg [DATA_WIDTH-1:0] pq_out, // Output: max value
    output reg pq_valid_out, // Output: valid flag
    output reg [INDEX_OUT_WIDTH-1:0] pq_index_out // Output: index of max value
);

    generate // Generate block for parameterized implementation
        if(PQ_DEPTH == 2) begin // Special case for depth 2
            always@(posedge clk) begin // Sequential logic on clock edge
                if(reset) begin // On reset
                    pq_out <= 'd0; // Clear output
                    pq_valid_out <= 1'b0; // Clear valid flag
                    pq_index_out <= 'd0; // Clear index output
                end
                else begin // On normal operation
                    pq_out <= (data_in[DATA_WIDTH*2-1:DATA_WIDTH] >= data_in[DATA_WIDTH-1:0]) ? // Compare two elements
                                (valid_vector_in[1] ? data_in[DATA_WIDTH*2-1:DATA_WIDTH] : data_in[DATA_WIDTH-1:0]) : // Select valid max
                                (valid_vector_in[0] ? data_in[DATA_WIDTH-1:0] : data_in[DATA_WIDTH*2-1:DATA_WIDTH]); // Select valid min
                    pq_valid_out <= |valid_vector_in; // Output valid if any input is valid
                    pq_index_out <= (data_in[DATA_WIDTH*2-1:DATA_WIDTH] >= data_in[DATA_WIDTH-1:0]) ? // Index of max
                                        (valid_vector_in[1] ? 1'b1 : 1'b0) : // If second is valid
                                        (valid_vector_in[0] ? 1'b0 : 1'b1); // If first is valid
                end
            end
        end
        else begin // General case for depth > 2
            localparam HALF = PQ_DEPTH/2; // Half the depth
            localparam INDEX_OUT_WIDTH_HALF = $clog2(HALF); // Index width for half

            wire [DATA_WIDTH-1:0] pq_out_left, pq_out_right; // Outputs from left/right subqueues
            wire pq_valid_out_left, pq_valid_out_right; // Valid flags from left/right
            wire [INDEX_OUT_WIDTH_HALF-1:0] pq_index_out_left, pq_index_out_right; // Index outputs from left/right

            // Instantiate left subqueue
            max_priority_queue_data_structure_pipelined #(
                .DATA_WIDTH(DATA_WIDTH), // Pass data width
                .PQ_DEPTH(HALF), // Pass half depth
                .INDEX_OUT_WIDTH(INDEX_OUT_WIDTH_HALF) // Pass index width
            ) pq_left (
                .clk(clk), // Clock input
                .reset(reset), // Reset input
                .data_in(data_in[DATA_WIDTH*PQ_DEPTH-1:DATA_WIDTH*HALF]), // Left half of data
                .valid_vector_in(valid_vector_in[PQ_DEPTH-1:HALF]), // Left half of valid bits
                .pq_out(pq_out_left), // Output from left
                .pq_valid_out(pq_valid_out_left), // Valid from left
                .pq_index_out(pq_index_out_left) // Index from left
            );

            // Instantiate right subqueue
            max_priority_queue_data_structure_pipelined #(
                .DATA_WIDTH(DATA_WIDTH), // Pass data width
                .PQ_DEPTH(HALF), // Pass half depth
                .INDEX_OUT_WIDTH(INDEX_OUT_WIDTH_HALF) // Pass index width
            ) pq_right (
                .clk(clk), // Clock input
                .reset(reset), // Reset input
                .data_in(data_in[DATA_WIDTH*HALF-1:0]), // Right half of data
                .valid_vector_in(valid_vector_in[HALF-1:0]), // Right half of valid bits
                .pq_out(pq_out_right), // Output from right
                .pq_valid_out(pq_valid_out_right), // Valid from right
                .pq_index_out(pq_index_out_right) // Index from right
            );

            always@(posedge clk) begin // Sequential logic on clock edge
                if(reset) begin // On reset
                    pq_out <= 'd0; // Clear output
                    pq_valid_out <= 1'b0; // Clear valid flag
                    pq_index_out <= 'd0; // Clear index output
                end
                else begin // On normal operation
                    pq_out <= (pq_out_left >= pq_out_right) ? // Compare left/right outputs
                                (pq_valid_out_left ? pq_out_left : pq_out_right) : // Select valid max
                                (pq_valid_out_right ? pq_out_right : pq_out_left); // Select valid min
                    pq_valid_out <= pq_valid_out_left | pq_valid_out_right; // Output valid if any subqueue is valid
                    pq_index_out <= (pq_out_left >= pq_out_right) ? // Index of max
                                    (pq_valid_out_left ? {1'b1, pq_index_out_left} : {1'b0, pq_index_out_right}) : // If left is valid
                                    (pq_valid_out_right ? {1'b0, pq_index_out_right} : {1'b1, pq_index_out_left}); // If right is valid
                end
            end 
        end
    endgenerate // End generate block

endmodule // End data structure module

// Max priority queue module with pipelined data structure
module max_priority_queue #(
    parameter DATA_WIDTH = 8, // Width of each data element
    parameter PQ_DEPTH = 8, // Number of elements in the queue
    parameter PIPELINE = 0 // Pipeline parameter (not used in this implementation)
)(
    input wire clk, // Clock input
    input wire reset, // Reset input

    input wire [DATA_WIDTH-1:0] data_in, // Data input
    input wire valid_in, // Valid input
    input wire [1:0] op, // Operation code: 00 NOP, 01 PUSH, 10 POP, 11 TOP
    output wire ready_out, // Ready output

    output wire [DATA_WIDTH-1:0] pq_out, // Output: max value
    output wire valid_out, // Output: valid flag
    input wire ready_in // Ready input for pop
);

    localparam PQ_FL_PTR_SIZE  = $clog2(PQ_DEPTH); // Pointer size for free list

    localparam OP_NOP  = 2'b00, // No operation
               OP_PUSH = 2'b01, // Push operation
               OP_POP  = 2'b10, // Pop operation
               OP_TOP  = 2'b11; // Top operation

    reg [PQ_DEPTH-1:0] pq_valid_vector; // Valid bits for each element
    reg [DATA_WIDTH*PQ_DEPTH-1:0] pq_data_vector; // Data vector for queue

    reg [PQ_FL_PTR_SIZE-1:0] pq_free_list [0:PQ_DEPTH-1]; // Free list for indices
    reg [PQ_FL_PTR_SIZE-1:0] pq_fl_rd_ptr, pq_fl_wr_ptr; // Read/write pointers for free list

    wire [PQ_FL_PTR_SIZE-1:0] pq_popped_index_out; // Index output from data structure

    wire valid_out_internal; // Internal valid output from data structure

    reg [PQ_FL_PTR_SIZE-1:0] pop_result_counter; // Counter to manage output timing

    always@(posedge clk) begin // Sequential logic on clock edge
        if(reset) begin // On reset
            pq_valid_vector <= 'd0; // Clear valid vector
            pq_data_vector <= 'd0; // Clear data vector
            pq_fl_rd_ptr <= 'd0; // Clear read pointer
            pq_fl_wr_ptr <= 'd0; // Clear write pointer
            for(integer i=0; i<PQ_DEPTH; i=i+1) begin // Initialize free list
                pq_free_list[i] <= i; // Assign index
            end
        end
        else begin // On normal operation
            case(op) // Check operation code
                OP_PUSH: begin // Push operation
                    if(valid_in && ready_out) begin // If input is valid and ready
                        pq_valid_vector[pq_free_list[pq_fl_rd_ptr]] <= 1'b1; // Set valid bit
                        pq_data_vector[DATA_WIDTH*pq_free_list[pq_fl_rd_ptr] +: DATA_WIDTH] <= data_in; // Store data
                        pq_fl_rd_ptr <= pq_fl_rd_ptr + 1'b1; // Increment read pointer
                    end
                end
                OP_POP: begin // Pop operation
                    if(ready_in && valid_out) begin // If ready and output is valid
                        pq_valid_vector[pq_popped_index_out] <= 1'b0; // Clear valid bit
                        pq_free_list[pq_fl_wr_ptr] <= pq_popped_index_out; // Add index to free list
                        pq_fl_wr_ptr <= pq_fl_wr_ptr + 1'b1; // Increment write pointer
                    end
                end
                default : begin // Default case (NOP or TOP)
                    // NOP or TOP
                end
            endcase // End case
        end
    end // End always block

    // Instantiate the pipelined data structure module
    max_priority_queue_data_structure_pipelined #(
        .DATA_WIDTH(DATA_WIDTH), // Pass data width
        .PQ_DEPTH(PQ_DEPTH), // Pass depth
        .INDEX_OUT_WIDTH(PQ_FL_PTR_SIZE) // Pass index width
    ) pq_data_structure (
        .clk(clk), // Clock input
        .reset(reset), // Reset input
        .data_in(pq_data_vector), // Data vector
        .valid_vector_in(pq_valid_vector), // Valid vector
        .pq_out(pq_out), // Output: max value
        .pq_valid_out(valid_out_internal), // Output: valid flag
        .pq_index_out(pq_popped_index_out) // Output: index of max value
    );

    always@(posedge clk) begin // Sequential logic for pop result counter
        if(reset) pop_result_counter <= PQ_FL_PTR_SIZE; // On reset, set counter
        //else if(~|pop_result_counter) pop_result_counter <= pop_result_counter; // If counter is zero, hold
        else if((op == OP_PUSH) && valid_in && ready_out ) pop_result_counter <= PQ_FL_PTR_SIZE; // If queue is empty and push, reset counter
        else if((op == OP_POP) && ready_in && valid_out) pop_result_counter <= PQ_FL_PTR_SIZE; // On pop, reset counter
        else if(~|pop_result_counter) pop_result_counter <= pop_result_counter; // If counter is zero, hold
        else pop_result_counter <= pop_result_counter - 1'b1; // Otherwise, decrement counter 
    end // End always block

    assign ready_out = ~&pq_valid_vector; // Ready if not all valid
    assign valid_out = valid_out_internal && ready_in && (pop_result_counter == 0); // Output valid only when counter is zero
    //pq_out assigned in the max_priority_queue_data_structure module

endmodule // End max priority queue module