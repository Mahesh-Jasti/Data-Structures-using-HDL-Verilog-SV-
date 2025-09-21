module elastic_buf(
    input clk,                // Clock input
    input rst_n,              // Active-low reset

    input in_srdy,            // Source ready: input data is valid
    input [7:0] in_data,      // Input data
    output in_rrdy,           // Ready to receive input data
    
    input out_rrdy,           // Output ready: downstream can accept data
    output out_srdy,          // Output data is valid
    output [7:0] out_data     // Output data
);

    reg [7:0] buffer;         // Internal buffer to store data
    reg full;                 // Indicates if buffer is full

    // Sequential logic: handles reset and buffer state transitions
    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            buffer <= 8'h00;  // Clear buffer on reset
            full <= 1'b0;     // Mark buffer as empty on reset
        end
        else begin
            case(full)
                1'b0: begin   // Buffer is empty
                    if(in_srdy) begin
                        buffer <= in_data; // Latch input data
                        full <= 1'b1;      // Mark buffer as full
                    end
                end
                1'b1: begin   // Buffer is full
                    if(out_rrdy && in_srdy) begin
                        buffer <= in_data; // Overwrite buffer with new data if both input and output are ready
                        full <= 1'b1;      // Remain full
                    end
                    else if(out_rrdy) begin
                        full <= 1'b0;      // Mark buffer as empty if output is ready (data consumed)
                    end
                end
            endcase
        end
    end

    assign in_rrdy = !full | (full & out_rrdy);      // Ready to receive input when buffer is not full
    assign out_data = buffer;    // Output current buffer value
    assign out_srdy = full;      // Output is valid when buffer is full

endmodule