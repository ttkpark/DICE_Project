// 교육용 RV32I 부분집합 제어기. 전체 CPU가 아님.
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
    reg branch;
    reg jump;
    // 조합논리: blocking 대입, 모든 출력에 기본값 지정
    always @* begin
        REGWRITE = 1'b0;
        MEMWRITE = 1'b0;
        ALUSRC = 1'b0;
        RESULTSRC = 2'b00; // 00=ALU, 01=memory, 10=PC+4
        IMMSRC = 2'b00;    // 00=I, 01=S, 10=B, 11=J
        ALUCTRL = 3'b000;  // W04 코드: 000=ADD, 001=SUB, 010=AND
        branch = 1'b0;
        jump = 1'b0;
        ILLEGAL = 1'b1;    // 지원하지 않는 명령은 쓰기 금지
        case (opcode)
            7'b0110011: begin // R-type: ADD, SUB, AND
                case ({funct7, funct3})
                    10'b0000000_000: begin
                        REGWRITE = 1'b1;
                        ILLEGAL = 1'b0;
                    end
                    10'b0100000_000: begin
                        REGWRITE = 1'b1;
                        ALUCTRL = 3'b001;
                        ILLEGAL = 1'b0;
                    end
                    10'b0000000_111: begin
                        REGWRITE = 1'b1;
                        ALUCTRL = 3'b010;
                        ILLEGAL = 1'b0;
                    end
                    default: begin end // 기본값 유지
                endcase
            end
            7'b0010011: begin // ADDI
                if (funct3 == 3'b000) begin
                    REGWRITE = 1'b1;
                    ALUSRC = 1'b1;
                    ILLEGAL = 1'b0;
                end
            end
            7'b0000011: begin // LW
                if (funct3 == 3'b010) begin
                    REGWRITE = 1'b1;
                    ALUSRC = 1'b1;
                    RESULTSRC = 2'b01;
                    ILLEGAL = 1'b0;
                end
            end
            7'b0100011: begin // SW
                if (funct3 == 3'b010) begin
                    MEMWRITE = 1'b1;
                    ALUSRC = 1'b1;
                    IMMSRC = 2'b01;
                    ILLEGAL = 1'b0;
                end
            end
            7'b1100011: begin // BEQ: ZERO는 외부 ALU 비교 결과
                if (funct3 == 3'b000) begin
                    branch = 1'b1;
                    IMMSRC = 2'b10;
                    ALUCTRL = 3'b001;
                    ILLEGAL = 1'b0;
                end
            end
            7'b1101111: begin // JAL: 목적지 계산기는 이 파일 밖
                REGWRITE = 1'b1;
                RESULTSRC = 2'b10;
                IMMSRC = 2'b11;
                jump = 1'b1;
                ILLEGAL = 1'b0;
            end
            default: begin end
        endcase
    end
    // BEQ는 같을 때만, JAL은 ZERO와 무관하게 분기
    assign PCSRC = jump | (branch & ZERO);
endmodule
