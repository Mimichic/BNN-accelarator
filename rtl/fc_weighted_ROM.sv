module fc_weighted_ROM # (parameter DATA_SIZE = 169, parameter DEPTH_ROM = 10)
(
	input logic [3:0] address,
	output logic [DATA_SIZE-1:0] output_weight
);

logic [DATA_SIZE-1:0] rom_register [0:DEPTH_ROM-1];

initial begin
	$readmemb("fc_weights.mem", rom_register);
end

assign output_weight = rom_register[address];


endmodule