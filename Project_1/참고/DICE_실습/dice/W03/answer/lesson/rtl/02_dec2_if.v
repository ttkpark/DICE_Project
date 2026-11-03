module DEC2_IF (
    input  wire [1:0] SEL,
    output reg  [3:0] Y
);
    always @(*) begin
        if (SEL == 2'b00) begin
            Y = 4'b0001; // 해결-I01: 진리표의 1번째 행.
        end
        else if (SEL == 2'b01) begin
            Y = 4'b0010; // 해결-I02: 진리표의 2번째 행.
        end
        else if (SEL == 2'b10) begin
            Y = 4'b0100; // 해결-I03: 진리표의 3번째 행.
        end
        else if (SEL == 2'b11) begin
            Y = 4'b1000; // 해결-I04: 진리표의 4번째 행.
        end
        else begin
            Y = 4'b0000;  // X/Z가 포함된 입력의 처리.
        end
    end
endmodule
