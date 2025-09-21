module min_heap #(
    parameter DATA_WIDTH = 5,
    parameter HEAP_DEPTH = 4 
)(
    input wire [HEAP_DEPTH-1:0] valid,
    input wire [DATA_WIDTH*HEAP_DEPTH-1:0] data_in,
    output wire [DATA_WIDTH-1:0] min_out,
    output wire min_valid_out,
    output wire [$clog2(HEAP_DEPTH)-1:0] min_index_out
);

    generate
        if(HEAP_DEPTH == 2) begin
            reg [DATA_WIDTH-1:0] min_out_reg;
            reg [$clog2(HEAP_DEPTH)-1:0] min_index_out_reg;
            
            always@(*) begin
                min_out_reg = data_in[DATA_WIDTH-1:0];
                min_index_out_reg = 0;
                case(valid)
                    2'b01: begin 
                        min_out_reg = data_in[DATA_WIDTH-1:0];
                        min_index_out_reg = 0;
                    end
                    2'b10: begin 
                        min_out_reg = data_in[DATA_WIDTH*HEAP_DEPTH-1:DATA_WIDTH];
                        min_index_out_reg = 1;
                    end
                    2'b11: begin 
                        min_out_reg = (data_in[DATA_WIDTH-1:0] <= data_in[DATA_WIDTH*HEAP_DEPTH-1:DATA_WIDTH]) ? 
                                            data_in[DATA_WIDTH-1:0] : data_in[DATA_WIDTH*HEAP_DEPTH-1:DATA_WIDTH];
                        min_index_out_reg = (data_in[DATA_WIDTH-1:0] <= data_in[DATA_WIDTH*HEAP_DEPTH-1:DATA_WIDTH]) ? 
                                            0 : 1;
                    end
                    default: begin
                        min_out_reg = data_in[DATA_WIDTH-1:0];
                        min_index_out_reg = 0;
                    end
                endcase
            end
            
            assign min_valid_out = |valid;
            assign min_out = min_out_reg;
            assign min_index_out = min_index_out_reg;
        end
        else begin
            localparam HALF = HEAP_DEPTH/2;
            wire [DATA_WIDTH-1:0] min_out_msb, min_out_lsb;
            wire min_valid_out_msb, min_valid_out_lsb;
            wire [$clog2(HALF)-1:0] min_index_out_msb, min_index_out_lsb;
            reg [DATA_WIDTH-1:0] min_out_reg;
            reg [$clog2(HEAP_DEPTH)-1:0] min_index_out_reg;

            min_heap #(
                .DATA_WIDTH(DATA_WIDTH),
                .HEAP_DEPTH(HALF)
            ) min_heap_msb (
                .valid(valid[HEAP_DEPTH-1:HALF]),
                .data_in(data_in[DATA_WIDTH*HEAP_DEPTH-1:DATA_WIDTH*HALF]),
                .min_out(min_out_msb),
                .min_valid_out(min_valid_out_msb),
                .min_index_out(min_index_out_msb)
            );

            min_heap #(
                .DATA_WIDTH(DATA_WIDTH),
                .HEAP_DEPTH(HALF)
            ) min_heap_lsb (
                .valid(valid[HALF-1:0]),
                .data_in(data_in[DATA_WIDTH*HALF-1:0]),
                .min_out(min_out_lsb),
                .min_valid_out(min_valid_out_lsb),
                .min_index_out(min_index_out_lsb)
            );

            always@(*) begin
                min_out_reg = min_out_lsb;
                min_index_out_reg = min_index_out_lsb;
                case({min_valid_out_msb, min_valid_out_lsb})
                    2'b01: begin 
                        min_out_reg = min_out_lsb;
                        min_index_out_reg = {1'b0, min_index_out_lsb};
                    end
                    2'b10: begin 
                        min_out_reg = min_out_msb;
                        min_index_out_reg = {1'b1, min_index_out_msb};
                    end
                    2'b11: begin
                        min_out_reg = (min_out_lsb <= min_out_msb) ? min_out_lsb : min_out_msb;
                        min_index_out_reg = (min_out_lsb <= min_out_msb) ? {1'b0, min_index_out_lsb} : {1'b1, min_index_out_msb};
                    end
                    default: begin
                        min_out_reg = min_out_lsb;
                        min_index_out_reg = min_index_out_lsb;
                    end
                endcase
            end

            assign min_valid_out = min_valid_out_msb | min_valid_out_lsb;
            assign min_out = min_out_reg;
            assign min_index_out = min_index_out_reg;
        end
    endgenerate

endmodule


module max_heap #(
    parameter DATA_WIDTH = 5,
    parameter HEAP_DEPTH = 4 
)(
    input wire [HEAP_DEPTH-1:0] valid,
    input wire [DATA_WIDTH*HEAP_DEPTH-1:0] data_in,
    output wire [DATA_WIDTH-1:0] max_out,
    output wire max_valid_out,
    output wire [$clog2(HEAP_DEPTH)-1:0] max_index_out
);

    generate
        if(HEAP_DEPTH == 2) begin
            reg [DATA_WIDTH-1:0] max_out_reg;
            reg [$clog2(HEAP_DEPTH)-1:0] max_index_out_reg;
            
            always@(*) begin
                max_out_reg = data_in[DATA_WIDTH-1:0];
                max_index_out_reg = 0;
                case(valid)
                    2'b01: begin 
                        max_out_reg = data_in[DATA_WIDTH-1:0];
                        max_index_out_reg = 0;
                    end
                    2'b10: begin 
                        max_out_reg = data_in[DATA_WIDTH*HEAP_DEPTH-1:DATA_WIDTH];
                        max_index_out_reg = 1;
                    end
                    2'b11: begin 
                        max_out_reg = (data_in[DATA_WIDTH-1:0] >= data_in[DATA_WIDTH*HEAP_DEPTH-1:DATA_WIDTH]) ? 
                                            data_in[DATA_WIDTH-1:0] : data_in[DATA_WIDTH*HEAP_DEPTH-1:DATA_WIDTH];
                        max_index_out_reg = (data_in[DATA_WIDTH-1:0] >= data_in[DATA_WIDTH*HEAP_DEPTH-1:DATA_WIDTH]) ? 
                                            0 : 1;
                    end
                    default: begin
                        max_out_reg = data_in[DATA_WIDTH-1:0];
                        max_index_out_reg = 0;
                    end
                endcase
            end
            
            assign max_valid_out = |valid;
            assign max_out = max_out_reg;
            assign max_index_out = max_index_out_reg;
        end
        else begin
            localparam HALF = HEAP_DEPTH/2;
            wire [DATA_WIDTH-1:0] max_out_msb, max_out_lsb;
            wire max_valid_out_msb, max_valid_out_lsb;
            wire [$clog2(HALF)-1:0] max_index_out_msb, max_index_out_lsb;
            reg [DATA_WIDTH-1:0] max_out_reg;
            reg [$clog2(HEAP_DEPTH)-1:0] max_index_out_reg;

            max_heap #(
                .DATA_WIDTH(DATA_WIDTH),
                .HEAP_DEPTH(HALF)
            ) max_heap_msb (
                .valid(valid[HEAP_DEPTH-1:HALF]),
                .data_in(data_in[DATA_WIDTH*HEAP_DEPTH-1:DATA_WIDTH*HALF]),
                .max_out(max_out_msb),
                .max_valid_out(max_valid_out_msb),
                .max_index_out(max_index_out_msb)
            );

            max_heap #(
                .DATA_WIDTH(DATA_WIDTH),
                .HEAP_DEPTH(HALF)
            ) max_heap_lsb (
                .valid(valid[HALF-1:0]),
                .data_in(data_in[DATA_WIDTH*HALF-1:0]),
                .max_out(max_out_lsb),
                .max_valid_out(max_valid_out_lsb),
                .max_index_out(max_index_out_lsb)
            );

            always@(*) begin
                max_out_reg = max_out_lsb;
                max_index_out_reg = max_index_out_lsb;
                case({max_valid_out_msb, max_valid_out_lsb})
                    2'b01: begin 
                        max_out_reg = max_out_lsb;
                        max_index_out_reg = {1'b0, max_index_out_lsb};
                    end
                    2'b10: begin 
                        max_out_reg = max_out_msb;
                        max_index_out_reg = {1'b1, max_index_out_msb};
                    end
                    2'b11: begin
                        max_out_reg = (max_out_lsb >= max_out_msb) ? max_out_lsb : max_out_msb;
                        max_index_out_reg = (max_out_lsb >= max_out_msb) ? {1'b0, max_index_out_lsb} : {1'b1, max_index_out_msb};
                    end
                    default: begin
                        max_out_reg = max_out_lsb;
                        max_index_out_reg = {1'b0, max_index_out_lsb};
                    end
                endcase
            end

            assign max_valid_out = max_valid_out_msb | max_valid_out_lsb;
            assign max_out = max_out_reg;
            assign max_index_out = max_index_out_reg;
        end
    endgenerate

endmodule

module priority_arbiter #(
    parameter DEPTH = 4
)(
    input wire [DEPTH-1:0] req,
    output wire [$clog2(DEPTH)-1:0] grant_valid_idx,
);

    wire found_flag;
    reg [$clog2(DEPTH)-1:0] grant_valid_idx_reg;

    always@(*) begin
        grant_valid_idx_reg = 'd0;
        found_flag = 1'b0;
        for(int i=0; i<DEPTH; i=i+1) begin
            if(!found_flag && !req[i]) begin
                grant_valid_idx_reg = i;
                found_flag = 1'b1;
            end
        end
    end

    assign grant_valid_idx = grant_valid_idx_reg;

endmodule

module priority_arbiter_optimized #(
    parameter DEPTH = 4
)(
    input wire [DEPTH-1:0] req,
    output wire [$clog2(DEPTH)-1:0] grant_valid_idx,
    output wire grant_valid
);

    generate
        if(DEPTH == 2) begin
            assign grant_valid_idx = !req[0] ? 1'b0 : 1'b1;
            assign grant_valid = ~&req;
        end
        else begin
            localparam HALF = DEPTH/2;

            wire [$clog2(HALF)-1:0] grant_valid_idx_msb, grant_valid_idx_lsb;
            wire grant_valid_msb, grant_valid_lsb;

            priority_arbiter_optimized #(
                .DEPTH(HALF)
            ) priority_arbiter_msb(
                .req(DEPTH-1:HALF),
                .grant_valid_idx(grant_valid_idx_msb),
                .grant_valid(grant_valid_msb)
            );

            priority_arbiter_optimized #(
                .DEPTH(HALF)
            ) priority_arbiter_lsb(
                .req(HALF-1:0),
                .grant_valid_idx(grant_valid_idx_lsb),
                .grant_valid(grant_valid_lsb)
            );

            assign grant_valid = grant_valid_msb | grant_valid_lsb;
            assign grant_valid_idx = grant_valid_lsb ? {1'b0, grant_valid_idx_lsb} : {1'b1, grant_valid_idx_msb};
        end
    endgenerate

endmodule

module elevator #(
    parameter NUM_FLOORS = 16,
    parameter MAX_REQ = 4
)(
    input wire clk,
    input wire reset,

    input wire valid_in,
    input wire [$clog2(NUM_FLOORS)-1:0] floor_in,
    output wire ready_out,

    output wire elevator_stop
);

    localparam FLOOR_REQ_WIDTH = $clog2(NUM_FLOORS);

    reg [FLOOR_REQ_WIDTH-1:0] req_valid_vector;
    reg [FLOOR_REQ_WIDTH*MAX_REQ-1:0] req_data_vector;

    reg [1:0] state, next_state;
    reg [FLOOR_REQ_WIDTH-1:0] current_floor;
    reg elevator_stop_reg;

    wire grant_valid_idx;
    wire min_valid, max_valid;
    wire [FLOOR_REQ_WIDTH-1:0] min_out, max_out;
    wire [$clog2(MAX_REQ)-1:0] min_index_out, max_index_out;

    localparam IDLE = 2'b00,
               MOVING_UP = 2'b01,
               MOVING_DOWN = 2'b10;

    min_heap #(
        .DATA_WIDTH(FLOOR_REQ_WIDTH),
        .HEAP_DEPTH(MAX_REQ)
    ) min_heap_inst (
        .valid(req_valid_vector),
        .data_in(req_data_vector),
        .min_out(min_out),
        .min_valid_out(min_valid),
        .min_index_out(min_index_out)
    );

    max_heap #(
        .DATA_WIDTH(FLOOR_REQ_WIDTH),
        .HEAP_DEPTH(MAX_REQ)
    ) min_heap_inst (
        .valid(req_valid_vector),
        .data_in(req_data_vector),
        .min_out(max_out),
        .min_valid_out(max_valid),
        .min_index_out(max_index_out)
    );

    priority_arbiter #(
        .DEPTH(MAX_REQ)
    ) priority_arbiter_inst (
        .req(req_valid_vector),
        .grant_valid_idx(grant_valid_idx)
    );

    always@(posedge clk) begin
        if(reset) begin
            current_floor <= 'd0;
        end
        else begin
            case(state)
                IDLE: begin
                    current_floor <= current_floor;
                end
                MOVING_UP: begin
                    if(current_floor < max_floor) current_floor <= current_floor + 1'b1;
                end
                MOVING_DOWN: begin
                    if(current_floor > min_floor) current_floor <= current_floor - 1'b1;
                end
                default : begin
                    current_floor <= current_floor;
                end
            endcase
        end
    end

    always@(posedge clk) begin
        if(reset) begin
            req_valid_vector <= 'd0;
            req_data_vector <= 'd0;
        end
        else begin
            if(valid_in && ready_out) begin
                case(state)
                    IDLE: begin
                        req_valid_vector[grant_valid_idx] <= 1'b1;
                        req_data_vector[FLOOR_REQ_WIDTH*grant_valid_idx +: FLOOR_REQ_WIDTH] <= floor_in;
                    end
                    MOVING_UP: begin
                        if((floor_in > current_floor + 1'b1) && (current_floor != NUM_FLOORS-2) ) begin
                            req_valid_vector[grant_valid_idx] <= 1'b1;
                            req_data_vector[FLOOR_REQ_WIDTH*grant_valid_idx +: FLOOR_REQ_WIDTH] <= floor_in;
                        end
                    end
                    MOVING_DOWN: begin
                        if(floor_in < current_floor - 1'b1 && (current_floor != 1)) begin
                            req_valid_vector[grant_valid_idx] <= 1'b1;
                            req_data_vector[FLOOR_REQ_WIDTH*grant_valid_idx +: FLOOR_REQ_WIDTH] <= floor_in;
                        end
                    end
                    default: begin
                        // Do nothing
                    end
                endcase
            end
            if((current_floor == min_out) && min_valid && (state == MOVING_UP)) begin
                req_valid_vector[min_index_out] <= 1'b0;
            end
            if((current_floor == max_out) && max_valid && (state == MOVING_DOWN)) begin
                req_valid_vector[max_index_out] <= 1'b0;
            end
        end
    end

    always@(posedge clk) begin
        if(reset) state <= IDLE;
        else state <= next_state;
    end

    always@(*) begin
        next_state = state;
        elevator_stop_reg = 1'b0;
        case(state)
            IDLE: begin
                if(valid_in && ready_out) begin
                    if(floor_in > current_floor) next_state = MOVING_UP;
                    else if(floor_in < current_floor) next_state = MOVING_DOWN;
                    else next_state = IDLE;
                end
                else next_state = IDLE;
            end
            MOVING_UP: begin
                if((current_floor == max_out) && max_valid) next_state = IDLE;
                else next_state = MOVING_UP;
                if((current_floor == min_out) && min_valid) elevator_stop_reg = 1'b1;
            end
            MOVING_DOWN: begin
                if((current_floor == min_out) && min_valid) next_state = IDLE;
                else next_state = MOVING_DOWN;
                if((current_floor == max_out) && max_valid) elevator_stop_reg = 1'b1;
            end
            default : begin
                next_state = IDLE;
            end
        endcase
    end

    assign elevator_stop = elevator_stop_reg;

    assign ready_out = ~&req_valid_vector;

endmodule