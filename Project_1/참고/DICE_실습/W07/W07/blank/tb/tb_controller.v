`timescale 1ns/1ps
module tb_controller;
    reg [31:0] INSTR;
    reg ZERO;
    wire REGWRITE;
    wire MEMWRITE;
    wire ALUSRC;
    wire [1:0] RESULTSRC;
    wire [1:0] IMMSRC;
    wire [2:0] ALUCTRL;
    wire PCSRC;
    wire ILLEGAL;
    wire [11:0] actual;
    integer errors;
    integer tests;
    CONTROLLER dut (/*AUTOINST*/
        .INSTR(INSTR),
        .ZERO(ZERO),
        .REGWRITE(REGWRITE),
        .MEMWRITE(MEMWRITE),
        .ALUSRC(ALUSRC),
        .RESULTSRC(RESULTSRC),
        .IMMSRC(IMMSRC),
        .ALUCTRL(ALUCTRL),
        .PCSRC(PCSRC),
        .ILLEGAL(ILLEGAL)
    );
    // 순서: RW, MW, AS, RS[1:0], IS[1:0], ALU[2:0], PC, BAD
    assign actual = {REGWRITE, MEMWRITE, ALUSRC, RESULTSRC,
                     IMMSRC, ALUCTRL, PCSRC, ILLEGAL};
    // 입력 지정, 1ns 대기, 기대값 검사를 재사용
    task check;
        input [31:0] instruction;
        input zero_value;
        input [11:0] expected;
        begin
            INSTR = instruction;
            ZERO = zero_value;
            #1; // 조합논리 평가 후 검사. 합성 대상이 아님.
            tests = tests + 1;
            if (actual !== expected) begin // X/Z도 오류 검출
                errors = errors + 1;
                $display("FAIL C%02d got=%b expected=%b", tests, actual, expected);
            end else begin
                $display("PASS C%02d", tests);
            end
        end
    endtask
    initial begin
`ifdef DUMP_FSDB
        // W06에서 검증된 vcs_queue --fsdb가 매크로 추가
        $fsdbDumpfile("build/controller.fsdb");
        $fsdbDumpvars(0, tb_controller);
`endif
        $dumpfile("build/controller.vcd");
        $dumpvars(0, tb_controller);
        INSTR = 0;
        ZERO = 0;
        errors = 0;
        tests = 0;
        // C01: ADD
        check(32'h003100b3, 1'b0, 12'b100_00_00_000_0_0);
        // C02: SUB
        check(32'h403100b3, 1'b0, 12'b100_00_00_001_0_0);
        // C03: AND
        check(32'h003170b3, 1'b0, 12'b100_00_00_010_0_0);
        // C04: ADDI
        check(32'h00510093, 1'b0, 12'b101_00_00_000_0_0);
        // C05: LW
        check(32'h00412083, 1'b0, 12'b101_01_00_000_0_0);
        // C06: SW
        check(32'h00312223, 1'b0, 12'b011_00_01_000_0_0);
        // C07: BEQ taken
        check(32'h00208463, 1'b1, 12'b000_00_10_001_1_0);
        // C08: BEQ not taken
        check(32'h00208463, 1'b0, 12'b000_00_10_001_0_0);
        // C09: JAL ZERO=0
        check(32'h008000ef, 1'b0, 12'b100_10_11_000_1_0);
        // C10: JAL ZERO=1
        check(32'h008000ef, 1'b1, 12'b100_10_11_000_1_0);
        // C11: unsupported opcode after JAL
        check(32'hffffffff, 1'b1, 12'b000_00_00_000_0_1);
        // C12: unsupported R funct7
        check(32'h023100b3, 1'b0, 12'b000_00_00_000_0_1);
        // C13: unsupported load funct3
        check(32'h00410083, 1'b0, 12'b000_00_00_000_0_1);
        // C14: SW before invalid
        check(32'h00312223, 1'b0, 12'b011_00_01_000_0_0);
        // C15: invalid after SW
        check(32'hffffffff, 1'b0, 12'b000_00_00_000_0_1);
        // C16: unsupported branch
        check(32'h00209463, 1'b1, 12'b000_00_00_000_0_1);
        if (errors == 0 && tests == 16)
            $display("CONTROL PASS (16/16)");
        else
            $fatal(1, "CONTROL FAIL errors=%0d", errors);
        $finish;
    end
endmodule

// Local Variables:
// verilog-library-directories: ("." "../rtl")
// End:
