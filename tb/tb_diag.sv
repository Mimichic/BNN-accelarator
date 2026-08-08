// =====================================================================
//  tb_diag.sv  -  stage-by-stage diagnostic for neural_net_top
//
//  Run this BEFORE tb_mnist.sv when accuracy looks like chance.
//  It checks, in order:
//     1. the conv filter actually loaded from ROM.txt
//     2. the FC weight vectors actually loaded from fc_weights.mem
//     3. the 169-bit feature map produced by layer 1, image by image,
//        against a golden reference
//     4. the resulting predictions
//
//  The first check that fails tells you exactly which file or which
//  module is wrong. Every check is independent of the others.
//
//  Required files: ROM.txt, fc_weights.mem, mnist_images.mem,
//                  mnist_labels.mem, golden_fmaps.mem
// =====================================================================
`timescale 1ns/1ps

module tb_diag();

    localparam int PIXELS  = 784;
    localparam int NCHECK  = 20;   // images compared against golden_fmaps.mem

    // Reference signatures produced by the software model
    localparam logic [8:0] EXP_FILTER = 9'b010011110;
    int exp_wpop [0:9];            // expected popcount of each FC weight vector

    logic [7:0] input_stream;
    logic       clk, rst, start;
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

    logic [7:0]   images [0:1000*PIXELS-1];
    logic [3:0]   labels [0:999];
    logic [168:0] golden [0:NCHECK-1];

    logic [168:0] observed;
    logic [3:0]   captured;
    bit           got_result;
    int           fails, first_bad, guard;

    task automatic run_image(input int idx);
        begin
            got_result = 1'b0;
            @(posedge clk); #1 start = 1'b1;
            @(posedge clk); #1 start = 1'b0;
            for (int p = 0; p < PIXELS; p++) begin
                @(posedge clk);
                #1 input_stream = images[idx*PIXELS + p];
            end
            // Poll 1ns after each edge. feature_map is still valid throughout
            // the DONE cycle - shift_rst clears it on the following edge.
            guard = 0;
            while (!got_result && guard < 200) begin
                @(posedge clk);
                #1;
                if (prediction_ready) begin
                    observed   = uut.layer_2.feature_map;
                    captured   = predicted_digit;
                    got_result = 1'b1;
                end
                guard++;
            end
            repeat (6) @(posedge clk);
        end
    endtask

    function automatic int popcount169(input logic [168:0] v);
        int n = 0;
        for (int b = 0; b < 169; b++) if (v[b] === 1'b1) n++;
        return n;
    endfunction

    string        a, b;
    logic [8:0]   got_filter;
    logic [168:0] got_weight;
    int           n_bad_fmaps;

    initial begin
        exp_wpop[0]=55; exp_wpop[1]=22; exp_wpop[2]=50; exp_wpop[3]=48;
        exp_wpop[4]=33; exp_wpop[5]=40; exp_wpop[6]=45; exp_wpop[7]=32;
        exp_wpop[8]=53; exp_wpop[9]=38;

        $readmemh("mnist_images.mem", images);
        $readmemh("mnist_labels.mem", labels);
        $readmemb("golden_fmaps.mem", golden);

        clk = 0; rst = 1; start = 0; input_stream = 0; got_result = 0;
        repeat (4) @(posedge clk);
        #1 rst = 0;
        repeat (2) @(posedge clk);

        $display("");
        $display("===========================================================");
        $display("  STAGE DIAGNOSTIC");
        $display("===========================================================");

        // ---- CHECK 0 : stimulus files loaded at all -------------------
        $display("");
        $display("[0] stimulus files");
        if (images[0] === 8'hxx || labels[0] === 4'hx) begin
            $display("    FAIL - mnist_images.mem / mnist_labels.mem not found.");
            $display("           Copy them into the xsim run directory:");
            $display("           <proj>.sim/sim_1/behav/xsim/");
            $finish;
        end
        if (golden[0] === 169'bx) begin
            $display("    FAIL - golden_fmaps.mem not found (same directory).");
            $finish;
        end
        $display("    PASS - first 3 labels = %0d %0d %0d (expect 7 2 1)",
                 labels[0], labels[1], labels[2]);

        // ---- CHECK 1 : conv filter ------------------------------------
        got_filter = uut.layer_1.weight_rom_inst.rom_register[0];
        $display("");
        $display("[1] conv filter, ROM.txt address 0");
        $display("    expected 9'b%b", EXP_FILTER);
        $display("    loaded   9'b%b", got_filter);
        if (got_filter !== EXP_FILTER) begin
            $display("    FAIL - the ROM.txt in your simulation directory is not");
            $display("           the one the FC weights were derived for.");
            $display("           You are almost certainly still picking up your");
            $display("           original ROM.txt. Replace it, or re-derive the");
            $display("           FC weights for your filter with gen_weights.py.");
        end
        else $display("    PASS");

        // ---- CHECK 2 : FC weights -------------------------------------
        $display("");
        $display("[2] FC weight vectors, fc_weights.mem");
        fails = 0;
        for (int d = 0; d < 10; d++) begin
            got_weight = uut.layer_2.rom_inst.rom_register[d];
            if (got_weight === 169'bx) begin
                $display("    digit %0d : all X - file not found or too short", d);
                fails++;
            end
            else if (popcount169(got_weight) != exp_wpop[d]) begin
                $display("    digit %0d : popcount %0d, expected %0d",
                         d, popcount169(got_weight), exp_wpop[d]);
                fails++;
            end
        end
        if (fails != 0) begin
            $display("    FAIL (%0d of 10 wrong) - stale or mis-parsed", fails);
            $display("           fc_weights.mem. If the popcounts are close but");
            $display("           not equal, your simulator may be choking on the");
            $display("           trailing '// Weights for Digit n' comments -");
            $display("           strip them and retry.");
        end
        else $display("    PASS - all 10 vectors match");

        // ---- CHECK 3 : feature maps out of layer 1 ---------------------
        $display("");
        $display("[3] layer-1 feature maps vs golden reference");
        n_bad_fmaps = 0;
        first_bad   = -1;
        for (int idx = 0; idx < NCHECK; idx++) begin
            run_image(idx);
            if (observed !== golden[idx]) begin
                n_bad_fmaps++;
                if (first_bad < 0) first_bad = idx;
            end
        end
        if (n_bad_fmaps == 0)
            $display("    PASS - %0d/%0d feature maps bit-exact", NCHECK, NCHECK);
        else begin
            $display("    FAIL - %0d of %0d feature maps differ", n_bad_fmaps, NCHECK);
            run_image(first_bad);
            $display("");
            $display("    image %0d,  observed | golden", first_bad);
            for (int r = 0; r < 13; r++) begin
                a = "";
                b = "";
                for (int c = 0; c < 13; c++) begin
                    a = {a, observed[r*13+c]     ? "#" : "."};
                    b = {b, golden[first_bad][r*13+c] ? "#" : "."};
                end
                $display("      %s   |   %s", a, b);
            end
            $display("");
            $display("    ones: observed %0d, golden %0d",
                     popcount169(observed), popcount169(golden[first_bad]));
            $display("");
            $display("    Read the two maps above:");
            $display("      * shifted sideways by a column  -> VALID_DELAY in");
            $display("        neural_network_top.sv is off by that many cycles");
            $display("      * shifted vertically / smeared  -> wrapper_top.sv is");
            $display("        still the old file. The pooling instance must read");
            $display("        .IMAGE_SIZE(IMAGE_SIZE), not .IMAGE_SIZE(IMAGE_SIZE-2)");
            $display("      * completely unrelated          -> wrong ROM.txt,");
            $display("        see check [1]");
            $display("      * all zeros                     -> larger_sr.sv or");
            $display("        fc_layer_top.sv not updated (no data_valid port)");
        end

        // ---- CHECK 4 : end-to-end -------------------------------------
        $display("");
        $display("[4] predictions on the first 10 images");
        fails = 0;
        for (int idx = 0; idx < 10; idx++) begin
            run_image(idx);
            if (captured != labels[idx]) fails++;
            $display("    image %0d : label %0d  predicted %0d  %s",
                     idx, labels[idx], captured,
                     (captured == labels[idx]) ? "OK" : "miss");
        end
        $display("    %0d/10 correct (the reference build gets 6/10)", 10 - fails);

        $display("");
        $display("===========================================================");
        $display("");
        $finish;
    end

endmodule
