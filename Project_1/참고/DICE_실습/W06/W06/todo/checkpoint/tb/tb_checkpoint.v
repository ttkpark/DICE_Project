`timescale 1ns/1ps
// 파형: clk reset we3 a1 a2 a3 wd3 rd1 rd2. 주소는 unsigned decimal 권장.
module tb_checkpoint;
    reg clk;
    reg reset;
    reg we3;
    reg [4:0] a1;
    reg [4:0] a2;
    reg [4:0] a3;
    reg [31:0] wd3;
    wire [31:0] rd1;
    wire [31:0] rd2;

    /* REGFILE AUTO_TEMPLATE (
        .RD1(rd1[]),
        .RD2(rd2[]),
        .CLK(clk),
        .RESET(reset),
        .WE3(we3),
        .A1(a1[]),
        .A2(a2[]),
        .A3(a3[]),
        .WD3(wd3[]),
    ); */
    REGFILE dut (/*AUTOINST*/
        // Outputs
        .RD1   (rd1),
        .RD2   (rd2),
        // Inputs
        .CLK   (clk),
        .RESET (reset),
        .WE3   (we3),
        .A1    (a1),
        .A2    (a2),
        .A3    (a3),
        .WD3   (wd3)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk; // 주기 10ns, 상승 에지는 5, 15, 25, ... ns.

    // 모든 자극과 검사는 이 순차 initial 블록 하나에서 실행합니다.
    initial begin
        $dumpfile("build/checkpoint.vcd");
        $dumpvars(0, tb_checkpoint);
`ifdef DUMP_FSDB
        // 실제 vcs_queue --fsdb가 +define+DUMP_FSDB를 추가합니다.
        $fsdbDumpfile("build/checkpoint.fsdb");
        $fsdbDumpvars(0, tb_checkpoint);
`endif
        reset = 1'b0; // active-high 리셋. 0이면 정상 동작.
        we3 = 1'b0; // 다음 상승 에지의 쓰기 허용 여부.
        a1 = 5'd1; // 첫 읽기 포트의 레지스터 번호.
        a2 = 5'd31; // 두 번째 읽기 포트의 레지스터 번호.
        a3 = 5'd0; // 쓰기 대상 번호. 읽기 주소와 독립적입니다.
        wd3 = 32'd0; // 저장할 32비트 데이터.
        #2;
        reset = 1'b1;
        #1; // 다음 상승 에지를 기다리지 않고 조합 읽기를 검사합니다.
        // C01: 최초 비동기 리셋: x1, x31
        if (rd1 !== 32'd0) $fatal(1, "FAIL C01 RD1 expected=%h actual=%h", 32'd0, rd1);
        if (rd2 !== 32'd0) $fatal(1, "FAIL C01 RD2 expected=%h actual=%h", 32'd0, rd2);
        $display("C01 OK t=%0t RD1=%h RD2=%h", $time, rd1, rd2);

        @(negedge clk); // 입력은 쓰기 상승 에지와 겹치지 않게 준비합니다.
        reset = 1'b1; // active-high 리셋. 0이면 정상 동작.
        we3 = 1'b1; // 다음 상승 에지의 쓰기 허용 여부.
        a1 = 5'd1; // 첫 읽기 포트의 레지스터 번호.
        a2 = 5'd31; // 두 번째 읽기 포트의 레지스터 번호.
        a3 = 5'd1; // 쓰기 대상 번호. 읽기 주소와 독립적입니다.
        wd3 = 32'd99; // 저장할 32비트 데이터.
        @(posedge clk);
        #1; // non-blocking 갱신이 끝난 뒤 두 출력을 검사합니다.
        // C02: RESET=1인 동안 쓰기를 시도해도 리셋 우선
        if (rd1 !== 32'd0) $fatal(1, "FAIL C02 RD1 expected=%h actual=%h", 32'd0, rd1);
        if (rd2 !== 32'd0) $fatal(1, "FAIL C02 RD2 expected=%h actual=%h", 32'd0, rd2);
        $display("C02 OK t=%0t RD1=%h RD2=%h", $time, rd1, rd2);

        @(negedge clk); // 입력은 쓰기 상승 에지와 겹치지 않게 준비합니다.
        reset = 1'b0; // active-high 리셋. 0이면 정상 동작.
        we3 = 1'b1; // 다음 상승 에지의 쓰기 허용 여부.
        a1 = 5'd1; // 첫 읽기 포트의 레지스터 번호.
        a2 = 5'd2; // 두 번째 읽기 포트의 레지스터 번호.
        a3 = 5'd1; // 쓰기 대상 번호. 읽기 주소와 독립적입니다.
        wd3 = 32'd10; // 저장할 32비트 데이터.
        @(posedge clk);
        #1; // non-blocking 갱신이 끝난 뒤 두 출력을 검사합니다.
        // C03: x1 쓰기, x2 독립성
        if (rd1 !== 32'd10) $fatal(1, "FAIL C03 RD1 expected=%h actual=%h", 32'd10, rd1);
        if (rd2 !== 32'd0) $fatal(1, "FAIL C03 RD2 expected=%h actual=%h", 32'd0, rd2);
        $display("C03 OK t=%0t RD1=%h RD2=%h", $time, rd1, rd2);

        @(negedge clk); // 입력은 쓰기 상승 에지와 겹치지 않게 준비합니다.
        reset = 1'b0; // active-high 리셋. 0이면 정상 동작.
        we3 = 1'b1; // 다음 상승 에지의 쓰기 허용 여부.
        a1 = 5'd1; // 첫 읽기 포트의 레지스터 번호.
        a2 = 5'd2; // 두 번째 읽기 포트의 레지스터 번호.
        a3 = 5'd2; // 쓰기 대상 번호. 읽기 주소와 독립적입니다.
        wd3 = 32'd20; // 저장할 32비트 데이터.
        @(posedge clk);
        #1; // non-blocking 갱신이 끝난 뒤 두 출력을 검사합니다.
        // C04: x2 쓰기, x1 유지
        if (rd1 !== 32'd10) $fatal(1, "FAIL C04 RD1 expected=%h actual=%h", 32'd10, rd1);
        if (rd2 !== 32'd20) $fatal(1, "FAIL C04 RD2 expected=%h actual=%h", 32'd20, rd2);
        $display("C04 OK t=%0t RD1=%h RD2=%h", $time, rd1, rd2);

        @(negedge clk); // 입력은 쓰기 상승 에지와 겹치지 않게 준비합니다.
        reset = 1'b0; // active-high 리셋. 0이면 정상 동작.
        we3 = 1'b0; // 다음 상승 에지의 쓰기 허용 여부.
        a1 = 5'd1; // 첫 읽기 포트의 레지스터 번호.
        a2 = 5'd2; // 두 번째 읽기 포트의 레지스터 번호.
        a3 = 5'd1; // 쓰기 대상 번호. 읽기 주소와 독립적입니다.
        wd3 = 32'd99; // 저장할 32비트 데이터.
        @(posedge clk);
        #1; // non-blocking 갱신이 끝난 뒤 두 출력을 검사합니다.
        // C05: WE3=0: 삭제나 갱신 없이 유지
        if (rd1 !== 32'd10) $fatal(1, "FAIL C05 RD1 expected=%h actual=%h", 32'd10, rd1);
        if (rd2 !== 32'd20) $fatal(1, "FAIL C05 RD2 expected=%h actual=%h", 32'd20, rd2);
        $display("C05 OK t=%0t RD1=%h RD2=%h", $time, rd1, rd2);

        @(negedge clk); // 입력은 쓰기 상승 에지와 겹치지 않게 준비합니다.
        reset = 1'b0; // active-high 리셋. 0이면 정상 동작.
        we3 = 1'b0; // 다음 상승 에지의 쓰기 허용 여부.
        a1 = 5'd2; // 첫 읽기 포트의 레지스터 번호.
        a2 = 5'd1; // 두 번째 읽기 포트의 레지스터 번호.
        a3 = 5'd1; // 쓰기 대상 번호. 읽기 주소와 독립적입니다.
        wd3 = 32'd99; // 저장할 32비트 데이터.
        #1; // 다음 상승 에지를 기다리지 않고 조합 읽기를 검사합니다.
        // C06: 조합 읽기 주소 교환
        if (rd1 !== 32'd20) $fatal(1, "FAIL C06 RD1 expected=%h actual=%h", 32'd20, rd1);
        if (rd2 !== 32'd10) $fatal(1, "FAIL C06 RD2 expected=%h actual=%h", 32'd10, rd2);
        $display("C06 OK t=%0t RD1=%h RD2=%h", $time, rd1, rd2);

        @(negedge clk); // 입력은 쓰기 상승 에지와 겹치지 않게 준비합니다.
        reset = 1'b0; // active-high 리셋. 0이면 정상 동작.
        we3 = 1'b0; // 다음 상승 에지의 쓰기 허용 여부.
        a1 = 5'd31; // 첫 읽기 포트의 레지스터 번호.
        a2 = 5'd1; // 두 번째 읽기 포트의 레지스터 번호.
        a3 = 5'd1; // 쓰기 대상 번호. 읽기 주소와 독립적입니다.
        wd3 = 32'd99; // 저장할 32비트 데이터.
        #1; // 다음 상승 에지를 기다리지 않고 조합 읽기를 검사합니다.
        // C07: A1만 변경: RD2 독립성
        if (rd1 !== 32'd0) $fatal(1, "FAIL C07 RD1 expected=%h actual=%h", 32'd0, rd1);
        if (rd2 !== 32'd10) $fatal(1, "FAIL C07 RD2 expected=%h actual=%h", 32'd10, rd2);
        $display("C07 OK t=%0t RD1=%h RD2=%h", $time, rd1, rd2);

        @(negedge clk); // 입력은 쓰기 상승 에지와 겹치지 않게 준비합니다.
        reset = 1'b0; // active-high 리셋. 0이면 정상 동작.
        we3 = 1'b1; // 다음 상승 에지의 쓰기 허용 여부.
        a1 = 5'd1; // 첫 읽기 포트의 레지스터 번호.
        a2 = 5'd1; // 두 번째 읽기 포트의 레지스터 번호.
        a3 = 5'd1; // 쓰기 대상 번호. 읽기 주소와 독립적입니다.
        wd3 = 32'd99; // 저장할 32비트 데이터.
        #1; // 다음 상승 에지를 기다리지 않고 조합 읽기를 검사합니다.
        // C08: 같은 주소의 에지 전 이전 값
        if (rd1 !== 32'd10) $fatal(1, "FAIL C08 RD1 expected=%h actual=%h", 32'd10, rd1);
        if (rd2 !== 32'd10) $fatal(1, "FAIL C08 RD2 expected=%h actual=%h", 32'd10, rd2);
        $display("C08 OK t=%0t RD1=%h RD2=%h", $time, rd1, rd2);

        @(posedge clk);
        #1; // non-blocking 갱신이 끝난 뒤 두 출력을 검사합니다.
        // C09: 같은 주소의 NBA 후 새 값
        if (rd1 !== 32'd99) $fatal(1, "FAIL C09 RD1 expected=%h actual=%h", 32'd99, rd1);
        if (rd2 !== 32'd99) $fatal(1, "FAIL C09 RD2 expected=%h actual=%h", 32'd99, rd2);
        $display("C09 OK t=%0t RD1=%h RD2=%h", $time, rd1, rd2);

        @(negedge clk); // 입력은 쓰기 상승 에지와 겹치지 않게 준비합니다.
        reset = 1'b0; // active-high 리셋. 0이면 정상 동작.
        we3 = 1'b1; // 다음 상승 에지의 쓰기 허용 여부.
        a1 = 5'd0; // 첫 읽기 포트의 레지스터 번호.
        a2 = 5'd1; // 두 번째 읽기 포트의 레지스터 번호.
        a3 = 5'd0; // 쓰기 대상 번호. 읽기 주소와 독립적입니다.
        wd3 = 32'hFFFFFFFF; // 저장할 32비트 데이터.
        @(posedge clk);
        #1; // non-blocking 갱신이 끝난 뒤 두 출력을 검사합니다.
        // C10: x0 쓰기 시도 무시
        if (rd1 !== 32'd0) $fatal(1, "FAIL C10 RD1 expected=%h actual=%h", 32'd0, rd1);
        if (rd2 !== 32'd99) $fatal(1, "FAIL C10 RD2 expected=%h actual=%h", 32'd99, rd2);
        $display("C10 OK t=%0t RD1=%h RD2=%h", $time, rd1, rd2);

        @(negedge clk); // 입력은 쓰기 상승 에지와 겹치지 않게 준비합니다.
        reset = 1'b0; // active-high 리셋. 0이면 정상 동작.
        we3 = 1'b0; // 다음 상승 에지의 쓰기 허용 여부.
        a1 = 5'd1; // 첫 읽기 포트의 레지스터 번호.
        a2 = 5'd0; // 두 번째 읽기 포트의 레지스터 번호.
        a3 = 5'd0; // 쓰기 대상 번호. 읽기 주소와 독립적입니다.
        wd3 = 32'hFFFFFFFF; // 저장할 32비트 데이터.
        #1; // 다음 상승 에지를 기다리지 않고 조합 읽기를 검사합니다.
        // C11: 두 번째 읽기 포트에서도 x0=0
        if (rd1 !== 32'd99) $fatal(1, "FAIL C11 RD1 expected=%h actual=%h", 32'd99, rd1);
        if (rd2 !== 32'd0) $fatal(1, "FAIL C11 RD2 expected=%h actual=%h", 32'd0, rd2);
        $display("C11 OK t=%0t RD1=%h RD2=%h", $time, rd1, rd2);

        @(negedge clk); // 입력은 쓰기 상승 에지와 겹치지 않게 준비합니다.
        reset = 1'b0; // active-high 리셋. 0이면 정상 동작.
        we3 = 1'b1; // 다음 상승 에지의 쓰기 허용 여부.
        a1 = 5'd31; // 첫 읽기 포트의 레지스터 번호.
        a2 = 5'd1; // 두 번째 읽기 포트의 레지스터 번호.
        a3 = 5'd31; // 쓰기 대상 번호. 읽기 주소와 독립적입니다.
        wd3 = 32'hA5A55A5A; // 저장할 32비트 데이터.
        @(posedge clk);
        #1; // non-blocking 갱신이 끝난 뒤 두 출력을 검사합니다.
        // C12: 최상위 주소 x31과 32비트 패턴
        if (rd1 !== 32'hA5A55A5A) $fatal(1, "FAIL C12 RD1 expected=%h actual=%h", 32'hA5A55A5A, rd1);
        if (rd2 !== 32'd99) $fatal(1, "FAIL C12 RD2 expected=%h actual=%h", 32'd99, rd2);
        $display("C12 OK t=%0t RD1=%h RD2=%h", $time, rd1, rd2);

        @(negedge clk); // 입력은 쓰기 상승 에지와 겹치지 않게 준비합니다.
        reset = 1'b0; // active-high 리셋. 0이면 정상 동작.
        we3 = 1'b0; // 다음 상승 에지의 쓰기 허용 여부.
        a1 = 5'd31; // 첫 읽기 포트의 레지스터 번호.
        a2 = 5'd1; // 두 번째 읽기 포트의 레지스터 번호.
        a3 = 5'd31; // 쓰기 대상 번호. 읽기 주소와 독립적입니다.
        wd3 = 32'hA5A55A5A; // 저장할 32비트 데이터.
        #2; // 하강 에지에서 2ns 뒤: 어떤 클럭 에지와도 겹치지 않습니다.
        reset = 1'b1;
        #1; // 다음 상승 에지를 기다리지 않고 조합 읽기를 검사합니다.
        // C13: 다음 상승 에지 전에 x31과 x1의 비동기 초기화
        if (rd1 !== 32'd0) $fatal(1, "FAIL C13 RD1 expected=%h actual=%h", 32'd0, rd1);
        if (rd2 !== 32'd0) $fatal(1, "FAIL C13 RD2 expected=%h actual=%h", 32'd0, rd2);
        $display("C13 OK t=%0t RD1=%h RD2=%h", $time, rd1, rd2);

        @(negedge clk); // 입력은 쓰기 상승 에지와 겹치지 않게 준비합니다.
        reset = 1'b0; // active-high 리셋. 0이면 정상 동작.
        we3 = 1'b1; // 다음 상승 에지의 쓰기 허용 여부.
        a1 = 5'd2; // 첫 읽기 포트의 레지스터 번호.
        a2 = 5'd2; // 두 번째 읽기 포트의 레지스터 번호.
        a3 = 5'd2; // 쓰기 대상 번호. 읽기 주소와 독립적입니다.
        wd3 = 32'h80000001; // 저장할 32비트 데이터.
        @(posedge clk);
        #1; // non-blocking 갱신이 끝난 뒤 두 출력을 검사합니다.
        // C14: 리셋 해제 후 재쓰기와 최상위 비트
        if (rd1 !== 32'h80000001) $fatal(1, "FAIL C14 RD1 expected=%h actual=%h", 32'h80000001, rd1);
        if (rd2 !== 32'h80000001) $fatal(1, "FAIL C14 RD2 expected=%h actual=%h", 32'h80000001, rd2);
        $display("C14 OK t=%0t RD1=%h RD2=%h", $time, rd1, rd2);

        @(negedge clk);
        we3 = 1'b0; // 마지막 쓰기도 여기서 금지하여 재쓰기를 막습니다.
        #1;
        $display("W06 CHECKPOINT PASS (14/14)");
        $finish;
    end

    // DUT/클럭을 잘못 수정해 대기가 끝나지 않으면 성공 없이 종료합니다.
    initial begin
        #1000;
        $fatal(1, "TIMEOUT");
    end
endmodule

// Local Variables:
// verilog-library-directories: ("." "../rtl")
// End:
