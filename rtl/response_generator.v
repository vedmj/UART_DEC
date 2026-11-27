//  6-byte response  5A | STATUS | RES_H | RES_L | FLAGS | CHK


module response_generator (

    input  wire        clk,
    input  wire        rst,
    input  wire        start,

    input  wire [7:0]  status_in,
    input  wire [15:0] result_in,
    input  wire [7:0]  flags_in,

    output wire        ready,

    output reg         tx_start,
    output reg  [7:0]  tx_data,

    input  wire        tx_busy,
    input  wire        tx_done

);

    reg [1:0] state;
    reg [2:0] idx;

    reg [7:0] st_r;
    reg [7:0] rh_r;
    reg [7:0] rl_r;
    reg [7:0] fl_r;

    wire [7:0] chk;

    assign chk = st_r ^ rh_r ^ rl_r ^ fl_r;

    reg [7:0] cur;

    always @* begin

        case (idx)

            3'd0: cur = 8'h5A;
            3'd1: cur = st_r;
            3'd2: cur = rh_r;
            3'd3: cur = rl_r;
            3'd4: cur = fl_r;

            default: cur = chk;

        endcase

    end

    assign ready = (state == 2'd0);

    always @(posedge clk) begin

        if (rst) begin

            state <= 2'd0;
            idx <= 3'd0;

            tx_start <= 1'b0;
            tx_data <= 8'h00;

            st_r <= 8'h00;
            rh_r <= 8'h00;
            rl_r <= 8'h00;
            fl_r <= 8'h00;

        end

        else begin

            tx_start <= 1'b0;

            case (state)

                // STATE 0: IDLE

                2'd0: begin

                    if (start) begin

                        st_r <= status_in;

                        rh_r <= result_in[15:8];
                        rl_r <= result_in[7:0];

                        fl_r <= flags_in;

                        idx <= 3'd0;

                        state <= 2'd1;

                    end

                end

                // STATE 1: LOAD

                2'd1: begin

                    if (!tx_busy) begin

                        tx_data <= cur;

                        tx_start <= 1'b1;

                        state <= 2'd2;

                    end

                end

                // STATE 2: WAIT

                2'd2: begin

                    if (tx_done) begin

                        if (idx == 3'd5) begin

                            state <= 2'd0;

                        end

                        else begin

                            idx <= idx + 3'd1;

                            state <= 2'd1;

                        end

                    end

                end

                default: begin

                    state <= 2'd0;

                end

            endcase

        end

    end

endmodule
