`timescale 1ns/1ps
// 입력 설정 → #10 대기 → 독립된 기대 상수와 비교.
// !==는 X/Z 출력도 실패로 검사. #10은 테스트벤치에서만 사용.
module tb_lookup;
    reg [1:0] SEL;
    wire [3:0] Y_IF, Y_CASE;
    integer errors; // 실패 개수이며 합성되는 회로가 아닙니다.

    DEC2_IF u_if (
        .SEL(SEL),
        .Y(Y_IF)
    );
    DEC2_CASE u_case (
        .SEL(SEL),
        .Y(Y_CASE)
    );

    initial begin
        errors = 0;

        // SEL=00
        SEL = 2'b00;
        #10;
        if (Y_IF !== 4'b0001) begin
            $display("FAIL: SEL=00, Y_IF=%b", Y_IF);
            errors = errors + 1;
        end
        if (Y_CASE !== 4'b0001) begin
            $display("FAIL: SEL=00, Y_CASE=%b", Y_CASE);
            errors = errors + 1;
        end

        // SEL=01
        SEL = 2'b01;
        #10;
        if (Y_IF !== 4'b0010) begin
            $display("FAIL: SEL=01, Y_IF=%b", Y_IF);
            errors = errors + 1;
        end
        if (Y_CASE !== 4'b0010) begin
            $display("FAIL: SEL=01, Y_CASE=%b", Y_CASE);
            errors = errors + 1;
        end

        // SEL=10
        SEL = 2'b10;
        #10;
        if (Y_IF !== 4'b0100) begin
            $display("FAIL: SEL=10, Y_IF=%b", Y_IF);
            errors = errors + 1;
        end
        if (Y_CASE !== 4'b0100) begin
            $display("FAIL: SEL=10, Y_CASE=%b", Y_CASE);
            errors = errors + 1;
        end

        // SEL=11
        SEL = 2'b11;
        #10;
        if (Y_IF !== 4'b1000) begin
            $display("FAIL: SEL=11, Y_IF=%b", Y_IF);
            errors = errors + 1;
        end
        if (Y_CASE !== 4'b1000) begin
            $display("FAIL: SEL=11, Y_CASE=%b", Y_CASE);
            errors = errors + 1;
        end

        // SEL=xx
        SEL = 2'bxx;
        #10;
        if (Y_IF !== 4'b0000) begin
            $display("FAIL: SEL=xx, Y_IF=%b", Y_IF);
            errors = errors + 1;
        end
        if (Y_CASE !== 4'b0000) begin
            $display("FAIL: SEL=xx, Y_CASE=%b", Y_CASE);
            errors = errors + 1;
        end

        if (errors == 0) $display("PASS: LOOKUP");
        else             $display("FAIL: LOOKUP, errors=%d", errors);
        $finish;
    end
    // VCS 실행 시 파형 저장. 기존 입력과 검사 코드는 그대로 유지합니다.
`ifdef DUMP_FSDB
    initial begin
        $fsdbDumpfile("build/lookup/waves.fsdb");
        $fsdbDumpvars(0, tb_lookup);
    end
`endif
endmodule
