// Project 1 CORE : 5단 파이프라인 RV32I (기본 8명령 ADD SUB AND ADDI LW SW BEQ JAL).
// 포트 이름·방향·폭은 PROJECT_CONTRACT_KO.md 계약 그대로. CONTROLLER 는 단일 사이클 판과 동일.
//
//   IF  : PC(출력) -> IMEM.ADDR, INSTR(입력) 을 IF/ID 에 저장
//   ID  : CONTROLLER 디코드, 레지스터 읽기(WB 와 같은 번지면 쓰는 값을 읽음), imm 확장
//   EX  : 포워딩(MEM, WB -> EX) + ALU, 분기/점프 판정, PC 목표 계산
//   MEM : ALURESULT / WRITEDATA / MEMWRITE 출력 (DMEM 과 채점기가 보는 store 신호), READDATA 입력
//   WB  : 레지스터 파일 쓰기
//
//   해저드 : lw 바로 뒤에서 그 결과를 쓰면 1 cycle stall. BEQ(taken)/JAL 은 EX 에서 해결하고
//            IF/ID, ID/EX 를 비워 2 cycle 손실. 그 밖의 RAW 는 포워딩으로 0 cycle.
//   버블   : IF/ID 의 INSTR=0 은 CONTROLLER 가 ILLEGAL 로 디코드해 모든 제어 신호가 0 (상태 변경 없음).
//   RESET  : 동기 active-high. PC=0, 모든 파이프라인 레지스터·레지스터 파일 0.
//
//   1110_pipeline_EX = 지금까지의 EX 분기판 개선을 모두 넣은 판 (포트·ISA·RESET 계약 변경 없음, cycle 수 동일)
//     1) ZeroE 를 뺄셈 결과==0 이 아니라 ALU 와 병렬인 비교기로 판정      (분기 경로에서 adder 제거)
//     2) 포워딩 select 를 ID 에서 미리 계산해 ID/EX 에 저장              (EX 의 번지 비교기 제거)
//     3) 버블 때 데이터 레지스터는 비우지 않고 제어 비트만 0             (PCSrcE/flush 팬아웃 축소)
//     4) result mux 를 MEM 단에서 하고 결과 32비트만 MEM/WB 에 저장      (WB 포워딩 경로 mux 제거, FF 66개 감소)
module CORE (
    input  wire        CLK,
    input  wire        RESET,
    input  wire [31:0] INSTR,
    input  wire [31:0] READDATA,
    output reg  [31:0] PC,
    output wire        MEMWRITE,
    output wire [31:0] ALURESULT,
    output wire [31:0] WRITEDATA
);
    // ---------------------------------------------------------------- IF
    wire        StallF, StallD, FlushD, FlushE, PCSrcE;
    wire [31:0] PCTargetE;
    wire [31:0] PCPlus4F = PC + 32'd4;
    wire [31:0] PCNextF  = PCSrcE ? PCTargetE : PCPlus4F;

    always @(posedge CLK) begin
        if (RESET)        PC <= 32'd0;
        else if (!StallF) PC <= PCNextF;
    end

    // ---------------------------------------------------------------- IF/ID
    reg [31:0] InstrD, PCD, PCPlus4D;

    always @(posedge CLK) begin
        if (RESET || FlushD) InstrD <= 32'd0;
        else if (!StallD)    InstrD <= INSTR;
    end
    // 데이터 쪽은 flush 하지 않는다: InstrD 가 0(버블)이면 제어가 전부 0 이라 값이 쓰이지 않는다.
    // -> PCSrcE(FlushD) 의 팬아웃에서 64 FF 가 빠진다.
    always @(posedge CLK) begin
        if (RESET) begin
            PCD <= 32'd0; PCPlus4D <= 32'd0;
        end else if (!StallD) begin
            PCD <= PC; PCPlus4D <= PCPlus4F;
        end
    end

    // ---------------------------------------------------------------- ID
    wire        REGWRITE, MEMWRITE_D, ALUSRC, BRANCHJUMP, ILLEGAL;
    wire [1:0]  RESULTSRC, IMMSRC;
    wire [2:0]  ALUCTRL;

    // ZERO 를 1 로 묶어 PCSRC 출력을 "분기 또는 점프" 로 쓰고, 실제 ZERO 판정은 EX 에서 한다.
    CONTROLLER u_controller (
        .INSTR      (InstrD),
        .ZERO       (1'b1),
        .REGWRITE   (REGWRITE),
        .MEMWRITE   (MEMWRITE_D),
        .ALUSRC     (ALUSRC),
        .RESULTSRC  (RESULTSRC),
        .IMMSRC     (IMMSRC),
        .ALUCTRL    (ALUCTRL),
        .PCSRC      (BRANCHJUMP),
        .ILLEGAL    (ILLEGAL)
    );

    wire RegWriteD = REGWRITE & ~ILLEGAL;
    wire MemWriteD = MEMWRITE_D & ~ILLEGAL;
    wire JumpD     = (IMMSRC == 2'b11);          // J-type = JAL 만

    reg  [31:0] rf [0:31];
    integer i;
    wire [4:0]  Rs1D = InstrD[19:15];
    wire [4:0]  Rs2D = InstrD[24:20];
    wire [4:0]  RdD  = InstrD[11:7];
    wire [4:0]  RdW;
    wire        RegWriteW;
    reg  [31:0] ResultW;
    // x0 = 0. WB 가 같은 번지에 쓰는 중이면 그 값을 읽는다 (write-first 레지스터 파일).
    wire [31:0] RD1D = (Rs1D == 5'd0) ? 32'd0 : (RegWriteW && RdW == Rs1D) ? ResultW : rf[Rs1D];
    wire [31:0] RD2D = (Rs2D == 5'd0) ? 32'd0 : (RegWriteW && RdW == Rs2D) ? ResultW : rf[Rs2D];

    reg [31:0] ImmExtD;
    always @* begin
        case (IMMSRC)
            2'b00: ImmExtD = {{20{InstrD[31]}}, InstrD[31:20]};
            2'b01: ImmExtD = {{20{InstrD[31]}}, InstrD[31:25], InstrD[11:7]};
            2'b10: ImmExtD = {{19{InstrD[31]}}, InstrD[31], InstrD[7],
                              InstrD[30:25], InstrD[11:8], 1'b0};
            2'b11: ImmExtD = {{11{InstrD[31]}}, InstrD[31], InstrD[19:12],
                              InstrD[20], InstrD[30:21], 1'b0};
            default: ImmExtD = 32'd0;
        endcase
    end

    // ---------------------------------------------------------------- ID/EX
    reg         RegWriteE, MemWriteE, ALUSrcE, BranchJumpE, JumpE;
    reg  [1:0]  ResultSrcE;
    reg  [2:0]  ALUControlE;
    reg  [31:0] RD1E, RD2E, PCE, ImmExtE, PCPlus4E;
    reg  [4:0]  RdE;
    reg  [1:0]  ForwardAE, ForwardBE;      // 10: MEM 의 ALU 결과, 01: WB 결과, 00: 레지스터 값
    reg  [4:0]  RdM;
    reg         RegWriteM;

    // 포워딩 select 를 ID 에서 미리 계산한다. 지금 ID 의 명령이 EX 에 갈 때,
    // 지금 EX 의 명령은 MEM 에(-> 10), 지금 MEM 의 명령은 WB 에(-> 01) 가 있다.
    // (지금 WB 의 명령은 write-first 레지스터 파일이 RD1D/RD2D 에서 이미 처리.)
    // stall/flush 로 ID 의 명령이 EX 에 못 가면 ID/EX 는 버블이라 select 값은 쓰이지 않는다.
    reg [1:0] ForwardAD, ForwardBD;
    always @* begin
        ForwardAD = 2'b00;
        if      (Rs1D != 5'd0 && Rs1D == RdE && RegWriteE) ForwardAD = 2'b10;
        else if (Rs1D != 5'd0 && Rs1D == RdM && RegWriteM) ForwardAD = 2'b01;
        ForwardBD = 2'b00;
        if      (Rs2D != 5'd0 && Rs2D == RdE && RegWriteE) ForwardBD = 2'b10;
        else if (Rs2D != 5'd0 && Rs2D == RdM && RegWriteM) ForwardBD = 2'b01;
    end

    // 제어 비트: flush 대상 (버블이 상태를 바꾸지 못하게 하는 데 필요한 것만)
    always @(posedge CLK) begin
        if (RESET || FlushE) begin
            RegWriteE <= 1'b0; MemWriteE <= 1'b0; BranchJumpE <= 1'b0; JumpE <= 1'b0;
            ResultSrcE <= 2'b00;
        end else begin
            RegWriteE <= RegWriteD; MemWriteE <= MemWriteD;
            BranchJumpE <= BRANCHJUMP & ~ILLEGAL; JumpE <= JumpD;
            ResultSrcE <= RESULTSRC;
        end
    end
    // 데이터·ALU 제어: flush 하지 않는다 (위 제어가 0 이면 결과가 어디에도 쓰이지 않는다).
    // -> PCSrcE(FlushE) 의 팬아웃에서 약 180 FF 가 빠진다. RESET 은 그대로 건다.
    always @(posedge CLK) begin
        if (RESET) begin
            ALUSrcE <= 1'b0; ALUControlE <= 3'b000;
            RD1E <= 32'd0; RD2E <= 32'd0; PCE <= 32'd0; ImmExtE <= 32'd0; PCPlus4E <= 32'd0;
            RdE <= 5'd0; ForwardAE <= 2'b00; ForwardBE <= 2'b00;
        end else begin
            ALUSrcE <= ALUSRC; ALUControlE <= ALUCTRL;
            RD1E <= RD1D; RD2E <= RD2D; PCE <= PCD; ImmExtE <= ImmExtD; PCPlus4E <= PCPlus4D;
            RdE <= RdD; ForwardAE <= ForwardAD; ForwardBE <= ForwardBD;
        end
    end

    // ---------------------------------------------------------------- EX
    reg  [31:0] ALUResultM, WriteDataM, PCPlus4M;
    reg         MemWriteM;
    reg  [1:0]  ResultSrcM;

    // MEM 에서 포워딩할 값: JAL 이면 PC+4, 그 외 ALU 결과 (lw 는 stall 로 여기 오지 않음)
    wire [31:0] ForwardM   = ResultSrcM[1] ? PCPlus4M : ALUResultM;
    wire [31:0] SrcAE      = ForwardAE[1] ? ForwardM : ForwardAE[0] ? ResultW : RD1E;
    wire [31:0] WriteDataE = ForwardBE[1] ? ForwardM : ForwardBE[0] ? ResultW : RD2E;
    wire [31:0] SrcBE      = ALUSrcE ? ImmExtE : WriteDataE;

    reg [31:0] ALUResultE;
    always @* begin
        case (ALUControlE)
            3'b000: ALUResultE = SrcAE + SrcBE;
            3'b001: ALUResultE = SrcAE - SrcBE;
            3'b010: ALUResultE = SrcAE & SrcBE;
            default: ALUResultE = 32'd0;
        endcase
    end

    // BEQ 는 rs1==rs2 이면 분기. 뺄셈 결과==0 대신 비교기를 ALU 와 병렬로 둔다 (분기 경로에서 adder 제거).
    wire ZeroE = (SrcAE == SrcBE);
    assign PCSrcE    = BranchJumpE & (JumpE | ZeroE);
    assign PCTargetE = PCE + ImmExtE;

    // ---------------------------------------------------------------- EX/MEM
    always @(posedge CLK) begin
        if (RESET) begin
            RegWriteM <= 1'b0; MemWriteM <= 1'b0; ResultSrcM <= 2'b00;
            ALUResultM <= 32'd0; WriteDataM <= 32'd0; PCPlus4M <= 32'd0; RdM <= 5'd0;
        end else begin
            RegWriteM <= RegWriteE; MemWriteM <= MemWriteE; ResultSrcM <= ResultSrcE;
            ALUResultM <= ALUResultE; WriteDataM <= WriteDataE; PCPlus4M <= PCPlus4E; RdM <= RdE;
        end
    end

    // ---------------------------------------------------------------- MEM
    assign ALURESULT = ALUResultM;
    assign WRITEDATA = WriteDataM;
    assign MEMWRITE  = MemWriteM;

    // ---------------------------------------------------------------- MEM/WB
    // result mux 를 MEM 단에서 하고 결과 32비트만 저장한다 (ALU 결과/READDATA/PC+4 를 따로 들고 가지 않음).
    // -> WB 포워딩 경로에서 3:1 mux 가 빠지고 FF 가 66 개 준다.
    reg         RegWriteW_r;
    reg  [4:0]  RdW_r;
    assign RegWriteW = RegWriteW_r;
    assign RdW       = RdW_r;

    always @(posedge CLK) begin
        if (RESET) begin
            RegWriteW_r <= 1'b0; RdW_r <= 5'd0; ResultW <= 32'd0;
        end else begin
            RegWriteW_r <= RegWriteM; RdW_r <= RdM;
            case (ResultSrcM)
                2'b00:   ResultW <= ALUResultM;
                2'b01:   ResultW <= READDATA;
                2'b10:   ResultW <= PCPlus4M;
                default: ResultW <= 32'd0;
            endcase
        end
    end

    // ---------------------------------------------------------------- WB
    always @(posedge CLK) begin
        if (RESET) begin
            for (i = 0; i < 32; i = i + 1)
                rf[i] <= 32'd0;
        end else if (RegWriteW && RdW != 5'd0) begin
            rf[RdW] <= ResultW;
        end
    end

    // ---------------------------------------------------------------- 해저드 유닛
    // lw 결과를 바로 다음 명령이 읽으면 1 cycle stall (IF/ID 유지, ID/EX 버블).
    // 분기/점프가 EX 에서 확정되면 IF/ID 와 ID/EX 를 비운다.
    wire lwStall = ResultSrcE[0] & RegWriteE & (RdE != 5'd0) & ((Rs1D == RdE) | (Rs2D == RdE));
    assign StallF = lwStall;
    assign StallD = lwStall;
    assign FlushD = PCSrcE;
    assign FlushE = lwStall | PCSrcE;
endmodule
