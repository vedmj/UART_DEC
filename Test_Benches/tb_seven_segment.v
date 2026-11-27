`timescale 1ns/1ps
module tb_seven_segment;

    reg         clk, rst;
    reg  [15:0] value;
    wire [6:0]  seg;
    wire [3:0]  an;

    seven_segment dut (.clk(clk), .rst(rst), .value(value),
                       .seg(seg), .an(an));

    // 100 MHz clock
    always #5 clk = ~clk;

    initial begin
        // tb signals only, keeps file small
        $dumpfile("tb_seven_segment.vcd");
        $dumpvars(1, tb_seven_segment);

        clk = 0; rst = 1; value = 16'h0123;
        #50 rst = 0;

        // one full frame each
        #2700000;
        value = 16'h4567; #2700000;
        value = 16'h89AB; #2700000;
        value = 16'hCDEF; #2700000;

        $finish;
    end

endmodule
