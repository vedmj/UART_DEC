module uart_rx (
    input  wire       clk,
    input  wire       rst,
    input  wire       rx_in,
    input  wire       tick_16x,

    output reg  [7:0] rx_data,
    output reg        rx_valid,
    output reg        rx_busy,
    output reg        framing_error
);

    // State encoding:
    // 0 = IDLE
    // 1 = START_CHECK
    // 2 = DATA_RECEIVE
    // 3 = STOP_CHECK
    // 4 = COMPLETE

    wire rx_s;

    // Two flip-flop synchronizer
    rx_synchronizer u_sync (
        .clk(clk),
        .rst(rst),
        .async_in(rx_in),
        .sync_out(rx_s)
    );

    // Internal registers
    reg [2:0] state;
    reg       rx_prev;
    reg [3:0] tcnt;
    reg [2:0] bit_idx;
    reg [7:0] shreg;
    reg       stop_ok;

    always @(posedge clk) begin

        if (rst) begin

            state         <= 3'd0;
            rx_prev       <= 1'b1;
            tcnt          <= 4'd0;
            bit_idx       <= 3'd0;
            shreg         <= 8'h00;
            stop_ok       <= 1'b0;

            rx_data       <= 8'h00;
            rx_valid      <= 1'b0;
            rx_busy       <= 1'b0;
            framing_error <= 1'b0;

        end

        else begin

            rx_valid      <= 1'b0;
            framing_error <= 1'b0;

            rx_prev <= rx_s;

            case (state)

                // STATE 0: IDLE
                3'd0: begin

                    rx_busy <= 1'b0;

                    if (rx_prev && !rx_s) begin

                        state   <= 3'd1;
                        tcnt    <= 4'd0;
                        rx_busy <= 1'b1;

                    end
                end

                // STATE 1: START_CHECK
                3'd1: begin

                    if (tick_16x) begin

                        if (tcnt == 4'd7) begin

                            if (!rx_s) begin

                                state   <= 3'd2;
                                tcnt    <= 4'd0;
                                bit_idx <= 3'd0;

                            end

                            else begin
                                state <= 3'd0;
                            end

                        end

                        else begin
                            tcnt <= tcnt + 4'd1;
                        end

                    end
                end

                // STATE 2: DATA_RECEIVE
                3'd2: begin

                    if (tick_16x) begin

                        if (tcnt == 4'd15) begin

                            shreg <= {rx_s, shreg[7:1]};

                            tcnt <= 4'd0;

                            if (bit_idx == 3'd7) begin
                                state <= 3'd3;
                            end

                            else begin
                                bit_idx <= bit_idx + 3'd1;
                            end

                        end

                        else begin
                            tcnt <= tcnt + 4'd1;
                        end

                    end
                end

                // STATE 3: STOP_CHECK
                3'd3: begin

                    if (tick_16x) begin

                        if (tcnt == 4'd15) begin

                            stop_ok <= rx_s;
                            state   <= 3'd4;

                        end

                        else begin
                            tcnt <= tcnt + 4'd1;
                        end

                    end
                end

                // STATE 4: COMPLETE
                3'd4: begin

                    rx_data       <= shreg;
                    rx_valid      <= stop_ok;
                    framing_error <= ~stop_ok;

                    state <= 3'd0;

                end

                default: begin
                    state <= 3'd0;
                end

            endcase

        end

    end

endmodule
