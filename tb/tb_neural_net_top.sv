module tb_neural_net_top();

    logic [7:0] input_stream;
    logic       clk;
    logic       rst;
    logic       start;
    logic [3:0] predicted_digit;
    logic       prediction_ready;

    neural_net_top #(
        .DATA_WIDTH(8),
        .IMAGE_SIZE(28)
    ) uut (
        .input_stream(input_stream),
        .clk(clk),
        .rst(rst),
        .start(start),
        .predicted_digit(predicted_digit),
        .prediction_ready(prediction_ready)
    );

    always #5 clk = ~clk;

    always @(posedge clk) begin
        if (prediction_ready)
            $display("[%0t] predicted_digit = %0d", $time, predicted_digit);
    end

    initial begin
        clk = 0;
        rst = 1;
        start = 0;
        input_stream = 0;

        #20;
        rst = 0;
        
        #10;
        @(posedge clk); #1 start = 1;
        @(posedge clk); #1 start = 0;

        for (int i = 0; i < 784; i++) begin
            @(posedge clk);
            #1 input_stream = $urandom_range(0, 255);
        end

        wait(prediction_ready == 1'b1);
        
        #50;
        $finish;
    end

endmodule
