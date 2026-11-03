module W03_TOP (
    input  wire [7:0] SW,
    output wire [6:0] HEX0,
    output wire [6:0] HEX1
);
    wire [4:0] SUM;
    wire [3:0] TENS, ONES;

    ADD4 add(.A(SW[3:0]), .B(SW[7:4]), .SUM(SUM)); //4' 4' 5'
    BIN5_TO_BCD bcd(.BIN(SUM), .TENS(TENS), .ONES(ONES));// 5' 4' 4'
    BCD_TO_7SEG(.BCD(TENS), .SEG(HEX1)); //4' 7'
    BCD_TO_7SEG(.BCD(ONES), .SEG(HEX0)); //4' 7'

endmodule
