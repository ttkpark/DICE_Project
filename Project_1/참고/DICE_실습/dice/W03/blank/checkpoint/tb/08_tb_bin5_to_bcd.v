`timescale 1ns/1ps
// 입력 설정 → #10 대기 → 독립된 기대 상수와 비교.
// !==는 X/Z 출력도 실패로 검사. #10은 테스트벤치에서만 사용.
module tb_bin5_to_bcd;
    reg [4:0] BIN;
    wire [3:0] TENS, ONES;
    integer errors; // 실패 개수이며 합성되는 회로가 아닙니다.

    BIN5_TO_BCD u_bcd (
        .BIN(BIN),
        .TENS(TENS),
        .ONES(ONES)
    );

    initial begin
        errors = 0;

        // 0의 십진수 두 자리
        BIN = 5'd0;
        #10;
        if (TENS !== 4'd0) begin
            $display("FAIL: 0의 십진수 두 자리, TENS=%b", TENS);
            errors = errors + 1;
        end
        if (ONES !== 4'd0) begin
            $display("FAIL: 0의 십진수 두 자리, ONES=%b", ONES);
            errors = errors + 1;
        end

        // 9의 십진수 두 자리
        BIN = 5'd9;
        #10;
        if (TENS !== 4'd0) begin
            $display("FAIL: 9의 십진수 두 자리, TENS=%b", TENS);
            errors = errors + 1;
        end
        if (ONES !== 4'd9) begin
            $display("FAIL: 9의 십진수 두 자리, ONES=%b", ONES);
            errors = errors + 1;
        end

        // 10의 십진수 두 자리
        BIN = 5'd10;
        #10;
        if (TENS !== 4'd1) begin
            $display("FAIL: 10의 십진수 두 자리, TENS=%b", TENS);
            errors = errors + 1;
        end
        if (ONES !== 4'd0) begin
            $display("FAIL: 10의 십진수 두 자리, ONES=%b", ONES);
            errors = errors + 1;
        end

        // 19의 십진수 두 자리
        BIN = 5'd19;
        #10;
        if (TENS !== 4'd1) begin
            $display("FAIL: 19의 십진수 두 자리, TENS=%b", TENS);
            errors = errors + 1;
        end
        if (ONES !== 4'd9) begin
            $display("FAIL: 19의 십진수 두 자리, ONES=%b", ONES);
            errors = errors + 1;
        end

        // 20의 십진수 두 자리
        BIN = 5'd20;
        #10;
        if (TENS !== 4'd2) begin
            $display("FAIL: 20의 십진수 두 자리, TENS=%b", TENS);
            errors = errors + 1;
        end
        if (ONES !== 4'd0) begin
            $display("FAIL: 20의 십진수 두 자리, ONES=%b", ONES);
            errors = errors + 1;
        end

        // 29의 십진수 두 자리
        BIN = 5'd29;
        #10;
        if (TENS !== 4'd2) begin
            $display("FAIL: 29의 십진수 두 자리, TENS=%b", TENS);
            errors = errors + 1;
        end
        if (ONES !== 4'd9) begin
            $display("FAIL: 29의 십진수 두 자리, ONES=%b", ONES);
            errors = errors + 1;
        end

        // 30의 십진수 두 자리
        BIN = 5'd30;
        #10;
        if (TENS !== 4'd3) begin
            $display("FAIL: 30의 십진수 두 자리, TENS=%b", TENS);
            errors = errors + 1;
        end
        if (ONES !== 4'd0) begin
            $display("FAIL: 30의 십진수 두 자리, ONES=%b", ONES);
            errors = errors + 1;
        end

        // 31의 십진수 두 자리
        BIN = 5'd31;
        #10;
        if (TENS !== 4'd3) begin
            $display("FAIL: 31의 십진수 두 자리, TENS=%b", TENS);
            errors = errors + 1;
        end
        if (ONES !== 4'd1) begin
            $display("FAIL: 31의 십진수 두 자리, ONES=%b", ONES);
            errors = errors + 1;
        end

        if (errors == 0) $display("PASS: BIN5_TO_BCD");
        else             $display("FAIL: BIN5_TO_BCD, errors=%d", errors);
        $finish;
    end
    // VCS 실행 시 파형 저장. 기존 입력과 검사 코드는 그대로 유지합니다.
`ifdef DUMP_FSDB
    initial begin
        $fsdbDumpfile("build/bin5_to_bcd/waves.fsdb");
        $fsdbDumpvars(0, tb_bin5_to_bcd);
    end
`endif
endmodule
