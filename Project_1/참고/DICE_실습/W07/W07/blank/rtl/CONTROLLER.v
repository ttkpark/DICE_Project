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
    // 아래 기본값과 assign을 진리표에 맞는 조합논리로 교체
    // 미완성판도 입력 변화 시 안전 기본값을 출력 (완성 시 always @* 사용)
    always @(INSTR or ZERO) begin
        REGWRITE = 0;
        MEMWRITE = 0;
        ALUSRC = 0;
        RESULTSRC = 0;
        IMMSRC = 0;
        ALUCTRL = 0;
        ILLEGAL = 1;
    end
    assign PCSRC = 0;
endmodule
