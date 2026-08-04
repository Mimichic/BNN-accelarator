module line_buffer #(parameter IMAGE_STREAM = 28, parameter DATA_WIDTH = 8) //mnist data set (28x28 image)
(
	input logic [DATA_WIDTH-1:0] input_streamed,
	input logic clk,
	input logic rst,
	output logic [DATA_WIDTH-1:0] line_output
);

logic [DATA_WIDTH-1:0] line_register [IMAGE_STREAM-1:0];
assign line_output = line_register[IMAGE_STREAM-1]; //line output gives us the last row (above) the current pixel 

always_ff @(posedge clk) begin
	if (rst) begin
		for (int i = IMAGE_STREAM-1 ; i >= 0 ; i--) begin
			line_register[i] <= 'b0; 
		end
	end
	else begin
		for (int i = IMAGE_STREAM-1 ; i > 0 ; i--) begin
			line_register[i] <= line_register[i-1]; //fills the older values in the last bucket iteratively
		end
		line_register[0] <= input_streamed;	//input stream always enters the 0th register	
	end
end

endmodule