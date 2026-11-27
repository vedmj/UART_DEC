// flags[0]=Z zero      : result == 0              (all operations)
// flags[1]=C carry     : ADD carry-out; MUL product > 255; 
// flags[2]=B borrow    : SUB only, A < B (unsigned)
// flags[3]=N negative  : ADD/SUB only, bit 7 of 8-bit result (signed view)
// flags[4]=V overflow  : ADD/SUB only, signed 8-bit overflow
// flags[5]=EQ          : CMP only, A == B
// flags[6]=GT          : CMP only, A >  B (unsigned)
// flags[7]=LT          : CMP only, A <  B (unsigned)
// logic ops zero-extended; CMP result = 0 (A==B), 1 (A>B), 2 (A<B).


module alu (
    input  wire [7:0]  a,
    input  wire [7:0]  b,
    input  wire [3:0]  op,
    output reg  [15:0] result,
    output reg  [7:0]  flags
);

    wire [8:0] add9 = {1'b0, a} + {1'b0, b};
    wire [8:0] sub9 = {1'b0, a} - {1'b0, b};

    wire [15:0] prod = a * b;

    wire [3:0] sh = b[3:0];

    wire [23:0] shl_f = {16'h0000, a} << sh;

    wire [15:0] shr_r = {8'h00, a} >> sh;


    reg c, bo, n, v, eq, gt, lt, known;

    always @* begin

        result = 16'h0000;

        c = 1'b0;
        bo = 1'b0;
        n = 1'b0;
        v = 1'b0;
        eq = 1'b0;
        gt = 1'b0;
        lt = 1'b0;

        known = 1'b1;

        case (op)

            // ADD
            4'h1: begin
                result = {7'b0, add9};
                c = add9[8];
                n = add9[7];
                v = (a[7] == b[7]) && (add9[7] != a[7]);
            end

            // SUB
            4'h2: begin
                result = {8'h00, sub9[7:0]};
                bo = sub9[8];
                n = sub9[7];
                v = (a[7] != b[7]) && (sub9[7] != a[7]);
            end

            // MUL
            4'h3: begin
                result = prod;
                c = |prod[15:8];
            end

            // AND
            4'h4: begin
                result = {8'h00, a & b};
            end

            // OR
            4'h5: begin
                result = {8'h00, a | b};
            end

            // XOR
            4'h6: begin
                result = {8'h00, a ^ b};
            end

            // NOT
            4'h7: begin
                result = {8'h00, ~a};
            end

            // SHIFT LEFT
            4'h8: begin
                result = shl_f[15:0];
            end

            // SHIFT RIGHT
            4'h9: begin
                result = shr_r;
            end

            // COMPARE
            4'hA: begin
                eq = (a == b);
                gt = (a > b);
                lt = (a < b);

                result = eq ? 16'h0000 :
                         (gt ? 16'h0001 : 16'h0002);
            end

            default: begin
                known = 1'b0;
            end

        endcase

        flags = known ?
                {lt, gt, eq, v, n, bo, c, (result == 16'h0000)}
                : 8'h00;

    end

endmodule
