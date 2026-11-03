`timescale 1ns/1ps
module PC (/*AUTOARG*/
   // Outputs
   PC,
   // Inputs
   clk, reset, ImmExt, PCSrc
   );
    input wire        clk;
    input wire        reset;
    input wire [31:0] ImmExt;
    input wire        PCSrc;
    output wire [31:0] PC;

    reg  [31:0] PC_reg;
    wire [31:0] PCPlus4;
    wire [31:0] PCTarget;
    wire [31:0] PCNext;

    // 고정 길이 32비트 명령어를 가정하므로 순차 주소는 4바이트 증가합니다.
    assign PCPlus4 = PC_reg + 32'd4;
    // ImmExt는 이미 확장·정렬 처리가 끝난 바이트 오프셋입니다.
    // 분기의 기준은 현재 PC이며 PC+4가 아닙니다.
    assign PCTarget = PC_reg + ImmExt;
    assign PCNext = PCSrc ? PCTarget : PCPlus4;

    // 조합회로의 계산 결과를 상승 에지에 저장합니다.
    // reset은 active-high 비동기 입력이므로 클럭을 기다리지 않습니다.
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            PC_reg <= 32'd0;
        end else begin
            // <=는 이번 에지에서 읽은 다음 주소를 저장하도록 예약합니다.
            PC_reg <= PCNext;
        end
    end

    // 외부 PC는 다음 주소 후보가 아니라 현재 저장된 주소입니다.
    assign PC = PC_reg;
endmodule
