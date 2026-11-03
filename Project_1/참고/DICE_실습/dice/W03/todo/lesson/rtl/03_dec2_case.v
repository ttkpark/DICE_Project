module DEC2_CASE (
    input  wire [1:0] SEL,
    output reg  [3:0] Y
);
    always @(*) begin
        case (SEL)
            2'b00: Y = 4'b0000; // TODO-C01: 진리표의 1번째 출력 작성.
            2'b01: Y = 4'b0000; // TODO-C02: 진리표의 2번째 출력 작성.
            2'b10: Y = 4'b0000; // TODO-C03: 진리표의 3번째 출력 작성.
            2'b11: Y = 4'b0000; // TODO-C04: 진리표의 4번째 출력 작성.
            default: Y = 4'b0000;  // 어느 항목에도 일치하지 않을 때.
        endcase
    end
endmodule
