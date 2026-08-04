module shift_register #(parameter INPUT_DWIDTH = 8)
(
	input logic [INPUT_DWIDTH-1:0] incoming_data,
	input logic clk,
	input logic reset,
	output logic [INPUT_DWIDTH-1:0] window1, //we wish to create a 1x3 matrix
	output logic [INPUT_DWIDTH-1:0] window2,
	output logic [INPUT_DWIDTH-1:0] window3
	 
);

always_ff @(posedge clk) begin
	if (reset) begin
		window1 <= 0;
		window2 <= 0;
		window3 <= 0;
	end
	else begin
		window3 <= window2; //sequential process, we want the previous values to be stored before we change the value at window1
		window2 <= window1;
		window1 <= incoming_data;
	end
end
endmodule