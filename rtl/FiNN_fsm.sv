module FiNN_fsm #(
    parameter int DATA_WIDTH = 8,
    parameter int IMAGE_SIZE = 28,
    parameter int MATRIX_SIZE = 9,
    parameter int ROM_DEPTH = 16,
    parameter int POOLING_UNIT = 4
)
(
    input logic clk,
    input logic rst,
    input logic start,
    output logic ready_flag,
    output logic [3:0] rom_address
);

typedef enum logic [1:0] {IDLE, FILLING_PIPELINE, IMAGE_PROCESSING, NEXT_FILTER} state_t;

state_t current_state, next_state;

logic [9:0] cycle_counter;
logic [3:0] filter_counter;

always_ff @(posedge clk) begin
    if (rst) begin
        current_state <= IDLE;
    end 
    else begin
        current_state <= next_state;
    end
end

always_ff @(posedge clk) begin
    if (rst) begin
        cycle_counter <= 0;
        filter_counter <= 0;
    end 
    else begin
        if (current_state == FILLING_PIPELINE || current_state == IMAGE_PROCESSING) begin
            cycle_counter <= cycle_counter + 1;
        end 
        else begin
            cycle_counter <= 0;
        end

        if (current_state == NEXT_FILTER) begin
            if (filter_counter == ROM_DEPTH - 1) begin
                filter_counter <= 0;
            end 
            else begin
                filter_counter <= filter_counter + 1;
            end
        end
    end
end

always_comb begin
    next_state = current_state;

    case (current_state)
        IDLE: begin
            if (start) begin
                next_state = FILLING_PIPELINE;
            end
        end
        
        FILLING_PIPELINE: begin
            if (cycle_counter == 58) begin 
                next_state = IMAGE_PROCESSING;
            end
        end

        IMAGE_PROCESSING: begin
            if (cycle_counter == (784 + 58)) begin
                next_state = NEXT_FILTER;
            end
        end

        NEXT_FILTER: begin
            if (filter_counter == ROM_DEPTH - 1) begin
                next_state = IDLE;
            end 
            else begin
                next_state = FILLING_PIPELINE;
            end
        end
    endcase
end

always_comb begin
    ready_flag = 0;
    rom_address = filter_counter;

    if (current_state == IMAGE_PROCESSING) begin
        ready_flag = 1;
    end
end

endmodule