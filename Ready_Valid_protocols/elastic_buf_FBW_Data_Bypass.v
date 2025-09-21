module elastic_buf(
    input clk,                // Clock input
    input reset,              // Active-low reset

    input in_srdy,            // Source ready: input data is valid
    input [7:0] in_data,      // Input data
    output in_rrdy,           // Ready to receive input data
    
    input out_rrdy,           // Output ready: downstream can accept data
    output out_srdy,          // Output data is valid
    output [7:0] out_data     // Output data
);

    reg [7:0] buffer;         // Internal buffer to store data
    reg full;                 // Indicates if buffer is full

    always@(posedge clk) begin
        if(reset) buffer <= 'd0;
        else buffer <= in_data; // Always latch input data
    end

    always@(posedge clk) begin
        if(reset) full <= 'd0;
        else begin
            if(out_rrdy) full <= 1'b0;      // Mark buffer as empty when output data is consumed
            else if(in_srdy) full <= 1'b1; // Mark buffer as full when input data is latched
        end
    end

    assign out_srdy = full | in_srdy;      // Output is valid when buffer is full
    assign out_data = full ? buffer : in_data;    // Output current buffer value
    assign in_rrdy = !full;      // Ready to receive input when buffer is not full

endmodule