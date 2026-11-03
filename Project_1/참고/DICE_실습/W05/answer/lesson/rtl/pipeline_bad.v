`timescale 1ns/1ps
// 비교 관찰용: 두 단계 지연을 의도했지만 blocking 대입으로 작성한 예입니다.
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

    // 정상 예제와 동일한 active-high 비동기 reset 조건입니다.
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            q1 = 1'b0;
            q2 = 1'b0;
        end else begin
            q1 = data;      // 같은 블록 안에서 q1이 먼저 바뀝니다.
            q2 = q1;        // 이미 바뀐 q1을 읽으므로 첫 에지부터 둘 다 data입니다.
        end
    end
    // '='만으로 조합회로가 되는 것은 아닙니다. 이벤트 제어와 데이터 의존성도 중요합니다.
    // 레지스터 사이의 이전 상태 전달은 pipeline_good.v의 <=로 표현합니다.
endmodule
