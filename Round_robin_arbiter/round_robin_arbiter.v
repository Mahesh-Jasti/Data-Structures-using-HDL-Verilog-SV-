module round_robin_arbiter_recursion #(
    parameter WIDTH = 8
)(
    input wire [WIDTH-1:0] req_vector,
    input wire [WIDTH-1:0] req_priority_vector,
    output wire [$clog2(WIDTH)-1:0] grant_idx,
    output wire grant_valid
);

    generate
        if(WIDTH == 2) begin
            reg grant_idx_reg;

            always@(*) begin
                grant_idx_reg = 'd0;
                case({req_vector[1], req_vector[0]})
                    2'b00: grant_idx_reg = 'd0; // No requests
                    2'b01: grant_idx_reg = 0;   // Only req 0
                    2'b10: grant_idx_reg = 1;   // Only req 1
                    2'b11: grant_idx_reg = ({req_vector[0], req_priority_vector[0]} >= {req_vector[1], req_priority_vector[1]}) ? 0 : 1; // Both requests, use priority
                    default : grant_idx_reg = 'd0;
                endcase
            end

            assign grant_valid = req_vector[0] | req_vector[1];
            assign grant_idx = grant_idx_reg;
        end
        else begin
            localparam HALF = WIDTH / 2;
            wire grant_valid_lsb, grant_valid_msb;
            wire [$clog2(HALF)-1:0] grant_idx_lsb, grant_idx_msb;
            reg [$clog2(WIDTH)-1:0] grant_idx_reg;

            round_robin_arbiter_recursion #(
                .WIDTH(HALF)
            ) round_robin_arbiter_recursion_lsb (
                .req_vector(req_vector[HALF-1:0]),
                .req_priority_vector(req_priority_vector[HALF-1:0]),
                .grant_idx(grant_idx_lsb),
                .grant_valid(grant_valid_lsb)
            );

            round_robin_arbiter_recursion #(
                .WIDTH(HALF)
            ) round_robin_arbiter_recursion_msb (
                .req_vector(req_vector[WIDTH-1:HALF]),
                .req_priority_vector(req_priority_vector[WIDTH-1:HALF]),
                .grant_idx(grant_idx_msb),
                .grant_valid(grant_valid_msb)
            );

            always@(*) begin
                grant_idx_reg = 'd0;
                case({grant_valid_msb, grant_valid_lsb})
                    2'b00: grant_idx_reg = 'd0; // No requests
                    2'b01: grant_idx_reg = {1'b0, grant_idx_lsb}; // Only LSB has requests
                    2'b10: grant_idx_reg = {1'b1, grant_idx_msb}; // Only MSB has requests
                    2'b11: grant_idx_reg = ({req_vector[{1'b0, grant_idx_lsb}], req_priority_vector[{1'b0, grant_idx_lsb}]} >= {req_vector[{1'b1, grant_idx_msb}], req_priority_vector[{1'b1, grant_idx_msb}]})
                                            ? {1'b0, grant_idx_lsb} : {1'b1, grant_idx_msb}; // Both have requests, use priority
                    default : grant_idx_reg = 'd0;
                endcase
            end

            assign grant_valid = grant_valid_lsb | grant_valid_msb;
            assign grant_idx = grant_idx_reg;
        end
    endgenerate

endmodule

module round_robin_arbiter_for_loop #(
    parameter WIDTH = 8
)(
    input wire [WIDTH-1:0] req_vector,
    input wire [WIDTH-1:0] req_priority_vector,
    output wire [$clog2(WIDTH)-1:0] grant_idx,
    output wire grant_valid
);
    localparam NUM_LEVELS = $clog2(WIDTH);
    wire [$clog2(WIDTH)-1:0] grant_idx_levels [NUM_LEVELS-1:0][(WIDTH/2)-1:0];
    wire grant_valid_levels [NUM_LEVELS-1:0][(WIDTH/2)-1:0];

    generate 
        genvar i,j;
        for(i=1; i<=NUM_LEVELS; i=i+1) begin : i_loop
            for(j=0;j<(WIDTH >> i); j=j+1) begin : j_loop
                if(i==1) begin
                    assign grant_valid_levels[i-1][j] = req_vector[2*j] | req_vector[2*j+1];
                    assign grant_idx_levels[i-1][j] = (req_vector[2*j] & req_vector[2*j+1]) ? ({req_vector[2*j], req_priority_vector[2*j]} >= {req_vector[2*j+1], req_priority_vector[2*j+1]} ? 2*j : 2*j+1) :
                                                      (req_vector[2*j] ? 2*j : (req_vector[2*j+1] ? 2*j+1 : 'd0));
                end
                else begin
                    assign grant_valid_levels[i-1][j] = grant_valid_levels[i-2][2*j] | grant_valid_levels[i-2][2*j+1];
                    assign grant_idx_levels[i-1][j] = (grant_valid_levels[i-2][2*j] & grant_valid_levels[i-2][2*j+1]) ? ({req_vector[grant_idx_levels[i-2][2*j]], req_priority_vector[grant_idx_levels[i-2][2*j]]} >= {req_vector[grant_idx_levels[i-2][2*j+1]], req_priority_vector[grant_idx_levels[i-2][2*j+1]]} ? grant_idx_levels[i-2][2*j] : grant_idx_levels[i-2][2*j+1]) :
                                                      (grant_valid_levels[i-2][2*j] ? grant_idx_levels[i-2][2*j] : (grant_valid_levels[i-2][2*j+1] ? grant_idx_levels[i-2][2*j+1] : 'd0));
                end
            end
        end

        assign grant_valid = grant_valid_levels[NUM_LEVELS-1][0];
        assign grant_idx = grant_idx_levels[NUM_LEVELS-1][0];

    endgenerate

endmodule

module round_robin_arbiter #(
    parameter WIDTH = 8 
)(
    input wire clk,
    input wire reset,
    input wire [WIDTH-1:0] req_vector,
    output wire [$clog2(WIDTH)-1:0] grant_idx_recursion,
    output wire grant_valid_recursion,
    output wire [$clog2(WIDTH)-1:0] grant_idx_for_loop,
    output wire grant_valid_for_loop
);

    reg [WIDTH-1:0] req_priority_vector;

    //wire [$clog2(WIDTH)-1:0] grant_idx_recursion, grant_idx_for_loop;
    //wire grant_valid_recursion, grant_valid_for_loop;

    always@(posedge clk) begin
        if(reset) begin
            req_priority_vector <= {WIDTH{1'b1}};
        end
        else if(grant_valid_recursion) begin
            req_priority_vector <= ({WIDTH{1'b1}} << (grant_idx_recursion+1));
        end
    end

    round_robin_arbiter_recursion #(
        .WIDTH(WIDTH)
    ) round_robin_arbiter_recursion_inst (
        .req_vector(req_vector),
        .req_priority_vector(req_priority_vector),
        .grant_idx(grant_idx_recursion),
        .grant_valid(grant_valid_recursion)
    );

    round_robin_arbiter_for_loop #(
        .WIDTH(WIDTH)
    ) round_robin_arbiter_for_loop_inst (
        .req_vector(req_vector),
        .req_priority_vector(req_priority_vector),
        .grant_idx(grant_idx_for_loop),
        .grant_valid(grant_valid_for_loop)
    );

    //assign grant_idx = grant_idx_recursion; // Change to grant_idx_for_loop to use for loop implementation
    //assign grant_valid = grant_valid_recursion; // Change to grant_valid_for_loop to use

endmodule