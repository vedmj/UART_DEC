`timescale 1ns/1ps
module tb_uart_rx;

    // one bit time at 115200
    parameter BIT = 8680;

    reg        clk, rst, rx_in;
    wire       tick_16x, tick_1x;
    wire [7:0] rx_data;
    wire       rx_valid, rx_busy, framing_error;

    // baud ticks for the receiver
    baud_generator u_baud (.clk(clk), .rst(rst),
                           .tick_16x(tick_16x), .tick_1x(tick_1x));

    uart_rx dut (.clk(clk), .rst(rst), .rx_in(rx_in), .tick_16x(tick_16x),
                 .rx_data(rx_data), .rx_valid(rx_valid),
                 .rx_busy(rx_busy), .framing_error(framing_error));

    // 100 MHz clock
    always #5 clk = ~clk;

    initial begin
        $dumpfile("tb_uart_rx.vcd");
        $dumpvars(0, tb_uart_rx);

        clk = 0; rst = 1; rx_in = 1;
        #100 rst = 0;
        #(2*BIT);

        // frame 0x41
        rx_in = 0; #BIT rx_in = 1; #BIT rx_in = 0; #BIT rx_in = 0; #BIT rx_in = 0; #BIT
        rx_in = 0; #BIT rx_in = 0; #BIT rx_in = 1; #BIT rx_in = 0; #BIT rx_in = 1; #BIT
        #(BIT);

        // frame 0x55
        rx_in = 0; #BIT rx_in = 1; #BIT rx_in = 0; #BIT rx_in = 1; #BIT rx_in = 0; #BIT
        rx_in = 1; #BIT rx_in = 0; #BIT rx_in = 1; #BIT rx_in = 0; #BIT rx_in = 1; #BIT
        #(BIT);

        // frame 0xA5 back-to-back
        rx_in = 0; #BIT rx_in = 1; #BIT rx_in = 0; #BIT rx_in = 1; #BIT rx_in = 0; #BIT
        rx_in = 0; #BIT rx_in = 1; #BIT rx_in = 0; #BIT rx_in = 1; #BIT rx_in = 1; #BIT
        // frame 0x3C back-to-back
        rx_in = 0; #BIT rx_in = 0; #BIT rx_in = 0; #BIT rx_in = 1; #BIT rx_in = 1; #BIT
        rx_in = 1; #BIT rx_in = 1; #BIT rx_in = 0; #BIT rx_in = 0; #BIT rx_in = 1; #BIT
        #(BIT);

        // short glitch, rejected
        rx_in = 0; #(BIT/8); rx_in = 1; #(2*BIT);

        // framing error, stop low
        rx_in = 0; #BIT rx_in = 1; #BIT rx_in = 1; #BIT rx_in = 1; #BIT rx_in = 1; #BIT
        rx_in = 1; #BIT rx_in = 1; #BIT rx_in = 1; #BIT rx_in = 1; #BIT rx_in = 0; #BIT
        // line returns high
        rx_in = 1; #(3*BIT);

        $finish;
    end

endmodule
