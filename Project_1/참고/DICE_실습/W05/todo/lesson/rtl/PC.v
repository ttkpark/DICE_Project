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

    // TODO 1: 현재 PC에서 다음 순차 주소를 계산하세요.
    assign PCPlus4 = PC_reg;
    // TODO 2: 현재 PC를 기준으로 바이트 오프셋을 더한 분기 주소를 계산하세요.
    assign PCTarget = ImmExt;
    // TODO 3: PCSrc에 따라 다음에 저장할 주소 후보를 선택하세요.
    assign PCNext = PCPlus4;

    // reset은 클럭을 기다리지 않는 active-high 비동기 초기화입니다.
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // TODO 4: reset 시 저장할 초기 주소를 작성하세요.
            PC_reg <= 32'd4;
        end else begin
            // TODO 5: 정상 상승 에지에서 저장할 다음 주소를 작성하세요.
            PC_reg <= PC_reg;
        end
    end
    // <=는 이번 에지에서 읽은 값을 다음 상태로 예약하므로 그대로 사용합니다.
    // TODO 6: 현재 저장된 주소를 외부 출력으로 연결하세요.
    assign PC = 32'd0;
endmodule
