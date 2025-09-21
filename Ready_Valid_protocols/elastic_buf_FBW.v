module elastic_buf(
    input clk,                // Clock input
    input reset,              // Active-high reset

    input in_srdy,            // Source ready: input data is valid
    input [7:0] in_data,      // Input data
    output in_rrdy,           // Ready to receive input data
    
    input out_rrdy,           // Output ready: downstream can accept data
    output out_srdy,          // Output data is valid
    output [7:0] out_data     // Output data
);

    reg [7:0] buffer;
    reg full;                 // Indicates if buffer is full

    always@(posedge clk) begin
        if(reset) begin
            full <= 'd0;
        end
        else begin
            if(in_srdy) begin
                full <= 1'b1;      // Mark buffer as full when input data is latched
            end
            else if(out_rrdy) begin
                full <= 1'b0;      // Mark buffer as empty when output data is consumed
            end
        end
    end

    always@(posedge clk) begin
        if(reset) begin
            buffer <= 'd0;
        end
        else if(in_rrdy) begin
            buffer <= in_data; // Latch input data when ready
        end
    end

    assign out_srdy = full;      // Output is valid when buffer is full
    assign out_data = buffer;    // Output current buffer value
    assign in_rrdy = !full | out_rrdy;      // Ready to receive input when buffer is not full

endmodule