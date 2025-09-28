module forward_slice #(
    parameter DATA_WIDTH = 8
)(
    input wire clk,
    input wire reset,

    input wire valid_in,
    input wire [DATA_WIDTH-1:0] data_in,
    input wire ready_in,

    output wire ready_out,
    output wire valid_out,
    output wire [DATA_WIDTH-1:0] data_out
);

    reg [DATA_WIDTH-1:0] buffer;
    reg buffer_full;

    always@(posedge clk) begin
        if(reset) begin
            buffer <= 'd0;
            buffer_full <= 1'b0;
        end
        else begin
            if(valid_in & ready_out) begin
                buffer <= data_in;
                buffer_full <= 1'b1;
            end
            else if(ready_in & valid_out) begin
                buffer_full <= 1'b0;
            end
        end
    end

    assign ready_out = ~buffer_full | ready_in;   // combo logic in ready_out
    assign valid_out = buffer_full;
    assign data_out = buffer;

endmodule