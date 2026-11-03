module MUX_FIXED (
    input  wire A,
    input  wire B,
    input  wire S,
    output reg  Y
);
    // 해결-F01: @(*)로 모든 입력 변화를 감지.
    // 해결-F02: S=0과 S=1 모두 출력 대입.
    // 이 블록이 읽는 입력이 바뀌면 출력을 다시 계산.
    always @(*) begin
        if (S == 1'b0) begin
            Y = A;  // S=0이면 A 선택.
        end
        else begin
            Y = B;  // S=1이면 B 선택.
        end
    end
endmodule
