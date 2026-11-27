module uart_tx (

    input  wire       clk,
    input  wire       rst,
    input  wire       baud_tick,
    input  wire       tx_start,
    input  wire [7:0] tx_data,

    output reg        tx,
    output reg        busy,
    output reg        done

);

    // State encoding:
    // 0 = IDLE
    // 1 = START
    // 2 = DATA
    // 3 = STOP

    reg [1:0] state;

    reg [7:0] shreg;
    reg [3:0] idx;

    always @(posedge clk) begin

        if (rst) begin

            state <= 2'd0;

            tx    <= 1'b1;
            busy  <= 1'b0;
            done  <= 1'b0;

            shreg <= 8'h00;
            idx   <= 4'd0;

        end

        else begin

            done <= 1'b0;

            case (state)

                // STATE 0: IDLE

                2'd0: begin

                    tx <= 1'b1;

                    if (tx_start) begin

                        shreg <= tx_data;

                        busy <= 1'b1;

                        state <= 2'd1;

                    end

                end

                // STATE 1: START

                2'd1: begin

                    if (baud_tick) begin

                        tx <= 1'b0;

                        idx <= 4'd0;

                        state <= 2'd2;

                    end

                end

                // STATE 2: DATA

                2'd2: begin

                    if (baud_tick) begin

                        if (idx < 4'd8) begin

                            tx <= shreg[0];

                            shreg <= {1'b0, shreg[7:1]};

                            idx <= idx + 4'd1;

                        end

                        else begin

                            tx <= 1'b1;

                            state <= 2'd3;

                        end

                    end

                end

                // STATE 3: STOP

                2'd3: begin

                    if (baud_tick) begin

                        busy <= 1'b0;

                        done <= 1'b1;

                        state <= 2'd0;

                    end

                end

                // DEFAULT STATE

                default: begin

                    state <= 2'd0;

                    tx <= 1'b1;

                    busy <= 1'b0;

                end

            endcase

        end

    end

endmodule

