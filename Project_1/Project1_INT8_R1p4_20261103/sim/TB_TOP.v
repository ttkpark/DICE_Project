`timescale 1ns/1fs
// Public demonstration testbench. Do not modify it for grading.
// The official testbench is maintained separately and student edits to
// this file are never used in official grading.
module TB_TOP;
    reg CLK;
    reg RESET;
    wire [31:0] PC;
    wire [31:0] INSTR;
    wire [31:0] READDATA;
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
    integer done_seen;
    real f_mhz;
    real half_period_ns;
    real active_start_ns;
    reg [2047:0] vcd_file;
    reg [31:0] original_memory [0:511];

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
        .READDATA(READDATA),
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

    // These simulation-only memories are outside the synthesized dut (TOP).
    IMEM u_imem (
        .ADDR(PC),
        .INSTR(INSTR)
    );
    DMEM u_dmem (
        .CLK(CLK),
        .MEMWRITE(MEMWRITE && !RESET),
        .ADDR(ALURESULT),
        .WRITEDATA(WRITEDATA),
        .READDATA(READDATA)
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
        .IMEM_WORDS(u_imem.LOADED_WORDS)
    );

    // Same declared period as synth/common.sdc. The driver supplies F_MHZ.
    initial begin
        CLK = 1'b0;
        if (!$value$plusargs("F_MHZ=%f", f_mhz)) f_mhz = 250.0;
        if (f_mhz <= 0.0) begin
            $display("FAIL TB_TOP: F_MHZ must be positive");
            $finish;
        end
        half_period_ns = 500.0 / f_mhz;
        forever #(half_period_ns) CLK = ~CLK;
    end

    initial begin
        RESET = 1'b1;
        steps = 0;
        done_seen = 0;
        if (!$value$plusargs("VCD=%s", vcd_file)) vcd_file = "build/demo.raw.vcd";
        $dumpfile(vcd_file);
        $dumpvars(0, dut);
        $dumpoff;
        if (!$value$plusargs("EXPECTED=%s", expected_file))
            expected_file = "cases/demo_expected.hex";
        $readmemh(expected_file, EXPECTED);
        #1;
        for (i = 0; i < 512; i = i + 1) original_memory[i] = u_dmem.RAM[i];
        Y_BASE = u_dmem.RAM['h30c >> 2];
        SCRATCH_BASE = u_dmem.RAM['h310 >> 2];
        DONE_ADDR = u_dmem.RAM['h31c >> 2];
        DONE_TOKEN = u_dmem.RAM['h320 >> 2];
        repeat (2) @(negedge CLK);
        RESET = 1'b0;
        active_start_ns = $realtime;
        $dumpon;
    end

    always @(posedge CLK) begin
        if (!RESET && !done_seen) begin
            steps = steps + 1;
            if (steps > 100000) begin
                $display("FAIL TB_TOP: timeout at PC=%08x", PC);
                $finish;
            end
            if (MEMWRITE) begin
                if (!((ALURESULT >= SCRATCH_BASE &&
                       ALURESULT < SCRATCH_BASE + 128) ||
                      (ALURESULT >= Y_BASE && ALURESULT < Y_BASE + 16) ||
                       ALURESULT == DONE_ADDR)) begin
                    $display("FAIL TB_TOP: store outside allowed area %08x",
                             ALURESULT);
                    $finish;
                end
                if (ALURESULT == DONE_ADDR) begin
                    if (WRITEDATA !== DONE_TOKEN) begin
                        $display("FAIL TB_TOP: wrong DONE token");
                        $finish;
                    end
                    done_seen = 1;
                    #0.001;
                    for (i = 0; i < 4; i = i + 1) begin
                        if (u_dmem.RAM[(Y_BASE >> 2) + i] !== EXPECTED[i]) begin
                            $display("FAIL TB_TOP: Y[%0d] got=%08x expected=%08x",
                                     i, u_dmem.RAM[(Y_BASE >> 2) + i],
                                     EXPECTED[i]);
                            $finish;
                        end
                    end
                    // Input/config words must remain unchanged.
                    for (i = 0; i < 512; i = i + 1) begin
                        if (!((i*4 >= SCRATCH_BASE && i*4 < SCRATCH_BASE+128) ||
                              (i*4 >= Y_BASE && i*4 < Y_BASE+16) || i*4 == DONE_ADDR)) begin
                            if (u_dmem.RAM[i] !== original_memory[i]) begin
                                $display("FAIL TB_TOP: protected memory changed at %08x", i*4);
                                $finish;
                            end
                        end
                    end
                    // Stop at the next falling edge: exactly steps * period.
                    @(negedge CLK);
                    $display("ACTIVE_WINDOW start_ns=%0.6f end_ns=%0.6f", active_start_ns, $realtime);
                    $display("PASS TB_TOP: Y[0..3] match; DONE at cycle %0d", steps);
                    $dumpoff;
                    $finish;
                end
            end
        end
    end
endmodule
