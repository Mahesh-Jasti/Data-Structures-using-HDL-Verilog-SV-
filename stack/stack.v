module stack #(parameter SIZE = 8)(
    input clk,
    input rst_n,

    input push,                
    input [31:0] data_in,
    input pop,                 

    output wire [31:0] data_out,
    output wire ready,
    output wire valid
);

    reg [31:0] stack_mem [0:SIZE-1];

    wire full, empty;
    
    parameter ADDR_WIDTH = $clog2(SIZE);
    reg [ADDR_WIDTH:0] top; // Points to the top of the stack

    always@(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            top <= 0; // Reset stack pointer
            for(int i = 0; i < SIZE; i = i + 1) begin
                stack_mem[i] <= 32'b0; // Initialize stack memory to zero
            end
        end else begin
            if(push && !full) begin
                top <= top + 1; // Increment stack pointer on push 
                stack_mem[top] <= data_in; // Store data at the top of the stack
            end
            if(pop && !empty) begin
                top <= top - 1; // Decrement stack pointer on pop
            end
        end
    end
    
    assign full = (top == SIZE); // Stack is full if top is at the last index
    assign empty = (top == 0); // Stack is empty if top is at the
    
    assign data_out = (valid) ? stack_mem[top - 1] : 32'hDEAD_BEAD; // Output the top element of the stack
    assign ready = !full; // Ready to push if stack is not full
    assign valid = !empty; // Valid data if stack is not empty

endmodule