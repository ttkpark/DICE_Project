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

    // 선택 실습: 아래 기능을 처음부터 작성하세요. 구현 전 검사는 실패합니다.
    // 저장 배열 이름은 RF, 크기는 32개 x 32비트입니다.
    // RESET은 active-high 비동기 리셋이며 모든 저장값을 0으로 만듭니다.
    // 리셋이 쓰기보다 우선합니다. 저장값은 non-blocking으로 갱신합니다.
    // WE3가 1이고 A3가 0이 아닐 때 상승 에지에서 저장합니다.
    // 쓰기 금지 상태에서는 저장값을 유지합니다.
    // RD1/RD2는 조합 읽기이고, x0의 쓰기 금지와 읽기 0 고정을 모두 구현합니다.
endmodule
