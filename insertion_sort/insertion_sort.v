module insertion_sort #(parameter ARRAY_SIZE = 8)(
    input clk,
    input rst_n,
    input [31:0] data_in [0:ARRAY_SIZE-1],

    output wire [31:0] sorted_data,
    output wire done
);

    reg [31:0] array [0:ARRAY_SIZE-1];

    reg [1:0] state;
    parameter LOAD_ARRAY = 2'b00,
              ITER_INIT  = 2'b01,
              SORT       = 2'b10,
              DONE       = 2'b11;
    
    parameter SIZE_LN = $clog2(ARRAY_SIZE);
    reg [SIZE_LN-1:0] iter_i, iter_j;
    reg [SIZE_LN-1:0] iter_out;

    always@(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i = 0; i < ARRAY_SIZE; i = i + 1) begin
                array[i] <= 32'h0;
            end
            iter_i <= 0;
            iter_j <= 0;
            state <= LOAD_ARRAY;
        end
        else begin
            case(state)
                LOAD_ARRAY: begin
                    for (int i = 0; i < ARRAY_SIZE; i = i + 1) begin
                        array[i] <= data_in[i];
                    end
                    state <= ITER_INIT;
                end

                ITER_INIT: begin
                    iter_i <= 'd0 ? 'd1 : iter_i + 1;
                    iter_j <= 'd0;
                    state <= SORT;
                end

                SORT: begin
                    if(iter_j == iter_i) begin
                        state <= (iter_i == ARRAY_SIZE - 1) ? DONE : ITER_INIT;
                    end
                    else begin
                        if(array[iter_j] <= array[iter_i]) begin
                            iter_j <= iter_j + 1;
                            state <= SORT;
                        end
                        else begin
                            //array[iter_i] <= array[iter_j];
                            array[iter_j] <= array[iter_i];
                            for(int k = 0; k < ARRAY_SIZE; k = k + 1) begin
                                if(k>=iter_j & k<iter_i) begin
                                    array[k+1] <= array[k];
                                end
                            end
                            state <= (iter_i == ARRAY_SIZE - 1) ? DONE : ITER_INIT;
                        end 
                    end
                end

                DONE: begin
                    state <= (iter_out == ARRAY_SIZE - 1) ? LOAD_ARRAY : DONE; // Reset state to load new data
                end

                default: begin
                    
                end
            endcase
        end
    end

    always@(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            iter_out <= 0;
        end
        else if (state == DONE) begin
            iter_out <= iter_out + 1; // Output the last index processed
        end
    end

    assign sorted_data = array[iter_out];
    assign done = (state == DONE);

endmodule