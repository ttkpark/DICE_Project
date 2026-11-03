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

    // 자유 작성: 필요한 내부 신호와 동작을 작성하세요. 포트는 변경하지 않습니다.
endmodule
