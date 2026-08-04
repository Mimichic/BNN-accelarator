module MVTU_unit #(parameter int THRESHOLD = 0, parameter int DATA_WIDTH = 8)
(
	input logic [DATA_WIDTH-1:0] synapse_weight,
	input logic [DATA_WIDTH-1:0] image_stream,
	output logic neuron_output
);

logic [DATA_WIDTH-1:0] output_xnor;
logic [$clog2(DATA_WIDTH+1)-1:0] popcount_output;

xnor_popcount #(.WIDTH(DATA_WIDTH)) uut (.input_A(synapse_weight), .input_B(image_stream), .output_xnor(output_xnor), .output_popcount(popcount_output));

batch_normalisation #(.WIDTH($clog2(DATA_WIDTH+1)), .THRESHOLD(THRESHOLD)) uut2 (.input_popcount(popcount_output), .output_normalised(neuron_output)); //the output to our xnor module is the input here  

endmodule