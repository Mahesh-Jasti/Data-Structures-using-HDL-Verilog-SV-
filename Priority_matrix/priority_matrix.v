module priority_matrix #(parameter N=3) ( // Module definition with parameter N (default 3)
    input  wire clk,                      // Clock input
    input  wire rst_n,                    // Active-low reset input

    input wire [N-1:0] matrix_in [N-1:0], // Input: N x N priority matrix

    input  wire [N-1:0] req,              // Input: N-bit request vector

    output wire valid_gnt,                // Output: Grant valid signal
    output wire [N-1:0] gnt               // Output: N-bit grant vector
);

    reg [N-1:0] matrix [N-1:0];           // Internal storage for priority matrix
    reg [1:0] state, next_state;          // FSM state and next state

    reg [N-1:0] matrix_transpose [N-1:0]; // Transposed matrix for grant computation

    reg [N-1:0] pre_gnt;                  // Intermediate grant vector
    wire [N-1:0] pre_gnt_temp;            // Temporary grant vector for combinational logic

    parameter LOAD_MATRIX = 2'b00,        // FSM state: Load matrix
              REQ_COMPUTE = 2'b01,        // FSM state: Compute requests
              GNT_COMPUTE_1 = 2'b10,      // FSM state: Compute grants (step 1)
              GNT_COMPUTE_2 = 2'b11;      // FSM state: Compute grants (step 2)

    // State register: update state on clock or reset
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= LOAD_MATRIX;         // On reset, go to LOAD_MATRIX state
        end else begin
            state <= next_state;          // Otherwise, update to next state
        end
    end

    // Main FSM logic: matrix and grant computation
    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            // On reset, clear matrix
            for(int i = 0; i < N; i = i + 1) begin
                for(int j = 0; j < N; j = j + 1) begin
                    matrix[i][j] <= 0;    // Set all matrix elements to 0
                end
            end
        end
        else begin
            case(state)
                LOAD_MATRIX: begin
                    // Load matrix from input
                    for(int i = 0; i < N; i = i + 1) begin
                        for(int j = 0; j < N; j = j + 1) begin
                            matrix[i][j] <= matrix_in[i][j]; // Copy input matrix
                        end
                    end
                end

                REQ_COMPUTE: begin
                    // Compute grants based on requests and matrix
                    for(int i = 0; i < N; i = i + 1) begin
                        for(int j = 0; j < N; j = j + 1) begin
                            matrix[i][j] <= matrix[i][j] & req[i]; // AND matrix row with request bit
                        end
                    end
                end

                GNT_COMPUTE_1: begin
                    // Transpose matrix for grant computation
                    for(int i = 0; i < N; i = i + 1) begin
                        for(int j = 0; j < N; j = j + 1) begin
                            matrix_transpose[i][j] <= matrix[j][i]; // Transpose operation
                        end
                    end
                end

                GNT_COMPUTE_2: begin
                    // Assign grants based on the computed matrix (logic can be added here)
                end

                default: begin
                    // None of the above states, reset to LOAD_MATRIX
                end
            endcase
        end
    end

    // Combinational logic for next state and pre_gnt calculation
    always@(*) begin
        pre_gnt = {N{1'b0}}; // Initialize pre_gnt to all 0's
        case(state)
            LOAD_MATRIX: next_state = REQ_COMPUTE; // Move to REQ_COMPUTE after loading
            REQ_COMPUTE: next_state = GNT_COMPUTE_1; // Move to GNT_COMPUTE_1 after computing requests
            GNT_COMPUTE_1: next_state = GNT_COMPUTE_2; // Move to GNT_COMPUTE_2 after transposing
            GNT_COMPUTE_2: begin
                next_state = LOAD_MATRIX; // Loop back to LOAD_MATRIX
                pre_gnt = {N{1'b0}}; // Reset pre_gnt
                for(int i = 0; i < N; i = i + 1) begin
                    pre_gnt[i] = (~|matrix_transpose[i] & req[i]); // Set grant if no other request in column
                end
            end
            default: next_state = LOAD_MATRIX; // Default next state
        endcase
    end

    assign pre_gnt_temp[0] = 1'b0; // Initialize first temp grant to 0
    for(genvar i=0;i<N-1;i=i+1) begin
        assign pre_gnt_temp[i+1] = pre_gnt_temp[i] | pre_gnt[i]; // OR previous grants for priority encoding
    end

    assign gnt = (valid_gnt) ? pre_gnt & ~pre_gnt_temp : {N{1'b0}}; // Final grant output, one-hot encoded
    assign valid_gnt = (state == GNT_COMPUTE_2); // Grant valid only in GNT_COMPUTE_2

endmodule