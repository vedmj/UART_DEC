`timescale 1ns/1ps
module tb_command_controller;

    reg         clk, rst;
    reg         cmd_valid;
    reg  [1:0]  cmd_kind;
    reg  [7:0]  cmd_opcode, cmd_a, cmd_b;
    reg  [15:0] alu_result;
    reg  [7:0]  alu_flags;
    reg         resp_ready;

    wire        cmd_take, resp_start, busy;
    wire [7:0]  alu_a, alu_b;
    wire [3:0]  alu_op;
    wire [15:0] result_reg;
    wire [7:0]  flags_reg, status_reg, opcode_reg;

    command_controller dut (
        .clk(clk), .rst(rst),
        .cmd_valid(cmd_valid), .cmd_kind(cmd_kind),
        .cmd_opcode(cmd_opcode), .cmd_a(cmd_a), .cmd_b(cmd_b),
        .cmd_take(cmd_take),
        .alu_a(alu_a), .alu_b(alu_b), .alu_op(alu_op),
        .alu_result(alu_result), .alu_flags(alu_flags),
        .result_reg(result_reg), .flags_reg(flags_reg),
        .status_reg(status_reg), .opcode_reg(opcode_reg),
        .resp_start(resp_start), .resp_ready(resp_ready), .busy(busy));

    // 100 MHz clock
    always #5 clk = ~clk;

    initial begin
        $dumpfile("tb_command_controller.vcd");
        $dumpvars(0, tb_command_controller);

        clk = 0; rst = 1;
        cmd_valid = 0; cmd_kind = 0;
        cmd_opcode = 0; cmd_a = 0; cmd_b = 0;
        alu_result = 0; alu_flags = 0; resp_ready = 0;
        #30 rst = 0;
        #20;

        // valid add command
        alu_result = 16'h001E; alu_flags = 8'h00;
        cmd_kind = 0; cmd_opcode = 8'h01; cmd_a = 8'h0A; cmd_b = 8'h14;
        cmd_valid = 1; #10 cmd_valid = 0;
        #40 resp_ready = 1; #10 resp_ready = 0;
        #30;

        // valid multiply command
        alu_result = 16'h00E1; alu_flags = 8'h02;
        cmd_opcode = 8'h03; cmd_a = 8'h0F; cmd_b = 8'h0F;
        cmd_valid = 1; #10 cmd_valid = 0;
        #40 resp_ready = 1; #10 resp_ready = 0;
        #30;

        // invalid opcode command
        alu_result = 16'h0000; alu_flags = 8'h00;
        cmd_opcode = 8'h0B; cmd_a = 8'h01; cmd_b = 8'h02;
        cmd_valid = 1; #10 cmd_valid = 0;
        #40 resp_ready = 1; #10 resp_ready = 0;
        #30;

        // checksum error event
        cmd_kind = 1;
        cmd_valid = 1; #10 cmd_valid = 0;
        #40 resp_ready = 1; #10 resp_ready = 0;
        #30;

        // incomplete packet event
        cmd_kind = 2;
        cmd_valid = 1; #10 cmd_valid = 0;
        #40 resp_ready = 1; #10 resp_ready = 0;
        #30;

        // reset while waiting
        cmd_kind = 0; cmd_opcode = 8'h01; cmd_a = 8'h05; cmd_b = 8'h05;
        alu_result = 16'h000A;
        cmd_valid = 1; #10 cmd_valid = 0;
        #20 rst = 1; #20 rst = 0;
        #50;

        $finish;
    end

endmodule
