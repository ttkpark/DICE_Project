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

    // reset의 상승도 감시하므로 클럭 에지 사이에서도 즉시 초기화합니다.
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            q <= 1'b0;
        end else begin
            // <=는 이번 에지에서 읽은 data를 다음 q로 예약합니다.
            // 에지 사이에서는 대입이 실행되지 않으므로 이전 q가 유지됩니다.
            q <= data;
        end
    end
endmodule
