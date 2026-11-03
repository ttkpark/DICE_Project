`timescale 1ns/1ps
// 기능 확인용 simulation-only 단일 사이클 behavioral 실행 모델.
// 최종 프로젝트의 합성용 CPU/TOP/제어기 정답이나 공식 채점 덱이 아님.
// 10ns 테스트 clock은 합성으로 입증한 최대 동작 주기가 아님.
module TB_BEHAVIOR_CPU;
    reg CLK = 0;
    always #5 CLK = ~CLK;
    reg [31:0] IMEM [0:255];
    reg [31:0] DMEM [0:511];
    reg [31:0] EXPECTED [0:3];
    reg [31:0] RF [0:31];
    reg [31:0] PC, INSTR, A, B, IMM, NEXT_PC, RESULT, ADDR;
    reg [31:0] Y_BASE, TMP_BASE, DONE_ADDR, DONE_TOKEN;
    reg [3:0] Y_WRITTEN;
    reg WRITE_REG;
    integer i, WORDS, STEPS, LOADS, STORES, RD, RS1, RS2;
    reg [6:0] OPCODE, FUNCT7;
    reg [2:0] FUNCT3;
    string PROGRAM_FILE, DATA_FILE, EXPECTED_FILE;

    function integer word_index(input [31:0] address);
        begin
            if (address[1:0] != 0 || address >= 2048)
                $fatal(1, "FAIL invalid data address %08x", address);
            word_index = address >> 2;
        end
    endfunction

    initial begin
        if (!$value$plusargs("PROGRAM=%s", PROGRAM_FILE)) PROGRAM_FILE = "baseline_int8_fc_slow.hex";
        if (!$value$plusargs("DATA=%s", DATA_FILE)) DATA_FILE = "cases/demo_dmem.hex";
        if (!$value$plusargs("EXPECTED=%s", EXPECTED_FILE)) EXPECTED_FILE = "cases/demo_expected.hex";
        if (!$value$plusargs("WORDS=%d", WORDS)) WORDS = 57;
        if (WORDS < 1 || WORDS > 256) $fatal(1, "FAIL invalid IMEM size");
        for (i=0; i<256; i=i+1) IMEM[i] = 32'h00000013;
        for (i=0; i<512; i=i+1) DMEM[i] = 0;
        for (i=0; i<32; i=i+1) RF[i] = 0;
        $readmemh(PROGRAM_FILE, IMEM, 0, WORDS-1);
        $readmemh(DATA_FILE, DMEM);
        $readmemh(EXPECTED_FILE, EXPECTED);
        Y_BASE = DMEM['h30c >> 2];
        TMP_BASE = DMEM['h310 >> 2];
        DONE_ADDR = DMEM['h31c >> 2];
        DONE_TOKEN = DMEM['h320 >> 2];
        PC=0; STEPS=0; LOADS=0; STORES=0; Y_WRITTEN=0;
        // 한 rising edge마다 실제 instruction word 하나 실행.
        // nonblocking/hold/skew/게이트 딜레이 검증을 위한 모델이 아님.
        forever begin
            @(posedge CLK);
            if (STEPS >= 100000) $fatal(1, "FAIL timeout");
            if (PC[1:0] != 0 || (PC >> 2) >= WORDS) $fatal(1, "FAIL invalid PC %08x", PC);
            INSTR=IMEM[PC >> 2];
            OPCODE=INSTR[6:0]; FUNCT3=INSTR[14:12]; FUNCT7=INSTR[31:25];
            RD=INSTR[11:7]; RS1=INSTR[19:15]; RS2=INSTR[24:20];
            A=RF[RS1]; B=RF[RS2]; NEXT_PC=PC+4;
            RESULT=0; WRITE_REG=0;
            STEPS=STEPS+1;
            case (OPCODE)
                7'h33: begin
                    WRITE_REG=1;
                    case ({FUNCT7,FUNCT3})
                        10'b0000000_000: RESULT=A+B;
                        10'b0100000_000: RESULT=A-B;
                        10'b0000000_111: RESULT=A&B;
                        default: $fatal(1, "FAIL unsupported R instruction");
                    endcase
                end
                7'h13: begin
                    if (FUNCT3 != 0) $fatal(1, "FAIL unsupported I instruction");
                    IMM={{20{INSTR[31]}},INSTR[31:20]};
                    RESULT=A+IMM; WRITE_REG=1;
                end
                7'h03: begin
                    if (FUNCT3 != 2) $fatal(1, "FAIL only LW supported");
                    IMM={{20{INSTR[31]}},INSTR[31:20]};
                    RESULT=DMEM[word_index(A+IMM)]; WRITE_REG=1; LOADS=LOADS+1;
                end
                7'h23: begin
                    if (FUNCT3 != 2) $fatal(1, "FAIL only SW supported");
                    IMM={{20{INSTR[31]}},INSTR[31:25],INSTR[11:7]};
                    ADDR=A+IMM;
                    if (!((ADDR >= TMP_BASE && ADDR < TMP_BASE+128) ||
                          (ADDR >= Y_BASE && ADDR < Y_BASE+16) || ADDR == DONE_ADDR))
                        $fatal(1, "FAIL store outside scratch/output/status %08x", ADDR);
                    DMEM[word_index(ADDR)]=B; STORES=STORES+1;
                    if (ADDR >= Y_BASE && ADDR < Y_BASE+16) Y_WRITTEN[(ADDR-Y_BASE)>>2]=1;
                    if (ADDR == DONE_ADDR) begin
                        if (B !== DONE_TOKEN || Y_WRITTEN !== 4'b1111)
                            $fatal(1, "FAIL DONE ordering/token");
                        for (i=0; i<4; i=i+1)
                            if (DMEM[word_index(Y_BASE+4*i)] !== EXPECTED[i])
                                $fatal(1, "FAIL Y[%0d] got=%08x expected=%08x", i, DMEM[word_index(Y_BASE+4*i)], EXPECTED[i]);
                        if (LOADS != 110 || STORES != 37) $fatal(1, "FAIL baseline memory count");
                        $display("PASS RTL_MODEL steps=%0d loads=%0d stores=%0d Y=%0d,%0d,%0d,%0d",
                            STEPS,LOADS,STORES,$signed(DMEM[word_index(Y_BASE)]),$signed(DMEM[word_index(Y_BASE+4)]),
                            $signed(DMEM[word_index(Y_BASE+8)]),$signed(DMEM[word_index(Y_BASE+12)]));
                        $finish;
                    end
                end
                7'h63: begin
                    if (FUNCT3 != 0) $fatal(1, "FAIL only BEQ supported");
                    IMM={{19{INSTR[31]}},INSTR[31],INSTR[7],INSTR[30:25],INSTR[11:8],1'b0};
                    if (A == B) NEXT_PC=PC+IMM;
                end
                7'h6f: begin
                    IMM={{11{INSTR[31]}},INSTR[31],INSTR[19:12],INSTR[20],INSTR[30:21],1'b0};
                    RESULT=PC+4; WRITE_REG=1; NEXT_PC=PC+IMM;
                end
                default: $fatal(1, "FAIL unsupported instruction %08x", INSTR);
            endcase
            if (WRITE_REG && RD != 0) RF[RD]=RESULT;
            RF[0]=0; PC=NEXT_PC;
        end
    end
endmodule
