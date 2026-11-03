`timescale 1ns/1ps
// CONTROLLER self-check: 8 legal encodings must decode as expected; everything else
// (M extension, optional RV32I not implemented, ECALL, garbage) must give
// ILLEGAL=1 with REGWRITE=0 MEMWRITE=0 PCSRC=0 (no state change).
module TB_CTRL;
    reg  [31:0] INSTR;
    reg         ZERO;
    wire REGWRITE, MEMWRITE, ALUSRC, PCSRC, ILLEGAL;
    wire [1:0] RESULTSRC, IMMSRC;
    wire [2:0] ALUCTRL;
    integer pass, fail;

    CONTROLLER dut (.INSTR(INSTR), .ZERO(ZERO), .REGWRITE(REGWRITE), .MEMWRITE(MEMWRITE),
                    .ALUSRC(ALUSRC), .RESULTSRC(RESULTSRC), .IMMSRC(IMMSRC), .ALUCTRL(ALUCTRL),
                    .PCSRC(PCSRC), .ILLEGAL(ILLEGAL));

    // expected: {REGWRITE, MEMWRITE, ALUSRC, RESULTSRC, IMMSRC, ALUCTRL, PCSRC, ILLEGAL}
    task check(input [31:0] ins, input z, input [11:0] exp, input [95:0] name);
        reg [11:0] got;
        begin
            INSTR = ins; ZERO = z; #1;
            got = {REGWRITE, MEMWRITE, ALUSRC, RESULTSRC, IMMSRC, ALUCTRL, PCSRC, ILLEGAL};
            if (got === exp) pass = pass + 1;
            else begin
                fail = fail + 1;
                $display("FAIL %0s instr=%08x got=%b exp=%b", name, ins, got, exp);
            end
        end
    endtask

    task illegal(input [31:0] ins, input [95:0] name);
        begin
            INSTR = ins; ZERO = 1; #1;
            if (ILLEGAL === 1'b1 && REGWRITE === 1'b0 && MEMWRITE === 1'b0 && PCSRC === 1'b0)
                pass = pass + 1;
            else begin
                fail = fail + 1;
                $display("FAIL %0s instr=%08x ILLEGAL=%b REGWRITE=%b MEMWRITE=%b PCSRC=%b",
                         name, ins, ILLEGAL, REGWRITE, MEMWRITE, PCSRC);
            end
        end
    endtask

    initial begin
        pass = 0; fail = 0;
        //    instr        Z  RW MW AS RS  IS  ALU PS IL
        check(32'h005483b3, 0, 12'b1_0_0_00_00_000_0_0, "add");      // add x7,x9,x5
        check(32'h405483b3, 0, 12'b1_0_0_00_00_001_0_0, "sub");      // sub x7,x9,x5
        check(32'h01f2f333, 0, 12'b1_0_0_00_00_010_0_0, "and");      // and x6,x5,x31
        check(32'h30000a13, 0, 12'b1_0_1_00_00_000_0_0, "addi");     // addi x20,x0,768
        check(32'hffc38393, 0, 12'b1_0_1_00_00_000_0_0, "addi-neg"); // addi x7,x7,-1
        check(32'h000a2a83, 0, 12'b1_0_1_01_00_000_0_0, "lw");       // lw x21,0(x20)
        check(32'h0081a023, 0, 12'b0_1_1_00_01_000_0_0, "sw");       // sw x8,0(x3)
        check(32'h00030863, 0, 12'b0_0_0_00_10_001_0_0, "beq-nt");   // beq x6,x0  (ZERO=0 -> not taken)
        check(32'h00030863, 1, 12'b0_0_0_00_10_001_1_0, "beq-t");    // beq x6,x0  (ZERO=1 -> taken)
        check(32'h0100006f, 0, 12'b1_0_0_10_11_000_1_0, "jal");      // jal x0,+16
        check(32'h0100006f, 1, 12'b1_0_0_10_11_000_1_0, "jal-z1");   // jal independent of ZERO

        illegal(32'h025383b3, "mul");     // mul   x7,x7,x5  (M extension, forbidden)
        illegal(32'h0253c3b3, "div");     // div
        illegal(32'h00539393, "slli");    // slli  x7,x7,5   (optional, not implemented)
        illegal(32'h4053d393, "srai");    // srai
        illegal(32'h0053e3b3, "or");      // or
        illegal(32'h0053c3b3, "xor");     // xor
        illegal(32'h00531463, "bne");     // bne
        illegal(32'h00534463, "blt");     // blt
        illegal(32'h00038067, "jalr");    // jalr
        illegal(32'h000013b7, "lui");     // lui
        illegal(32'h00000397, "auipc");   // auipc
        illegal(32'h00038383, "lb");      // lb   (funct3=000 on load)
        illegal(32'h0053d383, "lhu");     // lhu
        illegal(32'h00538023, "sb");      // sb
        illegal(32'h00539023, "sh");      // sh
        illegal(32'h0053f393, "andi");    // andi
        illegal(32'h425383b3, "r-bad-f7");// opcode R, funct3=000, funct7=0100001 (neither ADD nor SUB)
        illegal(32'h825383b3, "r-garbage");
        illegal(32'h00000073, "ecall");
        illegal(32'h00100073, "ebreak");
        illegal(32'h00000000, "zero");
        illegal(32'hffffffff, "ones");
        illegal(32'h0000000f, "fence");
        $display("==== TB_CTRL RESULT : PASS=%0d FAIL=%0d ====", pass, fail);
        $finish;
    end
endmodule
