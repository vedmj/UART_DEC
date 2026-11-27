`timescale 1ns/1ps
module tb_alu;

    reg  [7:0]  a, b;
    reg  [3:0]  op;
    wire [15:0] result;
    wire [7:0]  flags;

    alu dut (.a(a), .b(b), .op(op), .result(result), .flags(flags));

    initial begin
        $dumpfile("tb_alu.vcd");
        $dumpvars(0, tb_alu);

        a = 0; b = 0; op = 0;
        #10;

        // add cases
        op = 4'h1; a = 8'd10;  b = 8'd20;  #10;
        a = 8'd255; b = 8'd1;   #10;
        a = 8'd127; b = 8'd1;   #10;

        // subtract cases
        op = 4'h2; a = 8'd20; b = 8'd10;  #10;
        a = 8'd5;  b = 8'd10;  #10;
        a = 8'd7;  b = 8'd7;   #10;

        // multiply cases
        op = 4'h3; a = 8'd15;  b = 8'd15;  #10;
        a = 8'd255; b = 8'd255; #10;

        // logic cases
        a = 8'hAA; b = 8'h55;
        op = 4'h4; #10;
        op = 4'h5; #10;
        op = 4'h6; #10;
        op = 4'h7; #10;

        // shift cases
        a = 8'hFF; b = 8'd4;
        op = 4'h8; #10;
        op = 4'h9; #10;
        a = 8'h01; b = 8'd3;
        op = 4'h8; #10;

        // compare cases
        op = 4'hA; a = 8'd9; b = 8'd9; #10;
        a = 8'd9;  b = 8'd4;  #10;
        a = 8'd4;  b = 8'd9;  #10;

        // invalid opcodes
        op = 4'h0; #10;
        op = 4'hB; #10;

        #10;
        $finish;
    end

endmodule
