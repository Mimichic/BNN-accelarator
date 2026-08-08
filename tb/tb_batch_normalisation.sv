module tb_batch_normalisation;

//naming all inputs we will be needing for the DUT
localparam THRESHOLD = 8;
localparam WIDTH = 8;

logic [WIDTH-1:0] input_popcount;
logic normalised_output;

//instantiating the DUT
batch_normalisation #(.THRESHOLD(THRESHOLD), .WIDTH(WIDTH)) dut (
	.input_popcount(input_popcount),
	.output_normalised(normalised_output)
);

//creation of class for crv
class batch_test;
	rand logic [WIDTH-1:0] random_vector;

	constraint valid_popcount_range{
		random_vector >= 0; 
		random_vector <= WIDTH; // max popcount cannot exceed the width of the bits !!
	}
endclass

//wiring the class and the inputs we chose together
initial begin
	batch_test tx;
	tx = new();


for (int i = 0; i < 15; i++) begin
	if (!tx.randomize()) 
		$display("Uh oh! randomisation failed!!");
	else begin
		input_popcount = tx.random_vector;
		#5;
		$display(" Event : %d || input_vector : %d || output_given : %d", i, input_popcount, normalised_output);
		#5;
	end
end

$display("CRV completed!");

end
endmodule