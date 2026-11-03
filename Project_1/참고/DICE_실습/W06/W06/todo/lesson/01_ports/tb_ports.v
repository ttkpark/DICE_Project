`timescale 1ns/1ps
// 파형: clk reset we3 a1 a2 a3 wd3 rd1 rd2. 주소는 unsigned decimal 권장.
module tb_ports;
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
        $dumpfile("build/ports.vcd");
        $dumpvars(0, tb_ports);
`ifdef DUMP_FSDB
        // 실제 vcs_queue --fsdb가 +define+DUMP_FSDB를 추가합니다.
        $fsdbDumpfile("build/ports.fsdb");
        $fsdbDumpvars(0, tb_ports);
`endif
        reset = 1'b0; // active-high 리셋. 0이면 정상 동작.
        we3 = 1'b0; // 다음 상승 에지의 쓰기 허용 여부.
        a1 = 5'd1; // 첫 읽기 포트의 레지스터 번호.
        a2 = 5'd2; // 두 번째 읽기 포트의 레지스터 번호.
        a3 = 5'd0; // 쓰기 대상 번호. 읽기 주소와 독립적입니다.
        wd3 = 32'd0; // 저장할 32비트 데이터.
        #2;
        reset = 1'b1; // 2ns에 리셋을 올려 첫 상승 에지 전에 확인합니다.
        #1; // 다음 상승 에지를 기다리지 않고 조합 읽기를 검사합니다.
        // P01: 리셋 후 x1과 x2는 0
        if (rd1 !== 32'd0) $fatal(1, "FAIL P01 RD1 expected=%h actual=%h", 32'd0, rd1);
        if (rd2 !== 32'd0) $fatal(1, "FAIL P01 RD2 expected=%h actual=%h", 32'd0, rd2);
        $display("P01 OK t=%0t RD1=%h RD2=%h", $time, rd1, rd2);

        @(negedge clk); // 입력은 쓰기 상승 에지와 겹치지 않게 준비합니다.
        reset = 1'b0; // active-high 리셋. 0이면 정상 동작.
        we3 = 1'b1; // 다음 상승 에지의 쓰기 허용 여부.
        a1 = 5'd1; // 첫 읽기 포트의 레지스터 번호.
        a2 = 5'd2; // 두 번째 읽기 포트의 레지스터 번호.
        a3 = 5'd1; // 쓰기 대상 번호. 읽기 주소와 독립적입니다.
        wd3 = 32'd10; // 저장할 32비트 데이터.
        @(posedge clk);
        #1; // non-blocking 갱신이 끝난 뒤 두 출력을 검사합니다.
        // P02: EDIT A: x1에 10 저장; 입력과 예상값을 함께 7로 바꿔 보세요
        if (rd1 !== 32'd10) $fatal(1, "FAIL P02 RD1 expected=%h actual=%h", 32'd10, rd1);
        if (rd2 !== 32'd0) $fatal(1, "FAIL P02 RD2 expected=%h actual=%h", 32'd0, rd2);
        $display("P02 OK t=%0t RD1=%h RD2=%h", $time, rd1, rd2);

        @(negedge clk); // 입력은 쓰기 상승 에지와 겹치지 않게 준비합니다.
        reset = 1'b0; // active-high 리셋. 0이면 정상 동작.
        we3 = 1'b1; // 다음 상승 에지의 쓰기 허용 여부.
        a1 = 5'd1; // 첫 읽기 포트의 레지스터 번호.
        a2 = 5'd2; // 두 번째 읽기 포트의 레지스터 번호.
        a3 = 5'd2; // 쓰기 대상 번호. 읽기 주소와 독립적입니다.
        wd3 = 32'd20; // 저장할 32비트 데이터.
        @(posedge clk);
        #1; // non-blocking 갱신이 끝난 뒤 두 출력을 검사합니다.
        // P03: EDIT B: x2에 20 저장; 입력과 예상값을 함께 9로 바꿔 보세요
        if (rd1 !== 32'd10) $fatal(1, "FAIL P03 RD1 expected=%h actual=%h", 32'd10, rd1);
        if (rd2 !== 32'd20) $fatal(1, "FAIL P03 RD2 expected=%h actual=%h", 32'd20, rd2);
        $display("P03 OK t=%0t RD1=%h RD2=%h", $time, rd1, rd2);

        @(negedge clk); // 입력은 쓰기 상승 에지와 겹치지 않게 준비합니다.
        reset = 1'b0; // active-high 리셋. 0이면 정상 동작.
        we3 = 1'b0; // 다음 상승 에지의 쓰기 허용 여부.
        a1 = 5'd1; // 첫 읽기 포트의 레지스터 번호.
        a2 = 5'd2; // 두 번째 읽기 포트의 레지스터 번호.
        a3 = 5'd2; // 쓰기 대상 번호. 읽기 주소와 독립적입니다.
        wd3 = 32'd20; // 저장할 32비트 데이터.
        #1; // 다음 상승 에지를 기다리지 않고 조합 읽기를 검사합니다.
        // P04: 쓰기를 금지해도 두 값 유지
        if (rd1 !== 32'd10) $fatal(1, "FAIL P04 RD1 expected=%h actual=%h", 32'd10, rd1);
        if (rd2 !== 32'd20) $fatal(1, "FAIL P04 RD2 expected=%h actual=%h", 32'd20, rd2);
        $display("P04 OK t=%0t RD1=%h RD2=%h", $time, rd1, rd2);

        @(negedge clk); // 입력은 쓰기 상승 에지와 겹치지 않게 준비합니다.
        reset = 1'b0; // active-high 리셋. 0이면 정상 동작.
        we3 = 1'b0; // 다음 상승 에지의 쓰기 허용 여부.
        a1 = 5'd2; // 첫 읽기 포트의 레지스터 번호.
        a2 = 5'd1; // 두 번째 읽기 포트의 레지스터 번호.
        a3 = 5'd2; // 쓰기 대상 번호. 읽기 주소와 독립적입니다.
        wd3 = 32'd20; // 저장할 32비트 데이터.
        #1; // 다음 상승 에지를 기다리지 않고 조합 읽기를 검사합니다.
        // P05: 읽기 주소 교환: 다음 상승 에지 전에 출력 교환
        if (rd1 !== 32'd20) $fatal(1, "FAIL P05 RD1 expected=%h actual=%h", 32'd20, rd1);
        if (rd2 !== 32'd10) $fatal(1, "FAIL P05 RD2 expected=%h actual=%h", 32'd10, rd2);
        $display("P05 OK t=%0t RD1=%h RD2=%h", $time, rd1, rd2);

        @(negedge clk); // 입력은 쓰기 상승 에지와 겹치지 않게 준비합니다.
        reset = 1'b0; // active-high 리셋. 0이면 정상 동작.
        we3 = 1'b0; // 다음 상승 에지의 쓰기 허용 여부.
        a1 = 5'd31; // 첫 읽기 포트의 레지스터 번호.
        a2 = 5'd1; // 두 번째 읽기 포트의 레지스터 번호.
        a3 = 5'd2; // 쓰기 대상 번호. 읽기 주소와 독립적입니다.
        wd3 = 32'd20; // 저장할 32비트 데이터.
        #1; // 다음 상승 에지를 기다리지 않고 조합 읽기를 검사합니다.
        // P06: A1만 x31로 변경해도 A2의 x1=10 유지
        if (rd1 !== 32'd0) $fatal(1, "FAIL P06 RD1 expected=%h actual=%h", 32'd0, rd1);
        if (rd2 !== 32'd10) $fatal(1, "FAIL P06 RD2 expected=%h actual=%h", 32'd10, rd2);
        $display("P06 OK t=%0t RD1=%h RD2=%h", $time, rd1, rd2);

        @(negedge clk);
        we3 = 1'b0; // 마지막 쓰기도 여기서 금지하여 재쓰기를 막습니다.
        #1;
        $display("W06 PORTS PASS (6/6)");
        $finish;
    end

    // DUT/클럭을 잘못 수정해 대기가 끝나지 않으면 성공 없이 종료합니다.
    initial begin
        #1000;
        $fatal(1, "TIMEOUT");
    end
endmodule

// Local Variables:
// verilog-library-directories: ("." ".")
// End:
