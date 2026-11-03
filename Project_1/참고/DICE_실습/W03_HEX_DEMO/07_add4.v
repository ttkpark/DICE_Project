module ADD4 (
    input  wire [3:0] A,
    input  wire [3:0] B,
    output reg  [4:0] SUM
);
    always @(*) begin
        SUM = {1'b0, A} + {1'b0, B}; // TODO-A01: B를 포함한 5비트 덧셈 작성.
    end
endmodule
