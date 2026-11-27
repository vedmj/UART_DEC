// btnC = reset. sw[1:0] selects the 7-segment view:
//   00 result | 01 {status,flags} | 10 {A,B} of last command | 11 {8'h00,opcode}
// led[7:0] = result low byte, led[15:8] = flags {LT,GT,EQ,V,N,B,C,Z}

module top_uart_calculator #(
    parameter CLK_HZ       = 100_000_000,
    parameter BAUD         = 115_200,
    parameter PARSER_TIMEOUT = 5_000_000
)(
    input  wire        clk,
    input  wire        btnC,
    input  wire [15:0] sw,
    input  wire        RsRx,
    output wire        RsTx,
    output wire [15:0] led,
    output wire [6:0]  seg,
    output wire        dp,
    output wire [3:0]  an
);
    // ---- reset: button synchronizer + power-on reset (FFs initialise to 1)
    reg [1:0] rst_ff = 2'b11;
    always @(posedge clk) rst_ff <= {rst_ff[0], btnC};
    wire rst = rst_ff[1];

    // ---- baud timing
    wire tick_16x, tick_1x;
    baud_generator #(.CLK_HZ(CLK_HZ), .BAUD(BAUD)) u_baud (
        .clk(clk), .rst(rst), .tick_16x(tick_16x), .tick_1x(tick_1x));

    // ---- UART
    wire [7:0] rx_data;  wire rx_valid, rx_busy, rx_ferr;
    uart_rx u_rx (.clk(clk), .rst(rst), .rx_in(RsRx), .tick_16x(tick_16x),
                  .rx_data(rx_data), .rx_valid(rx_valid), .rx_busy(rx_busy),
                  .framing_error(rx_ferr));

    wire       tx_start, tx_busy, tx_done;
    wire [7:0] tx_data;
    uart_tx u_tx (.clk(clk), .rst(rst), .baud_tick(tick_1x), .tx_start(tx_start),
                  .tx_data(tx_data), .tx(RsTx), .busy(tx_busy), .done(tx_done));

    // ---- application layer
    wire       cmd_valid, cmd_take, overrun;
    wire [1:0] cmd_kind;
    wire [7:0] cmd_opcode, cmd_a, cmd_b;
    packet_parser #(.TIMEOUT_CLKS(PARSER_TIMEOUT)) u_parser (
        .clk(clk), .rst(rst), .rx_data(rx_data), .rx_valid(rx_valid),
        .cmd_take(cmd_take), .cmd_valid(cmd_valid), .cmd_kind(cmd_kind),
        .cmd_opcode(cmd_opcode), .cmd_a(cmd_a), .cmd_b(cmd_b), .overrun(overrun));

    wire [7:0]  alu_a, alu_b;  wire [3:0] alu_op;
    wire [15:0] alu_result;    wire [7:0] alu_flags;
    alu u_alu (.a(alu_a), .b(alu_b), .op(alu_op), .result(alu_result), .flags(alu_flags));

    wire [15:0] result_reg;  wire [7:0] flags_reg, status_reg, opcode_reg;
    wire        resp_start, resp_ready, ctrl_busy;
    command_controller u_ctrl (
        .clk(clk), .rst(rst),
        .cmd_valid(cmd_valid), .cmd_kind(cmd_kind), .cmd_opcode(cmd_opcode),
        .cmd_a(cmd_a), .cmd_b(cmd_b), .cmd_take(cmd_take),
        .alu_a(alu_a), .alu_b(alu_b), .alu_op(alu_op),
        .alu_result(alu_result), .alu_flags(alu_flags),
        .result_reg(result_reg), .flags_reg(flags_reg),
        .status_reg(status_reg), .opcode_reg(opcode_reg),
        .resp_start(resp_start), .resp_ready(resp_ready), .busy(ctrl_busy));

    response_generator u_resp (
        .clk(clk), .rst(rst), .start(resp_start),
        .status_in(status_reg), .result_in(result_reg), .flags_in(flags_reg),
        .ready(resp_ready), .tx_start(tx_start), .tx_data(tx_data),
        .tx_busy(tx_busy), .tx_done(tx_done));

    // ---- outputs
    reg overrun_sticky;
    always @(posedge clk) begin
        if (rst) overrun_sticky <= 1'b0;
        else if (overrun) overrun_sticky <= 1'b1;
    end

    reg [15:0] disp;
    always @* begin
        case (sw[1:0])
            2'b00:   disp = result_reg;
            2'b01:   disp = {status_reg, flags_reg};
            2'b10:   disp = {alu_a, alu_b};
            default: disp = {8'h00, opcode_reg};
        endcase
    end

    seven_segment u_seg (.clk(clk), .rst(rst), .value(disp), .seg(seg), .an(an));

    assign dp  = ~overrun_sticky;           // active low
    assign led = {flags_reg, result_reg[7:0]};
endmodule
