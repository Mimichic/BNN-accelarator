module fc_layer_top #(
    parameter int IMAGE_SIZE = 169,
    parameter int ROW_WIDTH = 28
)
(
    input  logic clk,
    input  logic rst,
    input  logic incoming_data, // The 1D pixel stream from the previous layer
    input  logic data_valid,
    
    output logic [3:0] predicted_digit, // The final classification
    output logic layer_done             
);

    logic feature_ready;
    logic shift_rst;
    logic [IMAGE_SIZE-1:0] feature_map;
    
    logic [3:0] rom_address;
    logic [IMAGE_SIZE-1:0] weight_vector;
    
    logic argmax_ready;
    logic [$clog2(IMAGE_SIZE+1)-1:0] match_score;
    logic argmax_done_flag; 

    larger_sr #(
        .INPUT_DWIDTH(IMAGE_SIZE),
        .ROW_WIDTH(ROW_WIDTH)
    ) shift_reg_inst (
        .clk(clk), .reset(shift_rst), .incoming_data(incoming_data), .data_valid(data_valid), .ready_flag(feature_ready), .window(feature_map)
    );

    fc_FiNN_fsm fsm_inst (
        .clk(clk), .rst(rst), .feature_ready(feature_ready), .rom_address(rom_address), .argmax_ready(argmax_ready), .shift_rst(shift_rst), .layer_done(layer_done)
    );


    fc_weighted_ROM #(
        .DATA_SIZE(IMAGE_SIZE),
        .DEPTH_ROM(10)
    ) rom_inst (
        .address(rom_address), .output_weight(weight_vector)
    );

    xnor_popcount #(
        .WIDTH(IMAGE_SIZE)
    ) math_core_inst (
        .input_A(feature_map), .input_B(weight_vector), .output_xnor(), .output_popcount(match_score)
    );

    fc_argmax #(
        .IMAGE_SIZE(IMAGE_SIZE)
    ) argmax_inst (
        .clk(clk), .rst(rst), .input_pixel(match_score), .ready(argmax_ready), .digit_match(predicted_digit), .done_flag(argmax_done_flag)
    );

endmodule
