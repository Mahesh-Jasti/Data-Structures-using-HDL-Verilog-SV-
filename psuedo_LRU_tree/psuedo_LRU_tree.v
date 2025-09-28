module psuedo_lru_tree #(
    parameter NUM_WAYS = 4
)(
    input wire clk,
    input wire reset,

    input wire [$clog2(NUM_WAYS)-1:0] access_way,
    input wire access_valid,

    output wire [$clog2(NUM_WAYS)-1:0] lru_way
);

    localparam NUM_LEVELS = $clog2(NUM_WAYS);

    reg [0:0] tree_levels [NUM_LEVELS-1:0][(NUM_WAYS/2)-1:0]; // in case of 8 ways, we have 3 levels and 4 values in each level but use only 1, 2 and 4 values respectively

    always@(posedge clk) begin
        if(reset) begin
            for(int i=0; i<NUM_LEVELS; i=i+1) begin
                for(int j=0; j<(NUM_WAYS >> (NUM_LEVELS-i)); j=j+1) begin   // "3-i" because first level has 1 root, 2nd has 2, 3rd has 4
                    tree_levels[i][j] <= 1'b0; // reset all to 0
                end
            end
        end
        else begin
            if(access_valid) begin
                tree_levels[0][0] <= ~tree_levels[0][0]; // toggle root always on a cache access
                for(int i=1; i<NUM_LEVELS; i=i+1) begin
                    tree_levels[i][access_way >> (NUM_LEVELS-i)] <= ~tree_levels[i][access_way >> (NUM_LEVELS-i)]; // toggle the bit on the path to the accessed way
                end
            end
        end
    end

    genvar i;
    generate
        assign lru_way[NUM_LEVELS-1] = tree_levels[0][0];
        for(i=1; i<NUM_LEVELS; i=i+1) begin: LRU_WAY
            assign lru_way[NUM_LEVELS-1-i] = tree_levels[i][lru_way >> (NUM_LEVELS-i)];
        end
    endgenerate

endmodule