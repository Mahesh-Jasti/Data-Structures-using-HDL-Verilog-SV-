module lru_doubly_linked_list #(
    parameter NUM_WAYS = 4
)(
    input wire clk,
    input wire reset,

    input wire [$clog2(NUM_WAYS)-1:0] access_way,
    input wire access_valid,

    output wire [$clog2(NUM_WAYS)-1:0] lru_way
);

    localparam PTR_WIDTH = $clog2(NUM_WAYS);
    
    reg [PTR_WIDTH-1:0] head, tail;
    reg [PTR_WIDTH-1:0] prev [NUM_WAYS-1:0];
    reg [PTR_WIDTH-1:0] next [NUM_WAYS-1:0];

    always@(posedge clk) begin
        if(reset) begin
            head <= 'd0;
            tail <= NUM_WAYS - 1'b1;
            for(int i=0;i<NUM_WAYS;i=i+1) begin
                prev[i] <= (i == 0) ? 'd0 : i - 1'b1;
                next[i] <= (i == NUM_WAYS - 1) ? NUM_WAYS - 1'b1 : i + 1'b1;
            end
        end
        else if(access_valid) begin
            if(access_way == tail) begin
                head <= tail;
                tail <= prev[tail];
                next[prev[tail]] <= prev[tail];
                prev[tail] <= 'd0;
                next[tail] <= head;
                prev[head] <= tail;
            end
            else if(access_way == head) begin
                head <= access_way;
            end
            else begin
                head <= access_way;
                next[access_way] <= head;
                prev[access_way] <= 'd0;
                prev[head] <= access_way;
                next[prev[access_way]] <= next[access_way];
                prev[next[access_way]] <= prev[access_way];
            end
        end
    end

    assign lru_way = tail;

endmodule