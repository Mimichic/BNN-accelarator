module larger_sr #(parameter int INPUT_DWIDTH = 169, parameter ROW_WIDTH = 28)
(
	input logic incoming_data,
	input logic data_valid,
	input logic clk,
	input logic reset,
	output logic ready_flag,
	output logic [INPUT_DWIDTH-1:0] window 
	 
);

logic [$clog2(INPUT_DWIDTH + 2)-1 : 0] i; //to ensure the width is sufficient 
logic en;

assign ready_flag = (i == INPUT_DWIDTH);
assign en = data_valid && (i < INPUT_DWIDTH); //enable signal to ensure no wrap-around


always_ff @(posedge clk) begin
    if (reset) begin
        window <= 0;
        i      <= 0;
    end
    else begin
        if (en) begin
            window[i] <= incoming_data;
            i         <= i + 1; //only increment when the ready_flag is hgih
        end
    end
end

endmodule
