module tb_swu;

    localparam int DATA_WIDTH = 8;
    // We override to a 5x5 image to make the pipeline fill up faster
    localparam int IMAGE_SIZE = 5; 

    logic clk, rst;
    logic [DATA_WIDTH-1:0] input_pixel;
    logic [DATA_WIDTH-1:0] top_left, top_middle, top_right;
    logic [DATA_WIDTH-1:0] middle_left, middle_middle, middle_right;
    logic [DATA_WIDTH-1:0] bottom_left, bottom_middle, bottom_right;

    sliding_window_unit #(.DATA_WIDTH(DATA_WIDTH), .IMAGE_SIZE(IMAGE_SIZE)) dut (
        .clk(clk), .rst(rst), .input_pixel(input_pixel),
        .top_left(top_left), .top_middle(top_middle), .top_right(top_right),
        .middle_left(middle_left), .middle_middle(middle_middle), .middle_right(middle_right),
        .bottom_left(bottom_left), .bottom_middle(bottom_middle), .bottom_right(bottom_right)
    );


    initial begin
        clk = 0;
        forever #5 clk = ~clk; 
    end


    initial begin
        rst = 1;
        input_pixel = 0;
        #20; 
        rst = 0;
        #10;

        for (int i = 1; i <= 25; i++) begin
            @(negedge clk); 
            input_pixel = i;
            
            @(posedge clk);             
            $display("--- Clock Cycle %0d (Pixel %0d fed to camera) ---", i, input_pixel);
            $display("[%3d] [%3d] [%3d]", top_left, top_middle, top_right);
            $display("[%3d] [%3d] [%3d]", middle_left, middle_middle, middle_right);
            $display("[%3d] [%3d] [%3d]\n", bottom_left, bottom_middle, bottom_right);
        end
        
        // Step 3: Let the clock run for 10 more cycles to flush the final pixels out
        repeat(10) begin
            @(negedge clk);
            input_pixel = 0; // Pad the end of the image with 0s
            
            @(posedge clk);
            #1;
            $display("--- Flushing Pipeline ---");
            $display("[%3d] [%3d] [%3d]", top_left, top_middle, top_right);
            $display("[%3d] [%3d] [%3d]", middle_left, middle_middle, middle_right);
            $display("[%3d] [%3d] [%3d]\n", bottom_left, bottom_middle, bottom_right);
        end
        
        $finish; // End the simulation
    end

endmodule