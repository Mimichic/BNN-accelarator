module xnor_popcount #(parameter int WIDTH = 8)
(
	input logic [WIDTH-1:0] input_A,
	input logic [WIDTH-1:0] input_B,
	output logic [WIDTH-1:0] output_xnor,
	output logic [$clog2(WIDTH+1)-1:0] output_popcount   
);

always_comb begin
	output_xnor = ~(input_A ^ input_B);
	output_popcount = 0;
	for (int i = 0; i < WIDTH; i++) begin
		if(output_xnor[i] == 1'b1) begin
			output_popcount = output_popcount + 1'b1;
		end  
	end
end
endmodule