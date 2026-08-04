module batch_normalisation #(parameter int THRESHOLD = 8, parameter int WIDTH = 8) 
(
	input logic [WIDTH-1:0] input_popcount, //our input from the popcount module we made earlier !!
	output logic output_normalised
);

	always_comb begin
		output_normalised = (input_popcount > THRESHOLD)? 1'b1 : 1'b0; //I came across this line from a linkedin post and it feels so cool to use it >.<
	end

endmodule