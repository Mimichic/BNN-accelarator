module fc_argmax #(parameter int IMAGE_SIZE = 169)
(
	input logic [$clog2(IMAGE_SIZE+1)-1:0] input_pixel,
	input logic ready,
	input logic clk,
	input logic rst,
	output logic [3:0] digit_match,
	output logic done_flag
);

logic [3:0] i = 0;
logic [$clog2(IMAGE_SIZE+1)-1:0] container = 0;

assign done_flag = (i==9) && ready; // if done flag goes high instantly at 9 it will be a hassle!


always_ff @(posedge clk) begin
	if (rst) begin
		i <= 0; digit_match <= 0; container <= 0;
	end
	else if (ready) begin
		if (i == 9) 
			i <= 0;
		else
			i <= i + 1;

		if ((i == 0) || (input_pixel > container)) begin
			container <= input_pixel;
			digit_match <= i;
		end
		
		if (done_flag) 
			container <= 0; 
	end
end


endmodule
