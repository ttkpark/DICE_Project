module DEC2_IF (
    input  wire [1:0] SEL,
    output reg  [3:0] Y
);
    always @(*) begin
        if (SEL == 2'b00) begin
            Y = 4'b0000; // TODO-I01: 진리표의 1번째 출력 작성.
        end
        else if (SEL == 2'b01) begin
            Y = 4'b0000; // TODO-I02: 진리표의 2번째 출력 작성.
        end
        else if (SEL == 2'b10) begin
            Y = 4'b0000; // TODO-I03: 진리표의 3번째 출력 작성.
        end
        else if (SEL == 2'b11) begin
            Y = 4'b0000; // TODO-I04: 진리표의 4번째 출력 작성.
        end
        else begin
            Y = 4'b0000;  // X/Z가 포함된 입력의 처리.
        end
    end
endmodule
