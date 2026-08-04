module wrapper_top #(
    parameter int DATA_WIDTH = 8, 
    parameter int IMAGE_SIZE = 28, 
    parameter int MATRIX_SIZE = 9, 
    parameter int ROM_DEPTH = 16,
    parameter int THRESHOLD = 4,
    parameter int POOLING_UNIT = 4
)
(
    input  logic [DATA_WIDTH-1:0] input_stream, 
    input  logic                  clk,
    input  logic                  rst,
    input  logic                  start,
    output logic                  ready_flag,
    output logic                  processed_bits 
);

    logic binarized_pixel;
    assign binarized_pixel = (input_stream >= 8'd128) ? 1'b1 : 1'b0;

    logic top_left, top_middle, top_right;
    logic middle_left, middle_middle, middle_right;
    logic bottom_left, bottom_middle, bottom_right;

    logic [3:0] address;
    logic [MATRIX_SIZE-1:0] output_weight;
    logic [MATRIX_SIZE-1:0] flattened_window;
    logic neuron_output;
    logic pooled_output;

    FiNN_fsm #(
        .IMAGE_SIZE(IMAGE_SIZE),
        .ROM_DEPTH(ROM_DEPTH)
    ) master_controller (
        .clk(clk),
        .rst(rst),
        .start(start),
        .ready_flag(ready_flag),
        .rom_address(address)
    );

    sliding_window_unit #(
        .DATA_WIDTH(1),
        .IMAGE_SIZE(IMAGE_SIZE)
    ) swu (
        .clk(clk), 
        .rst(rst), 
        .input_pixel(binarized_pixel),
        .top_left(top_left), .top_middle(top_middle), .top_right(top_right),
        .middle_left(middle_left), .middle_middle(middle_middle), .middle_right(middle_right),
        .bottom_left(bottom_left), .bottom_middle(bottom_middle), .bottom_right(bottom_right)
    );

    assign flattened_window = {
        top_left, top_middle, top_right,
        middle_left, middle_middle, middle_right,
        bottom_left, bottom_middle, bottom_right
    };

    weighted_ROM #(
        .MATRIX_SIZE(MATRIX_SIZE), 
        .DEPTH_ROM(ROM_DEPTH)
    ) weight_rom_inst (
        .address(address),
        .output_weight(output_weight)
    );

    MVTU_unit #(
        .DATA_WIDTH(MATRIX_SIZE), 
        .THRESHOLD(THRESHOLD)
    ) mvtu_inst (
        .image_stream(flattened_window), 
        .synapse_weight(output_weight), 
        .neuron_output(neuron_output) 
    );

    pooling_unit #(
        .IMAGE_SIZE(IMAGE_SIZE - 2) 
    ) pu (
        .clk(clk),
        .rst(rst),
        .input_pixel(neuron_output),
        .pooled_output(pooled_output)
    );

    assign processed_bits = pooled_output;

endmodule
