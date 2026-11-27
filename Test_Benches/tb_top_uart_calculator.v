`timescale 1ns/1ps
module tb_top_uart_calculator;

    // one bit time at 115200
    parameter BIT = 8680;

    reg         clk, btnC, RsRx;
    reg  [15:0] sw;
    wire        RsTx, dp;
    wire [15:0] led;
    wire [6:0]  seg;
    wire [3:0]  an;

    top_uart_calculator dut (.clk(clk), .btnC(btnC), .sw(sw), .RsRx(RsRx),
                             .RsTx(RsTx), .led(led), .seg(seg),
                             .dp(dp), .an(an));

    // 100 MHz clock
    always #5 clk = ~clk;

    initial begin
        // top ports plus key blocks
        $dumpfile("tb_top_uart_calculator.vcd");
        $dumpvars(1, tb_top_uart_calculator);
        $dumpvars(1, dut.u_rx);
        $dumpvars(1, dut.u_parser);
        $dumpvars(1, dut.u_alu);
        $dumpvars(1, dut.u_ctrl);
        $dumpvars(1, dut.u_resp);
        $dumpvars(1, dut.u_tx);

        clk = 0; btnC = 1; RsRx = 1; sw = 16'h0000;
        #200 btnC = 0;
        #(2*BIT);

        // request: 10 + 20
        // byte 0xA5
        RsRx = 0; #BIT RsRx = 1; #BIT RsRx = 0; #BIT RsRx = 1; #BIT RsRx = 0; #BIT
        RsRx = 0; #BIT RsRx = 1; #BIT RsRx = 0; #BIT RsRx = 1; #BIT RsRx = 1; #BIT
        // byte 0x01
        RsRx = 0; #BIT RsRx = 1; #BIT RsRx = 0; #BIT RsRx = 0; #BIT RsRx = 0; #BIT
        RsRx = 0; #BIT RsRx = 0; #BIT RsRx = 0; #BIT RsRx = 0; #BIT RsRx = 1; #BIT
        // byte 0x0A
        RsRx = 0; #BIT RsRx = 0; #BIT RsRx = 1; #BIT RsRx = 0; #BIT RsRx = 1; #BIT
        RsRx = 0; #BIT RsRx = 0; #BIT RsRx = 0; #BIT RsRx = 0; #BIT RsRx = 1; #BIT
        // byte 0x14
        RsRx = 0; #BIT RsRx = 0; #BIT RsRx = 0; #BIT RsRx = 1; #BIT RsRx = 0; #BIT
        RsRx = 1; #BIT RsRx = 0; #BIT RsRx = 0; #BIT RsRx = 0; #BIT RsRx = 1; #BIT
        // byte 0x1F
        RsRx = 0; #BIT RsRx = 1; #BIT RsRx = 1; #BIT RsRx = 1; #BIT RsRx = 1; #BIT
        RsRx = 1; #BIT RsRx = 0; #BIT RsRx = 0; #BIT RsRx = 0; #BIT RsRx = 1; #BIT
        // wait for response
        #800000;

        // view status and flags
        sw = 16'h0001; #20000;
        // view operands
        sw = 16'h0002; #20000;
        // view opcode
        sw = 16'h0003; #20000;
        sw = 16'h0000;

        // request: 15 * 15
        // byte 0xA5
        RsRx = 0; #BIT RsRx = 1; #BIT RsRx = 0; #BIT RsRx = 1; #BIT RsRx = 0; #BIT
        RsRx = 0; #BIT RsRx = 1; #BIT RsRx = 0; #BIT RsRx = 1; #BIT RsRx = 1; #BIT
        // byte 0x03
        RsRx = 0; #BIT RsRx = 1; #BIT RsRx = 1; #BIT RsRx = 0; #BIT RsRx = 0; #BIT
        RsRx = 0; #BIT RsRx = 0; #BIT RsRx = 0; #BIT RsRx = 0; #BIT RsRx = 1; #BIT
        // byte 0x0F
        RsRx = 0; #BIT RsRx = 1; #BIT RsRx = 1; #BIT RsRx = 1; #BIT RsRx = 1; #BIT
        RsRx = 0; #BIT RsRx = 0; #BIT RsRx = 0; #BIT RsRx = 0; #BIT RsRx = 1; #BIT
        // byte 0x0F
        RsRx = 0; #BIT RsRx = 1; #BIT RsRx = 1; #BIT RsRx = 1; #BIT RsRx = 1; #BIT
        RsRx = 0; #BIT RsRx = 0; #BIT RsRx = 0; #BIT RsRx = 0; #BIT RsRx = 1; #BIT
        // byte 0x03
        RsRx = 0; #BIT RsRx = 1; #BIT RsRx = 1; #BIT RsRx = 0; #BIT RsRx = 0; #BIT
        RsRx = 0; #BIT RsRx = 0; #BIT RsRx = 0; #BIT RsRx = 0; #BIT RsRx = 1; #BIT
        // wait for response
        #800000;

        // request: invalid opcode 0x0B
        // byte 0xA5
        RsRx = 0; #BIT RsRx = 1; #BIT RsRx = 0; #BIT RsRx = 1; #BIT RsRx = 0; #BIT
        RsRx = 0; #BIT RsRx = 1; #BIT RsRx = 0; #BIT RsRx = 1; #BIT RsRx = 1; #BIT
        // byte 0x0B
        RsRx = 0; #BIT RsRx = 1; #BIT RsRx = 1; #BIT RsRx = 0; #BIT RsRx = 1; #BIT
        RsRx = 0; #BIT RsRx = 0; #BIT RsRx = 0; #BIT RsRx = 0; #BIT RsRx = 1; #BIT
        // byte 0x01
        RsRx = 0; #BIT RsRx = 1; #BIT RsRx = 0; #BIT RsRx = 0; #BIT RsRx = 0; #BIT
        RsRx = 0; #BIT RsRx = 0; #BIT RsRx = 0; #BIT RsRx = 0; #BIT RsRx = 1; #BIT
        // byte 0x02
        RsRx = 0; #BIT RsRx = 0; #BIT RsRx = 1; #BIT RsRx = 0; #BIT RsRx = 0; #BIT
        RsRx = 0; #BIT RsRx = 0; #BIT RsRx = 0; #BIT RsRx = 0; #BIT RsRx = 1; #BIT
        // byte 0x08
        RsRx = 0; #BIT RsRx = 0; #BIT RsRx = 0; #BIT RsRx = 0; #BIT RsRx = 1; #BIT
        RsRx = 0; #BIT RsRx = 0; #BIT RsRx = 0; #BIT RsRx = 0; #BIT RsRx = 1; #BIT
        // wait for response
        #800000;

        // request: bad checksum
        // byte 0xA5
        RsRx = 0; #BIT RsRx = 1; #BIT RsRx = 0; #BIT RsRx = 1; #BIT RsRx = 0; #BIT
        RsRx = 0; #BIT RsRx = 1; #BIT RsRx = 0; #BIT RsRx = 1; #BIT RsRx = 1; #BIT
        // byte 0x01
        RsRx = 0; #BIT RsRx = 1; #BIT RsRx = 0; #BIT RsRx = 0; #BIT RsRx = 0; #BIT
        RsRx = 0; #BIT RsRx = 0; #BIT RsRx = 0; #BIT RsRx = 0; #BIT RsRx = 1; #BIT
        // byte 0x02
        RsRx = 0; #BIT RsRx = 0; #BIT RsRx = 1; #BIT RsRx = 0; #BIT RsRx = 0; #BIT
        RsRx = 0; #BIT RsRx = 0; #BIT RsRx = 0; #BIT RsRx = 0; #BIT RsRx = 1; #BIT
        // byte 0x03
        RsRx = 0; #BIT RsRx = 1; #BIT RsRx = 1; #BIT RsRx = 0; #BIT RsRx = 0; #BIT
        RsRx = 0; #BIT RsRx = 0; #BIT RsRx = 0; #BIT RsRx = 0; #BIT RsRx = 1; #BIT
        // byte 0x55 (wrong checksum)
        RsRx = 0; #BIT RsRx = 1; #BIT RsRx = 0; #BIT RsRx = 1; #BIT RsRx = 0; #BIT
        RsRx = 1; #BIT RsRx = 0; #BIT RsRx = 1; #BIT RsRx = 0; #BIT RsRx = 1; #BIT
        // wait for response
        #800000;

        // request: 0xFF << 4
        // byte 0xA5
        RsRx = 0; #BIT RsRx = 1; #BIT RsRx = 0; #BIT RsRx = 1; #BIT RsRx = 0; #BIT
        RsRx = 0; #BIT RsRx = 1; #BIT RsRx = 0; #BIT RsRx = 1; #BIT RsRx = 1; #BIT
        // byte 0x08
        RsRx = 0; #BIT RsRx = 0; #BIT RsRx = 0; #BIT RsRx = 0; #BIT RsRx = 1; #BIT
        RsRx = 0; #BIT RsRx = 0; #BIT RsRx = 0; #BIT RsRx = 0; #BIT RsRx = 1; #BIT
        // byte 0xFF
        RsRx = 0; #BIT RsRx = 1; #BIT RsRx = 1; #BIT RsRx = 1; #BIT RsRx = 1; #BIT
        RsRx = 1; #BIT RsRx = 1; #BIT RsRx = 1; #BIT RsRx = 1; #BIT RsRx = 1; #BIT
        // byte 0x04
        RsRx = 0; #BIT RsRx = 0; #BIT RsRx = 0; #BIT RsRx = 1; #BIT RsRx = 0; #BIT
        RsRx = 0; #BIT RsRx = 0; #BIT RsRx = 0; #BIT RsRx = 0; #BIT RsRx = 1; #BIT
        // byte 0xF3
        RsRx = 0; #BIT RsRx = 1; #BIT RsRx = 1; #BIT RsRx = 0; #BIT RsRx = 0; #BIT
        RsRx = 1; #BIT RsRx = 1; #BIT RsRx = 1; #BIT RsRx = 1; #BIT RsRx = 1; #BIT
        // wait for response
        #800000;

        $finish;
    end

endmodule
