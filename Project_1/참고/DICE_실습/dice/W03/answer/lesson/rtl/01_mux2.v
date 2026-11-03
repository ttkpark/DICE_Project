module MUX2 (
    input  wire A,
    input  wire B,
    input  wire S,
    output reg  Y
);
    // 이 블록이 읽는 입력이 바뀌면 출력을 다시 계산.
    always @(*) begin
        if (S == 1'b0) begin
            Y = A;  // S=0이면 A 선택.
        end
        else begin
            // 해결-M01: S=1이면 B를 선택.
            Y = B;  // S=1이면 B 선택.
        end
    end
endmodule
