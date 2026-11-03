module MUX_FIXED (
    input wire A,
    input wire B,
    input wire S,
    output reg Y
);
    // TODO-F01: 읽는 모든 입력 변화에 반응하도록 감도 목록 수정.
    // TODO-F02: S=0일 때도 출력이 대입되도록 분기 추가.
    always @(A or S) begin
        if (S) Y = B;
    end
endmodule
