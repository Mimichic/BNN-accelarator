module tb_MVTU;

//inputs and outputs for our dut
localparam THRESHOLD = 4; //given we are dealing with 8 bits, so 50-50 division 
localparam DATA_WIDTH = 8;
logic [DATA_WIDTH-1:0] image_stream;
logic [DATA_WIDTH-1:0] synapse_weights;
logic neuron_output;


class neuron_inputs;
	rand logic [DATA_WIDTH-1 : 0] input_stream;
	rand logic [DATA_WIDTH-1 : 0] weights;	//no need for crv here as all inputs remain valid
endclass

//device instantiation
MVTU_unit #(.THRESHOLD(THRESHOLD), .DATA_WIDTH(DATA_WIDTH)) dut (.image_stream(image_stream), .synapse_weight(synapse_weights), .neuron_output(neuron_output));

//randomization
initial begin
	neuron_inputs tx = new(); 


for (int i = 0; i < 15; i++) begin
	if(!tx.randomize()) 
		$display("Uh oh! randomization failed !!");
	else begin
		image_stream = tx.input_stream;
		#5;
		synapse_weights = tx.weights;
		#5;
		$display("event no. : %d || image_stream: %b || synapse_weights: %b || neuron_output: %b", i, image_stream, synapse_weights, neuron_output);
	end
end
end	

endmodule