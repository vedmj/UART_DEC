//   IDLE : wait for parser slot; cmd_take frees it; operands LATCHED here
//   EXEC : ALU (combinational, inputs frozen) is captured into result/flags/status
//   SEND : wait until the response generator is ready, then hand over (resp_start)

module command_controller (
    input  wire        clk,
    input  wire        rst,

    // From packet_parser
    input  wire        cmd_valid,
    input  wire [1:0]  cmd_kind,
    input  wire [7:0]  cmd_opcode,
    input  wire [7:0]  cmd_a,
    input  wire [7:0]  cmd_b,
    output wire        cmd_take,

    // To / from ALU
    output reg  [7:0]  alu_a,
    output reg  [7:0]  alu_b,
    output wire [3:0]  alu_op,
    input  wire [15:0] alu_result,
    input  wire [7:0]  alu_flags,

    // Result and status registers
    output reg  [15:0] result_reg,
    output reg  [7:0]  flags_reg,
    output reg  [7:0]  status_reg,
    output reg  [7:0]  opcode_reg,

    // To response_generator
    output wire        resp_start,
    input  wire        resp_ready,
    output wire        busy
);

    // State encoding:
    // 0 = IDLE
    // 1 = EXEC
    // 2 = SEND

    // Event encoding:
    // 0 = Valid command
    // 1 = Checksum error
    // 2 = Incomplete packet

    // Status encoding:
    // 00 = Success
    // 01 = Invalid opcode
    // 02 = Checksum error
    // 03 = Incomplete packet

    reg [1:0] state;
    reg [1:0] kind_r;

    wire opc_valid;

    assign opc_valid = (opcode_reg >= 8'h01) &&
                       (opcode_reg <= 8'h0A);

    assign alu_op     = opcode_reg[3:0];

    assign cmd_take   = (state == 2'd0) && cmd_valid;

    assign resp_start = (state == 2'd2) && resp_ready;

    assign busy       = (state != 2'd0);

    always @(posedge clk) begin

        if (rst) begin

            state       <= 2'd0;
            kind_r      <= 2'd0;

            alu_a       <= 8'h00;
            alu_b       <= 8'h00;
            opcode_reg  <= 8'h00;

            result_reg  <= 16'h0000;
            flags_reg   <= 8'h00;
            status_reg  <= 8'h00;

        end

        else begin

            case (state)

                // STATE 0: IDLE
                2'd0: begin

                    if (cmd_valid) begin

                        kind_r     <= cmd_kind;
                        opcode_reg <= cmd_opcode;

                        alu_a <= cmd_a;
                        alu_b <= cmd_b;

                        state <= 2'd1;

                    end

                end

                // STATE 1: EXEC
                2'd1: begin

                    if (kind_r == 2'd1) begin

                        status_reg <= 8'h02;
                        result_reg <= 16'h0000;
                        flags_reg  <= 8'h00;

                    end

                    else if (kind_r == 2'd2) begin

                        status_reg <= 8'h03;
                        result_reg <= 16'h0000;
                        flags_reg  <= 8'h00;

                    end

                    else if (opc_valid) begin

                        status_reg <= 8'h00;
                        result_reg <= alu_result;
                        flags_reg  <= alu_flags;

                    end

                    else begin

                        status_reg <= 8'h01;
                        result_reg <= 16'h0000;
                        flags_reg  <= 8'h00;

                    end

                    state <= 2'd2;

                end

                // STATE 2: SEND
                2'd2: begin

                    if (resp_ready)
                        state <= 2'd0;

                end

                default: begin

                    state <= 2'd0;

                end

            endcase

        end

    end

endmodule

