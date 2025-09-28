module skid_full_slice #(
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

    reg [DATA_WIDTH-1:0] dst_buffer, skid_buffer;
    reg dst_buffer_full, skid_buffer_full;

    always@(posedge clk) begin
        if(reset) begin
            dst_buffer <= 'd0;
            dst_buffer_full <= 'd0;
            skid_buffer <= 'd0;
            skid_buffer_full <= 'd0;
        end
        else begin
            if(valid_in & ready_out) begin            // WRITE handshake     // skid buffer is EMPTY as ready_out = 1
                if(~dst_buffer_full | (dst_buffer_full & ready_in)) begin        // both buffers empty or "dst buffer is full and ready_in = 1" -- read handshake
                    dst_buffer <= data_in;
                    dst_buffer_full <= 1'b1;
                end
                else if(dst_buffer_full & ~ready_in) begin  // skid buffer is EMPTY as ready_out = 1
                    skid_buffer <= data_in;
                    skid_buffer_full <= 1'b1;
                end
            end
            else if(ready_in & valid_out) begin             // READ handshake   // dst buffer is FULL as valid_out = 1
                if(skid_buffer_full) begin                  // skid buffer will pass through its data to dst buffer
                    skid_buffer_full <= 1'b0;
                    dst_buffer <= skid_buffer;
                    dst_buffer_full <= 1'b1;
                end
                else begin
                    dst_buffer_full <= 1'b0;                 // both buffers are now going to be empty (next cycle)
                end
            end
        end
    end

    assign valid_out = dst_buffer_full;
    assign ready_out = ~skid_buffer_full;
    assign data_out = dst_buffer;

endmodule