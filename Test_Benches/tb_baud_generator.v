`timescale 1ns/1ps
module tb_baud_generator;

    reg  clk, rst;
    wire tick_16x, tick_1x;

    baud_generator dut (.clk(clk), .rst(rst),
                        .tick_16x(tick_16x), .tick_1x(tick_1x));

    // 100 MHz clock
    always #5 clk = ~clk;

    initial begin
        $dumpfile("tb_baud_generator.vcd");
        $dumpvars(0, tb_baud_generator);

        clk = 0; rst = 1;
        #50 rst = 0;

        // about three baud periods
        #30000;

        // reset mid-run
        rst = 1; #50 rst = 0;
        #10000;

        $finish;
    end

endmodule
