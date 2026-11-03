module BCD_TO_7SEG (
    input  wire [3:0] BCD,
    output reg  [6:0] SEG
);
    always @(*) begin
        case (BCD)
            4'd0: SEG = 7'b1000000; // TODO-S01: 숫자 0의 패턴 작성.
            4'd1: SEG = 7'b1111001; // TODO-S02: 숫자 1의 패턴 작성.
            4'd2: SEG = 7'b0100100; // TODO-S03: 숫자 2의 패턴 작성.
            4'd3: SEG = 7'b0110000; // TODO-S04: 숫자 3의 패턴 작성.
            4'd4: SEG = 7'b0011001; // TODO-S05: 숫자 4의 패턴 작성.
            4'd5: SEG = 7'b0010010; // TODO-S06: 숫자 5의 패턴 작성.
            4'd6: SEG = 7'b0000010; // TODO-S07: 숫자 6의 패턴 작성.
            4'd7: SEG = 7'b1111000; // TODO-S08: 숫자 7의 패턴 작성.
            4'd8: SEG = 7'b0000000; // TODO-S09: 숫자 8의 패턴 작성.
            4'd9: SEG = 7'b0010000; // TODO-S10: 숫자 9의 패턴 작성.
            default: SEG = 7'b1111111;  // 10~15, X/Z 입력은 소등.
        endcase
    end
endmodule
