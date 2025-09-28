module VC_shared_buf #(parameter LUT_SIZE = 4, parameter BUFFER_SIZE = 8) (
    input clk,
    input rst_n,

    input [$clog2(LUT_SIZE)-1:0] req_vc_id, // Number of VCs = LUT_SIZE
    input [31:0] data_in,
    input valid_in,
    output wire req_ready,

    output wire valid_out,
    output wire [31:0] data_out,
    input commit_ready,
    input commit_id
);

    parameter LUT_SIZE_LN = $clog2(LUT_SIZE);
    parameter BUFFER_SIZE_LN = $clog2(BUFFER_SIZE);

    reg [LUT_SIZE-1:0] lut_valid;
    reg [BUFFER_SIZE-1:0] lut_head [0:LUT_SIZE-1];
    reg [BUFFER_SIZE-1:0] lut_tail [0:LUT_SIZE-1];

    reg [31:0] buffer_data [0:BUFFER_SIZE-1];
    reg [BUFFER_SIZE-1:0] buffer_avail;
    reg [BUFFER_SIZE-1:0] linked_list [0:BUFFER_SIZE-1];
    
    wire [BUFFER_SIZE-1:0] pri_avail;
    wire [BUFFER_SIZE-1:0] gnt_avail;
    reg [BUFFER_SIZE_LN-1:0] gnt_avail_idx;
    
    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            lut_valid <= {LUT_SIZE{1'b0}};
            for(int i=0; i<LUT_SIZE; i=i+1) begin
                lut_head[i] <= 'd0;
                lut_tail[i] <= 'd0;
            end
        end
        else begin
            if(commit_ready && lut_valid[commit_id]) begin
                lut_valid[commit_id] <= (lut_head[commit_id] == lut_tail[commit_id]) ? 1'b0 : 1'b1;
                lut_head[commit_id] <= linked_list[lut_head[commit_id]]; // Reset head
                lut_tail[commit_id] <= lut_tail[commit_id]; // Reset tail
            end
            else if(valid_in && req_ready) begin
                lut_valid[req_vc_id] <= 1'b1;
                lut_head[req_vc_id] <= (lut_valid[req_vc_id]) ? gnt_avail_idx : lut_head[req_vc_id];
                lut_tail[req_vc_id] <= gnt_avail_idx;
            end
        end
    end

    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            buffer_avail <= {BUFFER_SIZE{1'b1}};
            for(int i=0; i<BUFFER_SIZE; i=i+1) begin
                buffer_data[i] <= 'd0;
                linked_list[i] <= 'd0;
            end
        end
        else begin
            if(commit_ready && lut_valid[commit_id]) begin
                buffer_avail[lut_head[commit_id]] <= 1'b1;
            end
            else if(valid_in && req_ready) begin
                buffer_data[gnt_avail_idx] <= data_in;
                buffer_avail[gnt_avail_idx] <= 1'b0;
                linked_list[lut_tail[req_vc_id]] <= lut_valid[req_vc_id] ? gnt_avail_idx : linked_list[lut_tail[req_vc_id]];
            end
        end
    end

    assign pri_avail[0] = 1'b0;
    for(genvar i = 0; i < BUFFER_SIZE - 1; i = i + 1) begin
        assign pri_avail[i+1] = pri_avail[i] | buffer_avail[i];
    end
    assign gnt_avail = (~pri_avail) & buffer_avail;
    
    always@(*) begin
        gnt_avail_idx = 0;
        for(int i = 0; i < BUFFER_SIZE; i = i + 1) begin
            if(gnt_avail[i]) begin
                gnt_avail_idx = i;
            end
        end
    end

    assign req_ready = ~|buffer_avail; // Ready if any buffer slot is available
    
    assign data_out = buffer_data[lut_head[commit_id]];
    assign valid_out = commit_ready && lut_valid[commit_id];
    

endmodule