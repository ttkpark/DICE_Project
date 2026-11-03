module alu (/*AUTOARG*/
    // Outputs
    result,
    zero,
    // Inputs
    a,
    b,
    alucontrol
);
    output [31:0] result;
    output        zero;
    input  [31:0] a;
    input  [31:0] b;
    input  [2:0]  alucontrol;

    // always 안에서 값을 넣는 출력만 reg로 선언
    reg [31:0] result;

    wire        sub;
    wire [31:0] b_mod;
    wire [32:0] sum_ext;
    wire [31:0] sum32;
    wire        v_raw;
    wire        slt_bit;

    // 아래 세 신호는 파형 설명용이며 외부 포트를 추가하지 않음
    wire        n;
    wire        c;
    wire        v;

    // SUB와 SLT는 모두 A-B가 필요하므로 감산 모드 선택
    // DONE CP01: SUB와 SLT에서 감산 선택
    assign sub = (alucontrol == 3'b001) ||
                 (alucontrol == 3'b101);

    // sub=0이면 B 그대로, sub=1이면 B의 모든 비트를 반전
    // DONE CP02: sub=1일 때 B의 모든 비트 반전
    assign b_mod = b ^ {32{sub}};

    // 먼저 33비트로 넓힌 뒤 더하여 마지막 자리올림까지 보존
    // sub=1일 때 반전한 B에 1을 더하므로 A+(~B)+1이 됨
    // DONE CP03: 33비트 가산기에 두 값과 sub 입력
    assign sum_ext = {1'b0, a} + {1'b0, b_mod} + {32'b0, sub};
    assign sum32 = sum_ext[31:0];

    // 가산기 중간 결과의 overflow. 최종 result로 계산하지 않음
    assign v_raw = (a[31] ^ sum32[31]) &
                   ~(a[31] ^ b[31] ^ sub);

    // 감산 결과의 부호를 overflow로 보정한 signed 비교
    // DONE CP04: 감산 결과의 부호를 overflow로 보정
    assign slt_bit = sum32[31] ^ v_raw;

    // 입력이 바뀌면 다시 계산. 모든 분기에서 출력 대입
    always @(*) begin
        case (alucontrol)
            // DONE CP05: ADD 결과 선택
            3'b000: result = sum32;
            // DONE CP06: SUB 결과 선택
            3'b001: result = sum32;
            // DONE CP07: 각 자리에서 두 비트가 모두 1
            3'b010: result = a & b;
            // DONE CP08: 각 자리에서 하나라도 1
            3'b011: result = a | b;
            // DONE CP09: 각 자리에서 두 비트가 다름
            3'b100: result = a ^ b;
            3'b101: result = {31'b0, slt_bit};
            // DONE CP10: B의 하위 5비트만큼 왼쪽 이동
            3'b110: result = a << b[4:0];
            // DONE CP11: B의 하위 5비트만큼 오른쪽 이동
            3'b111: result = a >> b[4:0];
            default: result = 32'b0;
        endcase
    end

    // Zero는 가산기 중간값이 아닌 선택된 최종 결과로 판단
    // DONE CP12: 선택된 최종 결과가 0인지 확인
    assign zero = (result == 32'b0);
    assign n = result[31];

    // C/V 관측 신호는 ADD 또는 SUB일 때만 유효하게 표시
    assign c = ((alucontrol == 3'b000) ||
                (alucontrol == 3'b001)) ? sum_ext[32] : 1'b0;
    assign v = ((alucontrol == 3'b000) ||
                (alucontrol == 3'b001)) ? v_raw : 1'b0;
endmodule

// Local Variables:
// verilog-auto-arg-format: single
// End:
