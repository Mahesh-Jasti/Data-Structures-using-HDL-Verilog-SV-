module ping_pong_full_slice #(
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

    reg [DATA_WIDTH-1:0] buffer_a, buffer_b;
    reg [1:0] rd_ptr, wr_ptr;

    always@(posedge clk) begin
        if(reset) begin
            wr_ptr <= 2'b00;
        end
        else begin
            if(valid_in & ready_out) begin
                wr_ptr <= wr_ptr + 1'b1;
            end
        end
    end

    always@(posedge clk) begin
        if(reset) begin
            rd_ptr <= 2'b00;
        end
        else begin
            if(valid_out & ready_in) begin
                rd_ptr <= rd_ptr + 1'b1;
            end
        end
    end

    always@(posedge clk) begin
        if(reset) begin
            buffer_a <= 'd0;
            buffer_b <= 'd0;
        end
        else begin
            if(valid_in & ready_out) begin
                if(~wr_ptr[0]) begin
                    buffer_a <= data_in;
                end
                else begin
                    buffer_b <= data_in;
                end
            end
        end
    end

    assign ready_out = ~((wr_ptr[1] != rd_ptr[1]) && (wr_ptr[0] == rd_ptr[0]));   // ~full condition
    assign valid_out = ~(wr_ptr == rd_ptr); // ~empty condition
    assign data_out = (~rd_ptr[0]) ? buffer_a : buffer_b;

endmodule