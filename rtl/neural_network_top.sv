module neural_net_top #(
    parameter int DATA_WIDTH = 8,
    parameter int IMAGE_SIZE = 28,
    // Cycles between the pixel-position counter and the matching pooled
    // sample appearing at the layer-1 output.  Verified bit-exact against a
    // software model of the pipeline for the supplied testbench, which
    // presents pixel 0 two clocks after the rising edge that samples `start`.
    // If your image feeder has a different start-to-first-pixel gap, adjust
    // this by the same number of cycles - nothing else needs to change.
    parameter int VALID_DELAY = 3
)
(
    input  logic [DATA_WIDTH-1:0] input_stream,
    input  logic                  clk,
    input  logic                  rst,
    input  logic                  start,
    output logic [3:0]            predicted_digit,
    output logic                  prediction_ready
);

    logic cnn_to_fc_data;
    logic cnn_ready_flag;

    // ---------------------------------------------------------------
    // Pooled-sample valid generator.
    // Tracks where the incoming raster stream is, and marks the 13x13
    // positions at which layer 1 is emitting a genuine stride-2 pooled
    // output: odd rows and odd columns of the 26x26 convolution map,
    // i.e. input coordinates 3,5,...,27 in both axes.  Exactly 169 pulses
    // per frame.
    // ---------------------------------------------------------------
    logic streaming;
    logic [$clog2(IMAGE_SIZE)-1:0] col;
    logic [$clog2(IMAGE_SIZE)-1:0] row;
    logic raw_valid;
    logic [VALID_DELAY-1:0] valid_pipe;
    logic fc_valid;

    always_ff @(posedge clk) begin
        if (rst) begin
            streaming <= 1'b0; col <= '0; row <= '0;
        end
        else if (start) begin
            streaming <= 1'b1; col <= '0; row <= '0;
        end
        else if (streaming) begin
            if (col == IMAGE_SIZE-1) begin
                col <= '0;
                if (row == IMAGE_SIZE-1) begin
                    row       <= '0;
                    streaming <= 1'b0;
                end
                else row <= row + 1;
            end
            else col <= col + 1;
        end
    end

    assign raw_valid = streaming && col[0] && (col >= 3) && row[0] && (row >= 3);

    always_ff @(posedge clk) begin
        if (rst) valid_pipe <= '0;
        else     valid_pipe <= {valid_pipe[VALID_DELAY-2:0], raw_valid};
    end

    assign fc_valid = valid_pipe[VALID_DELAY-1];

    wrapper_top #(
        .DATA_WIDTH(DATA_WIDTH),
        .IMAGE_SIZE(IMAGE_SIZE)
    ) layer_1 (
        .input_stream(input_stream),
        .clk(clk),
        .rst(rst),
        .start(start),
        .ready_flag(cnn_ready_flag),
        .processed_bits(cnn_to_fc_data)
    );

    fc_layer_top #(
        .IMAGE_SIZE(169),
        .ROW_WIDTH(28)
    ) layer_2 (
        .clk(clk),
        .rst(rst),
        .incoming_data(cnn_to_fc_data),
        .data_valid(fc_valid),
        .predicted_digit(predicted_digit),
        .layer_done(prediction_ready)
    );

endmodule
