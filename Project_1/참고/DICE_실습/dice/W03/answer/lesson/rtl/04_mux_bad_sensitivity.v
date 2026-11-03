module MUX_BAD_SENSITIVITY (
    input wire A,
    input wire B,
    input wire S,
    output reg Y
);
    // 관찰용 오류 원본: 보존하고 06_mux_fixed.v에서 수정하세요.
    always @(A or S) begin
        if (S) Y = B;
        else   Y = A;
    end
endmodule
