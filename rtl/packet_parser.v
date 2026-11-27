
// Request-packet FSM   A5 | OP | A | B | OP^A^B
//   cmd_valid  : slot holds an event; stays high until cmd_take
//   cmd_kind   : 0 = valid command, 1 = checksum error, 2 = incomplete (timeout)
//   overrun    : 1-clk pulse - a new event completed while slot was still full
//                (new event dropped, old one kept)

module packet_parser #(
    parameter [7:0] HEADER = 8'hA5,
    parameter TIMEOUT_CLKS = 5_000_000
)(
    input  wire       clk,
    input  wire       rst,
    input  wire [7:0] rx_data,
    input  wire       rx_valid,
    input  wire       cmd_take,

    output reg        cmd_valid,
    output reg  [1:0] cmd_kind,
    output reg  [7:0] cmd_opcode,
    output reg  [7:0] cmd_a,
    output reg  [7:0] cmd_b,
    output reg        overrun
);

    // State encoding:
    // 0 = S_HDR
    // 1 = S_OP
    // 2 = S_A
    // 3 = S_B
    // 4 = S_CHK

    // Event encoding:
    // 0 = Valid command
    // 1 = Checksum error
    // 2 = Incomplete packet

    reg [2:0] state;

    reg [7:0] r_op;
    reg [7:0] r_a;
    reg [7:0] r_b;

    reg [31:0] tmo_cnt;

    reg       post;
    reg [1:0] post_kind;

    wire can_post;

    assign can_post = !cmd_valid || cmd_take;

    always @(posedge clk) begin

        if (rst) begin

            state <= 3'd0;

            r_op <= 8'h00;
            r_a  <= 8'h00;
            r_b  <= 8'h00;

            tmo_cnt <= 32'd0;

            cmd_valid  <= 1'b0;
            cmd_kind   <= 2'd0;

            cmd_opcode <= 8'h00;
            cmd_a      <= 8'h00;
            cmd_b      <= 8'h00;

            overrun <= 1'b0;

            post      <= 1'b0;
            post_kind <= 2'd0;

        end

        else begin

            post      = 1'b0;
            post_kind = 2'd0;

            overrun <= 1'b0;

            if (cmd_take)
                cmd_valid <= 1'b0;

            if (state == 3'd0)
                tmo_cnt <= 32'd0;
            else
                tmo_cnt <= tmo_cnt + 32'd1;

            if (rx_valid) begin

                tmo_cnt <= 32'd0;

                case (state)

                    // STATE 0: HEADER
                    3'd0: begin

                        if (rx_data == HEADER)
                            state <= 3'd1;

                    end

                    // STATE 1: OPCODE
                    3'd1: begin

                        r_op <= rx_data;
                        state <= 3'd2;

                    end

                    // STATE 2: OPERAND A
                    3'd2: begin

                        r_a <= rx_data;
                        state <= 3'd3;

                    end

                    // STATE 3: OPERAND B
                    3'd3: begin

                        r_b <= rx_data;
                        state <= 3'd4;

                    end

                    // STATE 4: CHECKSUM
                    3'd4: begin

                        state <= 3'd0;

                        post = 1'b1;

                        if (rx_data == (r_op ^ r_a ^ r_b))
                            post_kind = 2'd0;
                        else
                            post_kind = 2'd1;

                    end

                    default: begin

                        state <= 3'd0;

                    end

                endcase

            end

            else if ((state != 3'd0) &&
                     (tmo_cnt == TIMEOUT_CLKS - 1)) begin

                state <= 3'd0;

                post = 1'b1;
                post_kind = 2'd2;

            end

            if (post) begin

                if (can_post) begin

                    cmd_valid <= 1'b1;
                    cmd_kind <= post_kind;

                    cmd_opcode <= r_op;
                    cmd_a <= r_a;
                    cmd_b <= r_b;

                end

                else begin

                    overrun <= 1'b1;

                end

            end

        end

    end

endmodule

