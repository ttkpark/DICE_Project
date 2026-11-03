// Project 1 CONTROLLER: 기본 8개 명령(ADD SUB AND ADDI LW SW BEQ JAL)만 decode.
// 그 밖의 encoding은 ILLEGAL=1, REGWRITE=0, MEMWRITE=0, PCSRC=0 (상태 변경 없음).
// 포트 이름·방향·폭은 PROJECT_CONTRACT_KO.md 고정 계약 그대로.
module CONTROLLER (
    input  wire [31:0] INSTR,
    input  wire        ZERO,
    output reg         REGWRITE,
    output reg         MEMWRITE,
    output reg         ALUSRC,
    output reg  [1:0]  RESULTSRC,
    output reg  [1:0]  IMMSRC,
    output reg  [2:0]  ALUCTRL,
    output wire        PCSRC,
    output reg         ILLEGAL
);
    wire [6:0] opcode = INSTR[6:0];
    wire [2:0] funct3 = INSTR[14:12];
    wire [6:0] funct7 = INSTR[31:25];
    reg        branch;
    reg        jump;

    // ALUCTRL: 000 ADD, 001 SUB, 010 AND (CORE.v의 ALU case와 일치)
    // IMMSRC : 00 I, 01 S, 10 B, 11 J      RESULTSRC: 00 ALU, 01 READDATA, 10 PC+4
    always @* begin
        REGWRITE  = 1'b0;
        MEMWRITE  = 1'b0;
        ALUSRC    = 1'b0;
        RESULTSRC = 2'b00;
        IMMSRC    = 2'b00;
        ALUCTRL   = 3'b000;
        ILLEGAL   = 1'b0;
        branch    = 1'b0;
        jump      = 1'b0;
        case (opcode)
            7'b0110011: begin                                   // R-type
                if (funct7 == 7'b0000000 && funct3 == 3'b000) begin
                    REGWRITE = 1'b1; ALUCTRL = 3'b000;          // ADD
                end else if (funct7 == 7'b0100000 && funct3 == 3'b000) begin
                    REGWRITE = 1'b1; ALUCTRL = 3'b001;          // SUB
                end else if (funct7 == 7'b0000000 && funct3 == 3'b111) begin
                    REGWRITE = 1'b1; ALUCTRL = 3'b010;          // AND
                end else begin
                    ILLEGAL = 1'b1;
                end
            end
            7'b0010011: begin                                   // ADDI
                if (funct3 == 3'b000) begin
                    REGWRITE = 1'b1; ALUSRC = 1'b1;
                end else begin
                    ILLEGAL = 1'b1;
                end
            end
            7'b0000011: begin                                   // LW
                if (funct3 == 3'b010) begin
                    REGWRITE = 1'b1; ALUSRC = 1'b1; RESULTSRC = 2'b01;
                end else begin
                    ILLEGAL = 1'b1;
                end
            end
            7'b0100011: begin                                   // SW
                if (funct3 == 3'b010) begin
                    MEMWRITE = 1'b1; ALUSRC = 1'b1; IMMSRC = 2'b01;
                end else begin
                    ILLEGAL = 1'b1;
                end
            end
            7'b1100011: begin                                   // BEQ
                if (funct3 == 3'b000) begin
                    branch = 1'b1; IMMSRC = 2'b10; ALUCTRL = 3'b001;
                end else begin
                    ILLEGAL = 1'b1;
                end
            end
            7'b1101111: begin                                   // JAL
                REGWRITE = 1'b1; RESULTSRC = 2'b10; IMMSRC = 2'b11; jump = 1'b1;
            end
            default: ILLEGAL = 1'b1;
        endcase
    end

    assign PCSRC = (branch & ZERO) | jump;
endmodule
