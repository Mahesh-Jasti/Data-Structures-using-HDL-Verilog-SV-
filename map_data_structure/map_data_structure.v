module map_data_structure_non_pipelined #(
    parameter KEY_WIDTH = 8,
    parameter VALUE_WIDTH = 16,
    parameter MAP_SIZE = 16,
    parameter MAP_INDEX_WIDTH = $clog2(MAP_SIZE)
)(
    input wire [KEY_WIDTH*MAP_SIZE-1:0] keys,
    input wire [VALUE_WIDTH*MAP_SIZE-1:0] values,
    input wire [1:0] op, // 0 -- NOP, 1 -- insert, 2 -- delete, 3 -- lookup
    input wire [MAP_SIZE-1:0] valid_vector,
    input wire [KEY_WIDTH-1:0] key_in,
    input wire [VALUE_WIDTH-1:0] value_in,

    output wire [MAP_INDEX_WIDTH-1:0] index_out,
    output wire [VALUE_WIDTH-1:0] value_out,
    output wire valid_out
);

    localparam NOP = 2'b00,
               INSERT = 2'b01,
               DELETE = 2'b10,
               LOOKUP = 2'b11;

    generate
        if(MAP_SIZE == 2) begin
            assign index_out = ((op == DELETE) || (op == INSERT)) ? ((keys[KEY_WIDTH*2-1:KEY_WIDTH] == key_in) ? 1'b1 : 1'b0) : 1'b0;
            assign valid_out = ((op == LOOKUP) || (op == DELETE) || (op == INSERT)) ? 
                                    ((keys[KEY_WIDTH*2-1:KEY_WIDTH] == key_in) ? valid_vector[1] : 
                                    (keys[KEY_WIDTH-1:0] == key_in) ? valid_vector[0] : 1'b0) : 
                                    1'b0;
            assign value_out = (op == LOOKUP) ? 
                                    ((keys[KEY_WIDTH*2-1:KEY_WIDTH] == key_in) ? values[VALUE_WIDTH*2-1:VALUE_WIDTH] : 
                                    (keys[KEY_WIDTH-1:0] == key_in) ? values[VALUE_WIDTH-1:0] : 'd0) : 
                                    'd0;
        end
        else begin
            localparam HALF = MAP_SIZE / 2;

            wire [MAP_INDEX_WIDTH-2:0] low_index_out;
            wire [VALUE_WIDTH-1:0] low_value_out;
            wire low_valid_out;

            wire [MAP_INDEX_WIDTH-2:0] high_index_out;
            wire [VALUE_WIDTH-1:0] high_value_out;
            wire high_valid_out;

            map_data_structure_non_pipelined #(
                .KEY_WIDTH(KEY_WIDTH),
                .VALUE_WIDTH(VALUE_WIDTH),
                .MAP_SIZE(HALF),
                .MAP_INDEX_WIDTH(MAP_INDEX_WIDTH-1)
            ) upper_half (
                .keys(keys[KEY_WIDTH*MAP_SIZE-1:KEY_WIDTH*HALF]),
                .values(values[VALUE_WIDTH*MAP_SIZE-1:VALUE_WIDTH*HALF]),
                .op(op),
                .valid_vector(valid_vector[MAP_SIZE-1:HALF]),
                .key_in(key_in),
                .value_in(value_in),
                .index_out(high_index_out),
                .value_out(high_value_out),
                .valid_out(high_valid_out)
            );

            map_data_structure_non_pipelined #(
                .KEY_WIDTH(KEY_WIDTH),
                .VALUE_WIDTH(VALUE_WIDTH),
                .MAP_SIZE(HALF),
                .MAP_INDEX_WIDTH(MAP_INDEX_WIDTH-1)
            ) lower_half (
                .keys(keys[KEY_WIDTH*HALF-1:0]),
                .values(values[VALUE_WIDTH*HALF-1:0]),
                .op(op),
                .valid_vector(valid_vector[HALF-1:0]),
                .key_in(key_in),
                .value_in(value_in),
                .index_out(low_index_out),
                .value_out(low_value_out),
                .valid_out(low_valid_out)
            );

            assign index_out = (high_valid_out) ? {1'b1, high_index_out} : 
                               (low_valid_out) ? {1'b0, low_index_out} : 'd0;

            assign valid_out = ((op == LOOKUP) || (op == DELETE) || (op == INSERT)) ? (high_valid_out | low_valid_out) : 1'b0;
            assign value_out = (op == LOOKUP) ? (high_valid_out ? high_value_out : 
                                                (low_valid_out ? low_value_out : 'd0)) :
                                                'd0;
            
        end
        
    endgenerate

endmodule

module map_data_structure #(
    parameter KEY_WIDTH = 8,
    parameter VALUE_WIDTH = 16,
    parameter MAP_SIZE = 16
)(
    input wire clk,
    input wire reset,

    input wire [KEY_WIDTH-1:0] key_in,
    input wire [VALUE_WIDTH-1:0] value_in,
    input wire [1:0] op, // 0 -- NOP, 1 -- insert, 2 -- delete, 3 -- lookup
    input wire valid_in,
    output wire ready_out,

    output wire [VALUE_WIDTH-1:0] value_out,
    output wire valid_out,
    input wire ready_in
);

    reg [KEY_WIDTH*MAP_SIZE-1:0] keys;
    reg [VALUE_WIDTH*MAP_SIZE-1:0] values;
    reg [MAP_SIZE-1:0] map_valid_vector;

    localparam FL_INDEX_WIDTH = $clog2(MAP_SIZE);
    reg [FL_INDEX_WIDTH-1:0] free_list [0:MAP_SIZE-1];

    reg [FL_INDEX_WIDTH-1:0] fl_rd_ptr, fl_wr_ptr;

    wire [FL_INDEX_WIDTH-1:0] map_key_index;
    wire valid_out_internal;

    localparam NOP = 2'b00,
               INSERT = 2'b01,
               DELETE = 2'b10,
               LOOKUP = 2'b11;

    always@(posedge clk) begin
        if(reset) begin
            fl_rd_ptr <= 'd0;
            fl_wr_ptr <= 'd0;
            map_valid_vector <= 'd0;
            for(integer i = 0; i < MAP_SIZE; i = i + 1) begin
                free_list[i] <= i;
            end
            keys <= 'd0;
            values <= 'd0;
        end
        else begin
            case(op)
                INSERT: begin
                    if(valid_in && ready_out && ~valid_out_internal) begin
                        keys[KEY_WIDTH*free_list[fl_rd_ptr] +: KEY_WIDTH] <= key_in;
                        values[VALUE_WIDTH*free_list[fl_rd_ptr] +: VALUE_WIDTH] <= value_in;
                        map_valid_vector[free_list[fl_rd_ptr]] <= 1'b1;
                        fl_rd_ptr <= fl_rd_ptr + 1;
                    end
                    else if(valid_in && ready_out && valid_out_internal) begin
                        // Key already exists, update value
                        values[VALUE_WIDTH*map_key_index +: VALUE_WIDTH] <= value_in;
                    end
                end
                DELETE: begin
                    if(valid_in && valid_out_internal) begin
                        map_valid_vector[map_key_index] <= 1'b0;
                        free_list[fl_wr_ptr] <= map_key_index;
                        fl_wr_ptr <= fl_wr_ptr + 1;
                    end
                end
                default: begin
                    // NOP or LOOKUP
                end
            endcase
        end
    end

    map_data_structure_non_pipelined #(
        .KEY_WIDTH(KEY_WIDTH),
        .VALUE_WIDTH(VALUE_WIDTH),
        .MAP_SIZE(MAP_SIZE)
    ) map_inst (
        .keys(keys),
        .values(values),
        .op(op),
        .valid_vector(map_valid_vector),
        .key_in(key_in),
        .value_in(value_in),
        .index_out(map_key_index),
        .value_out(value_out),
        .valid_out(valid_out_internal)
    );

    assign valid_out = (op == LOOKUP) && valid_out_internal;
    assign ready_out = ~&map_valid_vector;

endmodule