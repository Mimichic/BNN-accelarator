`timescale 1ns / 1ps

module tb_wrapper_top();

    // 1. Parameters 
    parameter int DATA_WIDTH = 8;
    parameter int IMAGE_SIZE = 28;
    parameter int MATRIX_SIZE = 9;
    parameter int ROM_DEPTH = 8;
    parameter int POOLING_UNIT = 4;
    
    localparam int TOTAL_PIXELS = IMAGE_SIZE * IMAGE_SIZE; 

    // 2. Testbench Signals
    logic [DATA_WIDTH-1:0] input_stream;
    logic                  clk;
    logic                  rst;
    logic                  start;
    logic                  ready_flag;
    logic                  processed_bits;

    // Array to hold the input image data
    logic [DATA_WIDTH-1:0] image_memory [0:TOTAL_PIXELS-1];
    
    // File descriptor for saving the output
    int output_file; 

    // 3. Instantiate the DUT
    wrapper_top #(
        .DATA_WIDTH(DATA_WIDTH),
        .IMAGE_SIZE(IMAGE_SIZE),
        .MATRIX_SIZE(MATRIX_SIZE),
        .ROM_DEPTH(ROM_DEPTH),
        .POOLING_UNIT(POOLING_UNIT)
    ) dut (
        .input_stream(input_stream),
        .clk(clk),
        .rst(rst),
        .start(start),
        .ready_flag(ready_flag),
        .processed_bits(processed_bits)
    );

    // 4. Clock Generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; 
    end

    // 5. Stimulus Process
    initial begin
        // Open the output file for writing ("w")
        output_file = $fopen("output_image.txt", "w");
        if (output_file == 0) begin
            $display("Error: Could not open output_image.txt for writing.");
            $finish;
        end

        // Load the input image file
        $readmemh("image.hex", image_memory);
        
        rst = 1;
        start = 0;
        input_stream = 0;
        
        #20;
        rst = 0;
        
        #10;
        start = 1;
        #10;
        start = 0;

        // Stream the image: 1 pixel per clock cycle
        for (int i = 0; i < TOTAL_PIXELS; i++) begin
            input_stream = image_memory[i];
            #10; 
        end

        // Wait for the pipeline to finish processing
        #2000;
        
        // Close the file safely before ending the simulation
        $fclose(output_file);
        $display("Simulation Complete. Data saved to output_image.txt");
        $finish; 
    end

    // 6. File Writing Monitor
    // Writes the bit to the text file whenever ready_flag is high
    always_ff @(posedge clk) begin
        if (ready_flag) begin
            // $fdisplay automatically adds a newline after each bit
            $fdisplay(output_file, "%b", processed_bits);
        end
    end

endmodule