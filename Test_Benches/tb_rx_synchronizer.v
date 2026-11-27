`timescale 1ns/1ps
module tb_rx_synchronizer;

    reg  clk, rst, async_in;
    wire sync_out;

    rx_synchronizer dut (.clk(clk), .rst(rst),
                         .async_in(async_in), .sync_out(sync_out));

    // 100 MHz clock
    always #5 clk = ~clk;

    initial begin
        $dumpfile("tb_rx_synchronizer.vcd");
        $dumpvars(0, tb_rx_synchronizer);

        clk = 0; rst = 1; async_in = 1;
        #22 rst = 0;

        // async edges off-clock
        #31 async_in = 0;
        #47 async_in = 1;
        #13 async_in = 0;
        #60 async_in = 1;

        // narrow glitch
        #44 async_in = 0;
        #3  async_in = 1;

        // reset forces idle high
        #40 async_in = 0;
        #40 rst = 1;
        #30 rst = 0;
        #50;

        $finish;
    end

endmodule
