`timescale 1ns/1ps
// 입력 설정 → #10 대기 → 독립된 기대 상수와 비교.
// !==는 X/Z 출력도 실패로 검사. #10은 테스트벤치에서만 사용.
module tb_bcd_to_7seg;
    reg [3:0] BCD;
    wire [6:0] SEG;
    integer errors; // 실패 개수이며 합성되는 회로가 아닙니다.

    BCD_TO_7SEG u_seg (
        .BCD(BCD),
        .SEG(SEG)
    );

    initial begin
        errors = 0;

        // BCD=4'd0
        BCD = 4'd0;
        #10;
        if (SEG !== 7'b1000000) begin
            $display("FAIL: BCD=4'd0, SEG=%b", SEG);
            errors = errors + 1;
        end

        // BCD=4'd1
        BCD = 4'd1;
        #10;
        if (SEG !== 7'b1111001) begin
            $display("FAIL: BCD=4'd1, SEG=%b", SEG);
            errors = errors + 1;
        end

        // BCD=4'd2
        BCD = 4'd2;
        #10;
        if (SEG !== 7'b0100100) begin
            $display("FAIL: BCD=4'd2, SEG=%b", SEG);
            errors = errors + 1;
        end

        // BCD=4'd3
        BCD = 4'd3;
        #10;
        if (SEG !== 7'b0110000) begin
            $display("FAIL: BCD=4'd3, SEG=%b", SEG);
            errors = errors + 1;
        end

        // BCD=4'd4
        BCD = 4'd4;
        #10;
        if (SEG !== 7'b0011001) begin
            $display("FAIL: BCD=4'd4, SEG=%b", SEG);
            errors = errors + 1;
        end

        // BCD=4'd5
        BCD = 4'd5;
        #10;
        if (SEG !== 7'b0010010) begin
            $display("FAIL: BCD=4'd5, SEG=%b", SEG);
            errors = errors + 1;
        end

        // BCD=4'd6
        BCD = 4'd6;
        #10;
        if (SEG !== 7'b0000010) begin
            $display("FAIL: BCD=4'd6, SEG=%b", SEG);
            errors = errors + 1;
        end

        // BCD=4'd7
        BCD = 4'd7;
        #10;
        if (SEG !== 7'b1111000) begin
            $display("FAIL: BCD=4'd7, SEG=%b", SEG);
            errors = errors + 1;
        end

        // BCD=4'd8
        BCD = 4'd8;
        #10;
        if (SEG !== 7'b0000000) begin
            $display("FAIL: BCD=4'd8, SEG=%b", SEG);
            errors = errors + 1;
        end

        // BCD=4'd9
        BCD = 4'd9;
        #10;
        if (SEG !== 7'b0010000) begin
            $display("FAIL: BCD=4'd9, SEG=%b", SEG);
            errors = errors + 1;
        end

        // BCD=4'd10
        BCD = 4'd10;
        #10;
        if (SEG !== 7'b1111111) begin
            $display("FAIL: BCD=4'd10, SEG=%b", SEG);
            errors = errors + 1;
        end

        // BCD=4'd15
        BCD = 4'd15;
        #10;
        if (SEG !== 7'b1111111) begin
            $display("FAIL: BCD=4'd15, SEG=%b", SEG);
            errors = errors + 1;
        end

        // BCD=4'bxxxx
        BCD = 4'bxxxx;
        #10;
        if (SEG !== 7'b1111111) begin
            $display("FAIL: BCD=4'bxxxx, SEG=%b", SEG);
            errors = errors + 1;
        end

        if (errors == 0) $display("PASS: BCD_TO_7SEG");
        else             $display("FAIL: BCD_TO_7SEG, errors=%d", errors);
        $finish;
    end
    // VCS 실행 시 파형 저장. 기존 입력과 검사 코드는 그대로 유지합니다.
`ifdef DUMP_FSDB
    initial begin
        $fsdbDumpfile("build/bcd_to_7seg/waves.fsdb");
        $fsdbDumpvars(0, tb_bcd_to_7seg);
    end
`endif
endmodule
