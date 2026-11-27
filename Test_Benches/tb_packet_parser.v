`timescale 1ns/1ps
module tb_packet_parser;

    reg        clk, rst;
    reg  [7:0] rx_data;
    reg        rx_valid, cmd_take;
    wire       cmd_valid, overrun;
    wire [1:0] cmd_kind;
    wire [7:0] cmd_opcode, cmd_a, cmd_b;

    // short timeout for simulation
    packet_parser #(.TIMEOUT_CLKS(50)) dut (
        .clk(clk), .rst(rst), .rx_data(rx_data), .rx_valid(rx_valid),
        .cmd_take(cmd_take), .cmd_valid(cmd_valid), .cmd_kind(cmd_kind),
        .cmd_opcode(cmd_opcode), .cmd_a(cmd_a), .cmd_b(cmd_b),
        .overrun(overrun));

    // 100 MHz clock
    always #5 clk = ~clk;

    initial begin
        $dumpfile("tb_packet_parser.vcd");
        $dumpvars(0, tb_packet_parser);

        clk = 0; rst = 1; rx_data = 0; rx_valid = 0; cmd_take = 0;
        #30 rst = 0;
        #20;

        // valid add packet
        rx_data = 8'hA5; rx_valid = 1; #10 rx_valid = 0; #20;
        rx_data = 8'h01; rx_valid = 1; #10 rx_valid = 0; #20;
        rx_data = 8'h0A; rx_valid = 1; #10 rx_valid = 0; #20;
        rx_data = 8'h14; rx_valid = 1; #10 rx_valid = 0; #20;
        rx_data = 8'h1F; rx_valid = 1; #10 rx_valid = 0; #20;
        #30 cmd_take = 1; #10 cmd_take = 0;
        #40;

        // bad checksum packet
        rx_data = 8'hA5; rx_valid = 1; #10 rx_valid = 0; #20;
        rx_data = 8'h01; rx_valid = 1; #10 rx_valid = 0; #20;
        rx_data = 8'h0A; rx_valid = 1; #10 rx_valid = 0; #20;
        rx_data = 8'h14; rx_valid = 1; #10 rx_valid = 0; #20;
        rx_data = 8'h00; rx_valid = 1; #10 rx_valid = 0; #20;
        #30 cmd_take = 1; #10 cmd_take = 0;
        #40;

        // garbage, then valid sub
        rx_data = 8'h12; rx_valid = 1; #10 rx_valid = 0; #20;
        rx_data = 8'h34; rx_valid = 1; #10 rx_valid = 0; #20;
        rx_data = 8'hA5; rx_valid = 1; #10 rx_valid = 0; #20;
        rx_data = 8'h02; rx_valid = 1; #10 rx_valid = 0; #20;
        rx_data = 8'h0A; rx_valid = 1; #10 rx_valid = 0; #20;
        rx_data = 8'h03; rx_valid = 1; #10 rx_valid = 0; #20;
        rx_data = 8'h0B; rx_valid = 1; #10 rx_valid = 0; #20;
        #30 cmd_take = 1; #10 cmd_take = 0;
        #40;

        // incomplete packet timeout
        rx_data = 8'hA5; rx_valid = 1; #10 rx_valid = 0; #20;
        rx_data = 8'h01; rx_valid = 1; #10 rx_valid = 0; #20;
        #700;
        cmd_take = 1; #10 cmd_take = 0;
        #40;

        // two packets, no take
        rx_data = 8'hA5; rx_valid = 1; #10 rx_valid = 0; #20;
        rx_data = 8'h01; rx_valid = 1; #10 rx_valid = 0; #20;
        rx_data = 8'h0A; rx_valid = 1; #10 rx_valid = 0; #20;
        rx_data = 8'h14; rx_valid = 1; #10 rx_valid = 0; #20;
        rx_data = 8'h1F; rx_valid = 1; #10 rx_valid = 0; #20;
        rx_data = 8'hA5; rx_valid = 1; #10 rx_valid = 0; #20;
        rx_data = 8'h03; rx_valid = 1; #10 rx_valid = 0; #20;
        rx_data = 8'h0F; rx_valid = 1; #10 rx_valid = 0; #20;
        rx_data = 8'h0F; rx_valid = 1; #10 rx_valid = 0; #20;
        rx_data = 8'h03; rx_valid = 1; #10 rx_valid = 0; #20;
        #30 cmd_take = 1; #10 cmd_take = 0;
        #40;

        // reset mid packet
        rx_data = 8'hA5; rx_valid = 1; #10 rx_valid = 0; #20;
        rx_data = 8'h01; rx_valid = 1; #10 rx_valid = 0; #20;
        rst = 1; #20 rst = 0;
        #100;

        $finish;
    end

endmodule
