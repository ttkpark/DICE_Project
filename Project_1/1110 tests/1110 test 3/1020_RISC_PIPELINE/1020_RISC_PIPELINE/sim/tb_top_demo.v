`timescale 1ns/1ps
// Public demonstration testbench. Do not modify it for grading.
// The official testbench is maintained separately and student edits to
// this file are never used in official grading.
module TB_TOP_DEMO;
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
    integer i;
    integer steps;

    TOP dut (
        .CLK(CLK),
        .RESET(RESET),
        .RESERVED_IN0(32'b0),
        .RESERVED_IN1(32'b0),
        .RESERVED_IN2(32'b0),
        .RESERVED_IN3(32'b0),
        .RESERVED_IN4(32'b0),
        .RESERVED_IN5(32'b0),
        .RESERVED_IN6(32'b0),
        .RESERVED_IN7(32'b0),
        .RESERVED_IN8(32'b0),
        .RESERVED_IN9(32'b0),
        .RESERVED_IN10(32'b0),
        .RESERVED_IN11(32'b0),
        .RESERVED_IN12(32'b0),
        .RESERVED_IN13(32'b0),
        .RESERVED_IN14(32'b0),
        .RESERVED_IN15(32'b0),
        .RESERVED_IN16(32'b0),
        .RESERVED_IN17(32'b0),
        .RESERVED_IN18(32'b0),
        .RESERVED_IN19(32'b0),
        .PC(PC),
        .INSTR(INSTR),
        .MEMWRITE(MEMWRITE),
        .ALURESULT(ALURESULT),
        .WRITEDATA(WRITEDATA),
        .RESERVED_OUT0(),
        .RESERVED_OUT1(),
        .RESERVED_OUT2(),
        .RESERVED_OUT3(),
        .RESERVED_OUT4(),
        .RESERVED_OUT5(),
        .RESERVED_OUT6(),
        .RESERVED_OUT7(),
        .RESERVED_OUT8(),
        .RESERVED_OUT9(),
        .RESERVED_OUT10(),
        .RESERVED_OUT11(),
        .RESERVED_OUT12(),
        .RESERVED_OUT13(),
        .RESERVED_OUT14(),
        .RESERVED_OUT15(),
        .RESERVED_OUT16(),
        .RESERVED_OUT17(),
        .RESERVED_OUT18(),
        .RESERVED_OUT19()
    );

    MEMORY_POWER u_memory_power (
        .CLK(CLK),
        .RESET(RESET),
        .INSTR(INSTR),
        .MEMWRITE(MEMWRITE),
        .ALURESULT(ALURESULT),
        .WRITEDATA(WRITEDATA),
        .DONE_ADDR(DONE_ADDR),
        .DONE_TOKEN(DONE_TOKEN),
        .IMEM_WORDS(dut.u_imem.LOADED_WORDS)
    );

    always #5 CLK = ~CLK;

    initial begin
        CLK = 1'b0;
        RESET = 1'b1;
        steps = 0;
        if (!$value$plusargs("EXPECTED=%s", expected_file))
            expected_file = "cases/demo_expected.hex";
        $readmemh(expected_file, EXPECTED);
        #1;
        Y_BASE = dut.u_dmem.RAM['h30c >> 2];
        SCRATCH_BASE = dut.u_dmem.RAM['h310 >> 2];
        DONE_ADDR = dut.u_dmem.RAM['h31c >> 2];
        DONE_TOKEN = dut.u_dmem.RAM['h320 >> 2];
        repeat (2) @(negedge CLK);
        RESET = 1'b0;
    end

    always @(posedge CLK) begin
        if (!RESET) begin
            steps = steps + 1;
            if (steps > 100000) begin
                $display("FAIL TB_TOP_DEMO: timeout at PC=%08x", PC);
                $finish;
            end
            if (MEMWRITE) begin
                if (!((ALURESULT >= SCRATCH_BASE &&
                       ALURESULT < SCRATCH_BASE + 128) ||
                      (ALURESULT >= Y_BASE && ALURESULT < Y_BASE + 16) ||
                       ALURESULT == DONE_ADDR)) begin
                    $display("FAIL TB_TOP_DEMO: store outside allowed area %08x",
                             ALURESULT);
                    $finish;
                end
                if (ALURESULT == DONE_ADDR) begin
                    if (WRITEDATA !== DONE_TOKEN) begin
                        $display("FAIL TB_TOP_DEMO: wrong DONE token");
                        $finish;
                    end
                    #1;
                    for (i = 0; i < 4; i = i + 1) begin
                        if (dut.u_dmem.RAM[(Y_BASE >> 2) + i] !== EXPECTED[i]) begin
                            $display("FAIL TB_TOP_DEMO: Y[%0d] got=%08x expected=%08x",
                                     i, dut.u_dmem.RAM[(Y_BASE >> 2) + i],
                                     EXPECTED[i]);
                            $finish;
                        end
                    end
                    $display("PASS TB_TOP_DEMO: Y[0..3] match; DONE at cycle %0d", steps);
                    $finish;
                end
            end
        end
    end
endmodule
