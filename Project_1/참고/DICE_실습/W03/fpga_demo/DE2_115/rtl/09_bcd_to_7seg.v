module BCD_TO_7SEG (/*AUTOARG*/
    // Outputs
    SEG,
    // Inputs
    BCD
);
    output reg  [6:0] SEG;
    input  wire [3:0] BCD;
    always @(*) begin
        case (BCD)
            4'd0: SEG = 7'b1000000; // 해결-S01: 숫자 0 표시.
            4'd1: SEG = 7'b1111001; // 해결-S02: 숫자 1 표시.
            4'd2: SEG = 7'b0100100; // 해결-S03: 숫자 2 표시.
            4'd3: SEG = 7'b0110000; // 해결-S04: 숫자 3 표시.
            4'd4: SEG = 7'b0011001; // 해결-S05: 숫자 4 표시.
            4'd5: SEG = 7'b0010010; // 해결-S06: 숫자 5 표시.
            4'd6: SEG = 7'b0000010; // 해결-S07: 숫자 6 표시.
            4'd7: SEG = 7'b1111000; // 해결-S08: 숫자 7 표시.
            4'd8: SEG = 7'b0000000; // 해결-S09: 숫자 8 표시.
            4'd9: SEG = 7'b0010000; // 해결-S10: 숫자 9 표시.
            default: SEG = 7'b1111111;  // 10~15, X/Z 입력은 소등.
        endcase
    end
endmodule

// Local Variables:
// verilog-auto-arg-format: single
// End:
