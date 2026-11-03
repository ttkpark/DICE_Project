module BIN5_TO_BCD (
    input  wire [4:0] BIN,
    output reg  [3:0] TENS,
    output reg  [3:0] ONES
);
    always @(*) begin
        // TODO-B01: 큰 값부터 비교하여 모든 분기에서 두 출력 대입.
        TENS = 4'd0;
        ONES = BIN[3:0];
            if(BIN >= 5'd30) begin
                    TENS = 4'd3;
                    ONES = BIN - 5'd30;
            end

            else if(BIN >= 5'd20) begin
                    TENS = 4'd2;
                    ONES = BIN - 5'd20;
            end
            else if(BIN >= 5'd10) begin
                    TENS = 4'd1;
                    ONES = BIN - 5'd10;
            end
            else begin
                    TENS = 4'd0;
                    ONES = BIN[3:0];
            end
    end
endmodule
