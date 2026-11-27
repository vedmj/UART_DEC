//   tick_16x : 1-clk pulse at 16 x BAUD   (used by the receiver for oversampling)
//   tick_1x  : 1-clk pulse at 1  x BAUD   (used by the transmitter)
// Accumulator step INC = round(16*BAUD*2^ACC_W / CLK_HZ); 



module baud_generator #(
    parameter CLK_HZ = 100_000_000,
    parameter BAUD   = 115_200,
    parameter ACC_W  = 24
)(
    input  wire clk,
    input  wire rst,
    output wire tick_16x,
    output wire tick_1x
);

    wire [ACC_W-1:0] INC;

    assign INC =
        ((64'd16 * BAUD * (64'd1 << ACC_W)) + (CLK_HZ / 2)) / CLK_HZ;

    reg [ACC_W-1:0] acc;
    reg             tick16_r;
    reg [3:0]       cnt16;

    wire [ACC_W:0] sum;

    assign sum = {1'b0, acc} + {1'b0, INC};

    always @(posedge clk) begin

        if (rst) begin
            acc      <= {ACC_W{1'b0}};
            tick16_r <= 1'b0;
            cnt16    <= 4'd0;
        end

        else begin
            acc      <= sum[ACC_W-1:0];
            tick16_r <= sum[ACC_W];

            if (tick16_r)
                cnt16 <= cnt16 + 4'd1;
        end

    end

    assign tick_16x = tick16_r;
    assign tick_1x  = tick16_r & (cnt16 == 4'd15);

endmodule
