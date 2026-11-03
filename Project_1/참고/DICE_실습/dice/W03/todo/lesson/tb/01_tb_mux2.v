`timescale 1ns/1ps
// 입력 설정 → #10 대기 → 독립된 기대 상수와 비교.
// !==는 X/Z 출력도 실패로 검사. #10은 테스트벤치에서만 사용.
module tb_mux2;
    reg A, B, S;
    wire Y;
    integer errors; // 실패 개수이며 합성되는 회로가 아닙니다.

    MUX2 u_mux (
        .A(A),
        .B(B),
        .S(S),
        .Y(Y)
    );

    initial begin
        errors = 0;

        // A=0, B=1, S=0
        A = 1'b0;
        B = 1'b1;
        S = 1'b0;
        #10;
        if (Y !== 1'b0) begin
            $display("FAIL: A=0, B=1, S=0, Y=%b", Y);
            errors = errors + 1;
        end

        // A=0, B=1, S=1
        A = 1'b0;
        B = 1'b1;
        S = 1'b1;
        #10;
        if (Y !== 1'b1) begin
            $display("FAIL: A=0, B=1, S=1, Y=%b", Y);
            errors = errors + 1;
        end

        // A=1, B=0, S=0
        A = 1'b1;
        B = 1'b0;
        S = 1'b0;
        #10;
        if (Y !== 1'b1) begin
            $display("FAIL: A=1, B=0, S=0, Y=%b", Y);
            errors = errors + 1;
        end

        // A=1, B=0, S=1
        A = 1'b1;
        B = 1'b0;
        S = 1'b1;
        #10;
        if (Y !== 1'b0) begin
            $display("FAIL: A=1, B=0, S=1, Y=%b", Y);
            errors = errors + 1;
        end

        if (errors == 0) $display("PASS: MUX2");
        else             $display("FAIL: MUX2, errors=%d", errors);
        $finish;
    end
    // VCS 실행 시 파형 저장. 기존 입력과 검사 코드는 그대로 유지합니다.
`ifdef DUMP_FSDB
    initial begin
        $fsdbDumpfile("build/mux2/waves.fsdb");
        $fsdbDumpvars(0, tb_mux2);
    end
`endif
endmodule
