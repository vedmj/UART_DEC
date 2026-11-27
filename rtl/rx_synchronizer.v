//  2-flip-flop synchronizer for an asynchronous input



module rx_synchronizer (
    input  wire clk,
    input  wire rst,
    input  wire async_in,
    output wire sync_out
);

    reg [1:0] ff;

    always @(posedge clk) begin
        if (rst)
            ff <= 2'b11;
        else
            ff <= {ff[0], async_in};
    end

    assign sync_out = ff[1];

endmodule
