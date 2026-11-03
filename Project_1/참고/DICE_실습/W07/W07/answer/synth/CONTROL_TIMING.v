// 타이밍 관찰용. 단일 사이클 CPU에 삽입할 레지스터가 아님.
module CONTROL_TIMING (
    input wire CLK,
    input wire [31:0] INSTR,
    input wire ZERO,
    output reg [11:0] CTRL_Q
);
    reg [31:0] instr_q;
    reg zero_q;
    wire REGWRITE;
    wire MEMWRITE;
    wire ALUSRC;
    wire [1:0] RESULTSRC;
    wire [1:0] IMMSRC;
    wire [2:0] ALUCTRL;
    wire PCSRC;
    wire ILLEGAL;
    // Emacs AUTO 갱신 후에도 입력 레지스터를 우회하지 않도록 연결 이름 고정.
    /* CONTROLLER AUTO_TEMPLATE (
        .INSTR(instr_q[]),
        .ZERO(zero_q));
    */
    CONTROLLER u_ctrl (/*AUTOINST*/
        .INSTR(instr_q),
        .ZERO(zero_q),
        .REGWRITE(REGWRITE),
        .MEMWRITE(MEMWRITE),
        .ALUSRC(ALUSRC),
        .RESULTSRC(RESULTSRC),
        .IMMSRC(IMMSRC),
        .ALUCTRL(ALUCTRL),
        .PCSRC(PCSRC),
        .ILLEGAL(ILLEGAL)
    );
    // CTRL_Q는 edge 직전 instr_q의 decode 결과 저장
    always @(posedge CLK) begin
        instr_q <= INSTR;
        zero_q <= ZERO;
        CTRL_Q <= {REGWRITE, MEMWRITE, ALUSRC, RESULTSRC,
                   IMMSRC, ALUCTRL, PCSRC, ILLEGAL};
    end
endmodule

// Local Variables:
// verilog-library-directories: ("." "../rtl")
// End:
