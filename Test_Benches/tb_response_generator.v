`timescale 1ns/1ps
module tb_response_generator;

    reg         clk, rst, start;
    reg  [7:0]  status_in;
    reg  [15:0] result_in;
    reg  [7:0]  flags_in;
    reg         tx_busy, tx_done;
    wire        ready, tx_start;
    wire [7:0]  tx_data;

    response_generator dut (
        .clk(clk), .rst(rst), .start(start),
        .status_in(status_in), .result_in(result_in), .flags_in(flags_in),
        .ready(ready), .tx_start(tx_start), .tx_data(tx_data),
        .tx_busy(tx_busy), .tx_done(tx_done));

    // 100 MHz clock
    always #5 clk = ~clk;

    initial begin
        $dumpfile("tb_response_generator.vcd");
        $dumpvars(0, tb_response_generator);

        clk = 0; rst = 1; start = 0;
        status_in = 0; result_in = 0; flags_in = 0;
        tx_busy = 0; tx_done = 0;
        #30 rst = 0;
        #20;

        // first response
        status_in = 8'h00; result_in = 16'h001E; flags_in = 8'h00;
        start = 1; #10 start = 0;

        // inputs change after start
        status_in = 8'hFF; result_in = 16'hFFFF; flags_in = 8'hFF;

        // six tx done pulses
        #20;
        tx_done = 1; #10 tx_done = 0; #30;
        tx_done = 1; #10 tx_done = 0; #30;
        tx_done = 1; #10 tx_done = 0; #30;
        tx_done = 1; #10 tx_done = 0; #30;
        tx_done = 1; #10 tx_done = 0; #30;
        tx_done = 1; #10 tx_done = 0; #30;
        #50;

        // second response, tx busy
        status_in = 8'h01; result_in = 16'h0000; flags_in = 8'h01;
        tx_busy = 1;
        start = 1; #10 start = 0;
        #80 tx_busy = 0;
        #20;
        tx_done = 1; #10 tx_done = 0; #30;
        tx_done = 1; #10 tx_done = 0; #30;
        tx_done = 1; #10 tx_done = 0; #30;
        tx_done = 1; #10 tx_done = 0; #30;
        tx_done = 1; #10 tx_done = 0; #30;
        tx_done = 1; #10 tx_done = 0; #30;
        #50;

        $finish;
    end

endmodule
