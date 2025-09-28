module buffer_full_slice #(
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

    reg [DATA_WIDTH-1:0] src_buffer, skid_buffer;
    reg src_buffer_full, skid_buffer_full;

    always@(posedge clk) begin
        if(reset) begin
            src_buffer <= 'd0;
            skid_buffer <= 'd0;
            src_buffer_full <= 'd0;
            skid_buffer_full <= 'd0;
        end
        else begin
            if(valid_in & ready_out) begin
                if(~src_buffer_full | (src_buffer_full & ready_in)) begin
                    src_buffer <= data_in;
                    src_buffer_full <= 1'b1;
                end
                else if(src_buffer_full & ~ready_in) begin
                    skid_buffer <= src_buffer;
                    skid_buffer_full <= 1'b1;
                    src_buffer <= data_in;
                    src_buffer_full <= 1'b1;
                end
            end
            else if(ready_in & valid_out) begin       // one of the buffers must be full if valid_out = 1
                if(skid_buffer_full) begin
                    skid_buffer_full <= 1'b0;
                end
                else begin
                    src_buffer_full <= 1'b0;
                end
            end
        end
    end

    assign ready_out = ~skid_buffer_full;
    assign valid_out = src_buffer_full | skid_buffer_full;         // can be just "src_buffer_full" as skid buffer can't be full when src buffer is empty
    assign data_out = skid_buffer_full ? skid_buffer : src_buffer;

endmodule