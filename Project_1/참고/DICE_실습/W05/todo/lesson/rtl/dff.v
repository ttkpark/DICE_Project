`timescale 1ns/1ps
module dff (/*AUTOARG*/
   // Outputs
   q,
   // Inputs
   clk, reset, data
   );
    input wire clk;
    input wire reset;
    input wire data;
    output reg q;

    // reset은 클럭을 기다리지 않는 active-high 비동기 입력입니다.
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // TODO D1: reset이 들어왔을 때 저장할 초기값을 작성하세요.
            q <= 1'b1;
        end else begin
            // TODO D2: 이번 상승 에지에서 저장해야 할 입력을 작성하세요.
            q <= 1'b0;
        end
    end
    // <=는 에지에서 읽은 값을 다음 상태로 예약합니다. 위 우변을 완성하세요.
endmodule
