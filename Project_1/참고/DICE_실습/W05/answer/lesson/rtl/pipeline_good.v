`timescale 1ns/1ps
module pipeline_good (/*AUTOARG*/
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

    // 두 레지스터 모두 active-high 비동기 reset으로 초기화합니다.
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            q1 <= 1'b0;
            q2 <= 1'b0;
        end else begin
            // <=의 우변은 갱신 전 값으로 읽습니다. 두 레지스터의 전달을 표현합니다.
            q1 <= data;
            q2 <= q1;       // 이번 에지 직전의 q1이 두 번째 단계에 저장됩니다.
        end
    end
endmodule
