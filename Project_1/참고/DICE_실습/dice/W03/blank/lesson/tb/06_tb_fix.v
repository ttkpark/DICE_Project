`timescale 1ns/1ps
// 입력 설정 → #10 대기 → 독립된 기대 상수와 비교.
// !==는 X/Z 출력도 실패로 검사. #10은 테스트벤치에서만 사용.
module tb_fix;
    reg A, B, S;
    wire Y_SENS, Y_ASSIGN, Y_FIXED;
    integer errors; // 실패 개수이며 합성되는 회로가 아닙니다.

    MUX_BAD_SENSITIVITY u_y_sens (
        .A(A),
        .B(B),
        .S(S),
        .Y(Y_SENS)
    );
    MUX_BAD_ASSIGNMENT u_y_assign (
        .A(A),
        .B(B),
        .S(S),
        .Y(Y_ASSIGN)
    );
    MUX_FIXED u_y_fixed (
        .A(A),
        .B(B),
        .S(S),
        .Y(Y_FIXED)
    );

    initial begin
        errors = 0;

        // 초기 출력
        A = 1'b0;
        B = 1'b0;
        S = 1'b1;
        #10;
        $display("OBSERVE: BAD_SENSITIVITY=%b BAD_ASSIGNMENT=%b FIXED=%b", Y_SENS, Y_ASSIGN, Y_FIXED);
        if (Y_FIXED !== 1'b0) begin
            $display("FAIL: 초기 출력, Y_FIXED=%b", Y_FIXED);
            errors = errors + 1;
        end

        // B만 변경: 감도 목록 오류 관찰
        B = 1'b1;
        #10;
        $display("OBSERVE: BAD_SENSITIVITY=%b BAD_ASSIGNMENT=%b FIXED=%b", Y_SENS, Y_ASSIGN, Y_FIXED);
        if (Y_FIXED !== 1'b1) begin
            $display("FAIL: B만 변경: 감도 목록 오류 관찰, Y_FIXED=%b", Y_FIXED);
            errors = errors + 1;
        end

        // S만 변경: 출력 미대입 오류 관찰
        S = 1'b0;
        #10;
        $display("OBSERVE: BAD_SENSITIVITY=%b BAD_ASSIGNMENT=%b FIXED=%b", Y_SENS, Y_ASSIGN, Y_FIXED);
        if (Y_FIXED !== 1'b0) begin
            $display("FAIL: S만 변경: 출력 미대입 오류 관찰, Y_FIXED=%b", Y_FIXED);
            errors = errors + 1;
        end

        if (errors == 0) $display("PASS: FIXED");
        else             $display("FAIL: FIXED, errors=%d", errors);
        $finish;
    end
    // VCS 실행 시 파형 저장. 기존 입력과 검사 코드는 그대로 유지합니다.
`ifdef DUMP_FSDB
    initial begin
        $fsdbDumpfile("build/fix/waves.fsdb");
        $fsdbDumpvars(0, tb_fix);
    end
`endif
endmodule
