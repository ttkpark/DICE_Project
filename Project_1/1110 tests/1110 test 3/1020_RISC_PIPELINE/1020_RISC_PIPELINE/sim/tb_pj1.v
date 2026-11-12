`timescale 1ns/1ps
// PJ1 기능검사 TB. TOP 포트와 u_imem/u_dmem 만 본다 -> 단일 사이클·파이프라인 공용 (CORE 내부 무관).
// tb_top_demo 의 검사(쓰기 범위, DONE 토큰, Y 정답)에 더해:
//   - 모든 store 를 +TRACE 파일에 "cycle addr data" 로 기록 -> tools/pj1_check.py 가 ISA 모델의 store 순서와 1:1 비교
//   - DONE 시점의 DMEM 전체를 +MEMOUT 에 덤프              -> 입력·config 보존, SCRATCH 내용까지 ISA 모델과 비교
//   - DONE 전에 Y 4 word 가 모두 쓰였는지, 4바이트 정렬, MEMWRITE/주소/데이터에 X 없는지
//   - +RESET_AT=n : n cycle 째에 RESET 을 2 cycle 다시 건다 (실행 도중 동기 리셋 -> 처음부터 다시 돌아 같은 결과여야 함)
//   - +EXPECTED 가 있으면 Y 정답 비교 (없으면 pj1_check.py 의 메모리 비교가 대신함, 예: sw/hazard_test)
// 출력 마지막 줄: "PASS TB_PJ1: cycles=N stores=S" 또는 "FAIL TB_PJ1: ...".
module TB_PJ1;
    reg CLK;
    reg RESET;
    wire [31:0] PC;
    wire [31:0] INSTR;
    wire MEMWRITE;
    wire [31:0] ALURESULT;
    wire [31:0] WRITEDATA;
    reg [31:0] EXPECTED [0:3];
    reg [31:0] Y_BASE;
    reg [31:0] SCRATCH_BASE;
    reg [31:0] DONE_ADDR;
    reg [31:0] DONE_TOKEN;
    reg [2047:0] expected_file;
    reg [2047:0] trace_file;
    reg [2047:0] mem_file;
    reg has_expected;
    reg has_mem;
    reg [3:0] y_written;
    integer trace_fd;
    integer cycles;
    integer stores;
    integer reset_at;
    integer max_cycles;
    integer i;

    TOP dut (
        .CLK(CLK), .RESET(RESET),
        .RESERVED_IN0(32'b0),  .RESERVED_IN1(32'b0),  .RESERVED_IN2(32'b0),  .RESERVED_IN3(32'b0),
        .RESERVED_IN4(32'b0),  .RESERVED_IN5(32'b0),  .RESERVED_IN6(32'b0),  .RESERVED_IN7(32'b0),
        .RESERVED_IN8(32'b0),  .RESERVED_IN9(32'b0),  .RESERVED_IN10(32'b0), .RESERVED_IN11(32'b0),
        .RESERVED_IN12(32'b0), .RESERVED_IN13(32'b0), .RESERVED_IN14(32'b0), .RESERVED_IN15(32'b0),
        .RESERVED_IN16(32'b0), .RESERVED_IN17(32'b0), .RESERVED_IN18(32'b0), .RESERVED_IN19(32'b0),
        .PC(PC), .INSTR(INSTR), .MEMWRITE(MEMWRITE), .ALURESULT(ALURESULT), .WRITEDATA(WRITEDATA),
        .RESERVED_OUT0(),  .RESERVED_OUT1(),  .RESERVED_OUT2(),  .RESERVED_OUT3(),  .RESERVED_OUT4(),
        .RESERVED_OUT5(),  .RESERVED_OUT6(),  .RESERVED_OUT7(),  .RESERVED_OUT8(),  .RESERVED_OUT9(),
        .RESERVED_OUT10(), .RESERVED_OUT11(), .RESERVED_OUT12(), .RESERVED_OUT13(), .RESERVED_OUT14(),
        .RESERVED_OUT15(), .RESERVED_OUT16(), .RESERVED_OUT17(), .RESERVED_OUT18(), .RESERVED_OUT19()
    );

    MEMORY_POWER u_memory_power (
        .CLK(CLK), .RESET(RESET), .INSTR(INSTR), .MEMWRITE(MEMWRITE),
        .ALURESULT(ALURESULT), .WRITEDATA(WRITEDATA),
        .DONE_ADDR(DONE_ADDR), .DONE_TOKEN(DONE_TOKEN),
        .IMEM_WORDS(dut.u_imem.LOADED_WORDS)
    );

    always #5 CLK = ~CLK;

    initial begin
        CLK = 1'b0;
        RESET = 1'b1;
        cycles = 0;
        stores = 0;
        y_written = 4'b0;
        trace_fd = 0;
        has_expected = $value$plusargs("EXPECTED=%s", expected_file);
        if (has_expected)
            $readmemh(expected_file, EXPECTED);
        if ($value$plusargs("TRACE=%s", trace_file))
            trace_fd = $fopen(trace_file, "w");
        has_mem = $value$plusargs("MEMOUT=%s", mem_file);
        if (!$value$plusargs("RESET_AT=%d", reset_at))
            reset_at = 0;
        if (!$value$plusargs("MAX_CYCLES=%d", max_cycles))
            max_cycles = 100000;
        #1;
        Y_BASE = dut.u_dmem.RAM['h30c >> 2];
        SCRATCH_BASE = dut.u_dmem.RAM['h310 >> 2];
        DONE_ADDR = dut.u_dmem.RAM['h31c >> 2];
        DONE_TOKEN = dut.u_dmem.RAM['h320 >> 2];
        repeat (2) @(negedge CLK);
        RESET = 1'b0;
        if (reset_at > 0) begin
            wait (cycles == reset_at);
            @(negedge CLK);
            RESET = 1'b1;
            $display("TB_PJ1: RESET re-asserted at cycle %0d", cycles);
            if (trace_fd) $fdisplay(trace_fd, "R");
            repeat (2) @(negedge CLK);
            RESET = 1'b0;
        end
    end

    always @(posedge CLK) begin
        if (RESET) begin
            cycles = 0;
            stores = 0;
            y_written = 4'b0;
        end else begin
            cycles = cycles + 1;
            if (cycles > max_cycles) begin
                $display("FAIL TB_PJ1: timeout at PC=%08x", PC);
                $finish;
            end
            if (MEMWRITE !== 1'b0 && MEMWRITE !== 1'b1) begin
                $display("FAIL TB_PJ1: MEMWRITE=%b at cycle %0d", MEMWRITE, cycles);
                $finish;
            end
            if (MEMWRITE) begin
                if ((^ALURESULT) === 1'bx || (^WRITEDATA) === 1'bx) begin
                    $display("FAIL TB_PJ1: X on store addr=%08x data=%08x at cycle %0d",
                             ALURESULT, WRITEDATA, cycles);
                    $finish;
                end
                if (ALURESULT[1:0] != 2'b00) begin
                    $display("FAIL TB_PJ1: misaligned store %08x", ALURESULT);
                    $finish;
                end
                if (!((ALURESULT >= SCRATCH_BASE && ALURESULT < SCRATCH_BASE + 128) ||
                      (ALURESULT >= Y_BASE && ALURESULT < Y_BASE + 16) ||
                       ALURESULT == DONE_ADDR)) begin
                    $display("FAIL TB_PJ1: store outside allowed area %08x at cycle %0d",
                             ALURESULT, cycles);
                    $finish;
                end
                stores = stores + 1;
                if (trace_fd) $fdisplay(trace_fd, "%0d %08x %08x", cycles, ALURESULT, WRITEDATA);
                if (ALURESULT >= Y_BASE && ALURESULT < Y_BASE + 16)
                    y_written[(ALURESULT - Y_BASE) >> 2] = 1'b1;
                if (ALURESULT == DONE_ADDR) begin
                    if (WRITEDATA !== DONE_TOKEN) begin
                        $display("FAIL TB_PJ1: wrong DONE token %08x", WRITEDATA);
                        $finish;
                    end
                    if (y_written != 4'hf) begin
                        $display("FAIL TB_PJ1: DONE before all Y stored (Y written mask=%b)", y_written);
                        $finish;
                    end
                    #1;
                    if (has_expected)
                        for (i = 0; i < 4; i = i + 1)
                            if (dut.u_dmem.RAM[(Y_BASE >> 2) + i] !== EXPECTED[i]) begin
                                $display("FAIL TB_PJ1: Y[%0d] got=%08x expected=%08x",
                                         i, dut.u_dmem.RAM[(Y_BASE >> 2) + i], EXPECTED[i]);
                                $finish;
                            end
                    if (has_mem) $writememh(mem_file, dut.u_dmem.RAM);
                    if (trace_fd) $fclose(trace_fd);
                    $display("PASS TB_PJ1: cycles=%0d stores=%0d", cycles, stores);
                    $finish;
                end
            end
        end
    end
endmodule
