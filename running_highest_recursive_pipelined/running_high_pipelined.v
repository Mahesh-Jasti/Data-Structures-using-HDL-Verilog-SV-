// Code your design here
module running_high_recursive_finder #(
    parameter DEPTH = 8,
    parameter WIDTH = 4
)(
    input wire [WIDTH*DEPTH-1:0] data_in,
    output reg [WIDTH-1:0] high_out
);

    generate
        if(DEPTH == 2) begin : BASE
            always@(posedge clk) begin
                if(reset) high_out <= 0;
                else high_out <= (data_in[7:4] >= data_in[3:0]) ? data_in[7:4] : data_in[3:0];
            end
        end
        else begin : RECURSE
            localparam HALF = DEPTH/2;
            wire [WIDTH-1:0] high_out_high;
            wire [WIDTH-1:0] high_out_low;

            running_high_recursive_finder #(
                .DEPTH(HALF),
                .WIDTH(4)
            ) rhf_high (
                .clk(clk),
                .reset(reset),
                .data_in(data_in[WIDTH*DEPTH-1:WIDTH*HALF]),
                .high_out(high_out_high)
            );

            running_high_recursive_finder #(
                .DEPTH(HALF),
                .WIDTH(4)
            ) rhf_low (
                .clk(clk),
                .reset(reset),
                .data_in(data_in[WIDTH*HALF-1:0]),
                .high_out(high_out_low)
            );

            always@(posedge clk) begin
                if(reset) high_out <= 0;
                else high_out <= (high_out_high >= high_out_low) ? high_out_high : high_out_low;
            end
        end
    endgenerate

endmodule

module running_high (
    input wire clk,
    input wire reset,
    input wire [3:0] data_in,
    output wire [3:0] high_out
);

    reg [31:0] shift_reg;

    always@(posedge clk) begin
        if(reset) begin
            shift_reg <= 32'd0;
        end
        else begin
            shift_reg <= {shift_reg[27:0], data_in};
        end
    end

    running_high_recursive_finder #(
        .DEPTH(8),
        .WIDTH(4)
    ) rhf (
        .clk(clk),
        .reset(reset),
        .data_in(shift_reg),
        .high_out(high_out)
    );

endmodule