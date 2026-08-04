module sliding_window_unit #(parameter int DATA_WIDTH = 8, parameter int IMAGE_SIZE = 28)
(
	input logic [DATA_WIDTH-1:0] input_pixel,
	input logic clk,
	input logic rst,
	output logic [DATA_WIDTH-1:0] top_left, top_middle, top_right, bottom_left, bottom_right, bottom_middle, middle_left, middle_middle, middle_right
);

//input to shift register 2 and 3 (outputs of line buffers)
logic [DATA_WIDTH-1:0] input_sr2;
logic [DATA_WIDTH-1:0] input_sr3;

//instantiation of the shift registers
shift_register #(.INPUT_DWIDTH(DATA_WIDTH)) dut (.incoming_data(input_pixel), .clk(clk), .reset(rst), .window1(bottom_right), .window2(bottom_middle), .window3(bottom_left) );
shift_register #(.INPUT_DWIDTH(DATA_WIDTH)) dut2 (.incoming_data(input_sr2), .clk(clk), .reset(rst), .window1(middle_right), .window2(middle_middle), .window3(middle_left) );
shift_register #(.INPUT_DWIDTH(DATA_WIDTH)) dut3 (.incoming_data(input_sr3), .clk(clk), .reset(rst), .window1(top_right), .window2(top_middle), .window3(top_left) );

//instantiating the line buffers
line_buffer #(.DATA_WIDTH(DATA_WIDTH), .IMAGE_STREAM(IMAGE_SIZE)) buffer1 (.input_streamed(input_pixel), .clk(clk), .rst(rst), .line_output(input_sr2));
line_buffer #(.DATA_WIDTH(DATA_WIDTH), .IMAGE_STREAM(IMAGE_SIZE)) buffer2 (.input_streamed(input_sr2), .clk(clk), .rst(rst), .line_output(input_sr3));

endmodule