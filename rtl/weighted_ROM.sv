module weighted_ROM # (parameter MATRIX_SIZE = 9, parameter DEPTH_ROM = 8)
(
	input logic [3:0] address,
	output logic [MATRIX_SIZE-1:0] output_weight
);

logic [MATRIX_SIZE-1:0] rom_register [0:DEPTH_ROM-1];

initial begin
	$readmemb("ROM.txt", rom_register);
end

assign output_weight = rom_register[address];


endmodule