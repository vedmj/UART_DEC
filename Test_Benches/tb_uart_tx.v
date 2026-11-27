`timescale 1ns/1ps
module tb_uart_tx;

    reg        clk, rst, tx_start;
    reg  [7:0] tx_data;
    wire       tx, busy, done;
    wire       tick_16x, tick_1x;

    // baud ticks for the transmitter
    baud_generator u_baud (.clk(clk), .rst(rst),
                           .tick_16x(tick_16x), .tick_1x(tick_1x));

    uart_tx dut (.clk(clk), .rst(rst), .baud_tick(tick_1x),
                 .tx_start(tx_start), .tx_data(tx_data),
                 .tx(tx), .busy(busy), .done(done));

    // 100 MHz clock
    always #5 clk = ~clk;

    initial begin
        $dumpfile("tb_uart_tx.vcd");
        $dumpvars(0, tb_uart_tx);

        clk = 0; rst = 1; tx_start = 0; tx_data = 8'h00;
        #100 rst = 0;
        #1000;

        // send 0x41
        tx_data = 8'h41; tx_start = 1; #10 tx_start = 0;
        #110000;

        // send 0x55
        tx_data = 8'h55; tx_start = 1; #10 tx_start = 0;
        #110000;

        // send 0xFF
        tx_data = 8'hFF; tx_start = 1; #10 tx_start = 0;

        // start while busy ignored
        #30000 tx_data = 8'h00; tx_start = 1; #10 tx_start = 0;
        #80000;

        // send 0x00
        tx_data = 8'h00; tx_start = 1; #10 tx_start = 0;
        #110000;

        $finish;
    end

endmodule
