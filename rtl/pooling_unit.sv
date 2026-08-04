module pooling_unit #(parameter int IMAGE_SIZE = 26)
(
	input logic input_pixel,
	input logic clk,
	input logic rst,
	output logic pooled_output
);

logic top_left, top_right, bottom_left, bottom_right;
logic streamed_output;
logic [3:0] data_stream;

line_buffer #(.DATA_WIDTH(1), .IMAGE_STREAM(IMAGE_SIZE)) dut (.clk(clk),.rst(rst), .input_streamed(input_pixel), .line_output(streamed_output));


always_ff @(posedge clk) begin
	if (rst) begin
		top_left <= 0;
		top_right <= 0;
		bottom_left <= 0;
		bottom_right <= 0;
	end
	else begin
		bottom_right <= input_pixel;
		bottom_left <= bottom_right;
		top_right <= streamed_output;
		top_left <= top_right;
	end	
end

assign data_stream = {top_right, top_left, bottom_right, bottom_left};



always_comb begin
	pooled_output = |data_stream;
	
end

endmodule