module fc_FiNN_fsm (
    input  logic clk,
    input  logic rst,
    input  logic feature_ready, 
    output logic [3:0] rom_address, 
    output logic argmax_ready,      
    output logic shift_rst,         
    output logic layer_done         // The digit is predicted!
);

typedef enum logic [1:0] {IDLE, EVALUATE, DONE} state_t;
state_t current_state, next_state;

logic [3:0] digit_counter;


always_ff @(posedge clk) begin
    if (rst) 
        current_state <= IDLE;
    else 
        current_state <= next_state;
end

// The zero to nine Counter
always_ff @(posedge clk) begin
    if (rst) begin
        digit_counter <= 0;
    end 
    else if (current_state == EVALUATE) begin
        if (digit_counter == 9)
            digit_counter <= 0;
        else
            digit_counter <= digit_counter + 1;
    end 
    else begin
        digit_counter <= 0; // Default value set at zero
    end
end


always_comb begin
    next_state = current_state; 

    case (current_state)
        IDLE: begin
            if (feature_ready) 
                next_state = EVALUATE;
        end
        
        EVALUATE: begin
            if (digit_counter == 9) 
                next_state = DONE;
        end

        DONE: begin
            next_state = IDLE; // Just 1 cycle to indicate flags
        end
        
        default: next_state = IDLE;
    endcase
end

// 4. Output Logic (Combinational)
assign rom_address  = digit_counter;
assign argmax_ready = (current_state == EVALUATE);
assign shift_rst    = (current_state == DONE) || rst;
assign layer_done   = (current_state == DONE);

endmodule