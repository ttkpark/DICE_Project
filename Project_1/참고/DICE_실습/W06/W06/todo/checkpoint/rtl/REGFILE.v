module REGFILE (/*AUTOARG*/
    // Outputs
    RD1, RD2,
    // Inputs
    CLK, RESET, WE3, A1, A2, A3, WD3
);
    input wire CLK;
    input wire RESET;
    input wire WE3;
    input wire [4:0] A1;
    input wire [4:0] A2;
    input wire [4:0] A3;
    input wire [31:0] WD3;
    output wire [31:0] RD1;
    output wire [31:0] RD2;

    // 32비트 레지스터 32개. RF[2]는 x2의 저장 공간.
    reg [31:0] RF [0:31];
    integer i;

    always @(posedge CLK or posedge RESET) begin
        if (RESET) begin
            // 배열 전체 초기화. 이 반복문은 RTL 초기화 구조 설명용.
            for (i = 0; i < 32; i = i + 1) begin
                RF[i] <= (/* TODO T1: 리셋 값 */ 32'd1);
            end
        end else if ((/* TODO T2: 쓰기 허용 */ 1'b1) && (A3 != 5'd0)) begin
            // 순차회로의 저장값 갱신에는 non-blocking 사용.
            RF[/* TODO T3: 쓰기 주소 */ 5'd0] <= (/* TODO T4: 쓰기 데이터 */ 32'd0);
        end
        // 쓰기 금지 시 할당하지 않으면 기존 저장값 유지.
    end

    // 두 읽기 포트는 서로 독립적인 조합회로.
    assign RD1 = (A1 == 5'd0) ? 32'd0 : RF[/* TODO T5: 첫 읽기 주소 */ 5'd0];
    assign RD2 = (A2 == 5'd0) ? 32'd0 : RF[/* TODO T6: 둘째 읽기 주소 */ 5'd0];
endmodule
