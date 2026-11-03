`timescale 1ns/1ps
module pipeline_bad (/*AUTOARG*/
   // Outputs
   q1, q2,
   // Inputs
   clk, reset, data
   );
    input wire clk;
    input wire reset;
    input wire data;
    output reg q1;
    output reg q2;

    // 두 단계에 동일한 active-high 비동기 reset을 적용합니다.
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // TODO B1: 첫 번째 단계의 초기값을 작성하세요.
            q1 = 1'b1;
            // TODO B2: 두 번째 단계의 초기값을 작성하세요.
            q2 = 1'b1;
        end else begin
            // TODO B3: 첫 번째 단계가 읽을 입력을 작성하세요.
            q1 = 1'b0;
            // TODO B4: 두 번째 단계가 읽을 첫 번째 단계 신호를 작성하세요.
            q2 = 1'b0;
        end
    end
    // 비교용입니다. 같은 블록에서 =로 앞서 바뀐 값을 읽을 때의 차이를 관찰하세요.
endmodule
