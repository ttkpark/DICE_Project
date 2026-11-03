`timescale 1ns/1ps
module tb_add4;
    // TB가 값을 넣는 입력은 reg, 회로에서 받아 보는 출력은 wire.
    reg  [3:0] A;
    reg  [3:0] B;
    wire [4:0] SUM;
    integer errors;  // 틀린 검사 개수. 회로의 일부가 아님.

    ADD4 u_add4 (
        .A(A),
        .B(B),
        .SUM(SUM)
    );

    initial begin
        errors = 0;

        // ① 입력 설정 → ② 계산을 기다림 → ③ 기대값과 비교.
        A = 4'd0;
        B = 4'd0;
        #10;
        if (SUM !== 5'd0) begin
            $display("FAIL: 0+0, SUM=%d", SUM);
            errors = errors + 1;
        end

        A = 4'd3;
        B = 4'd5;
        #10;
        if (SUM !== 5'd8) begin
            $display("FAIL: 3+5, SUM=%d", SUM);
            errors = errors + 1;
        end

        // 4비트만 저장하면 16을 표현하지 못하므로 자리올림 검사.
        A = 4'd15;
        B = 4'd1;
        #10;
        if (SUM !== 5'd16) begin
            $display("FAIL: 15+1, SUM=%d", SUM);
            errors = errors + 1;
        end

        A = 4'd15;
        B = 4'd15;
        #10;
        if (SUM !== 5'd30) begin
            $display("FAIL: 15+15, SUM=%d", SUM);
            errors = errors + 1;
        end

        if (errors == 0) $display("PASS: ADD4");
        else             $display("FAIL: ADD4, errors=%d", errors);
        $finish;
    end
    // VCS 실행 시 파형 저장. 기존 입력과 검사 코드는 그대로 유지합니다.
`ifdef DUMP_FSDB
    initial begin
        $fsdbDumpfile("build/add4/waves.fsdb");
        $fsdbDumpvars(0, tb_add4);
    end
`endif
endmodule
