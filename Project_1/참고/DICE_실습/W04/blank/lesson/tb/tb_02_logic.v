`timescale 1ns/1ps
// 입력 대입 → #10 → result/zero의 독립된 기대 상수 비교 → 결과 출력.
// #10은 검사 대기 시간이며 실제 ALU 지연 또는 클록 주기가 아닙니다.
module tb_02_logic;
    reg  [31:0] a;
    reg  [31:0] b;
    reg  [2:0]  alucontrol;
    reg  [31:0] expected_result;
    reg         expected_zero;
    wire [31:0] result;
    wire        zero;

    alu dut (/*AUTOINST*/
        // Outputs
        .result     (result),
        .zero       (zero),
        // Inputs
        .a          (a),
        .b          (b),
        .alucontrol (alucontrol)
    );

    initial begin
        // VCD는 기본 저장. VCS --fsdb 실행에서는 FSDB도 함께 저장합니다.
        $dumpfile("build/02_logic.vcd");
        $dumpvars(0, tb_02_logic);
`ifdef DUMP_FSDB
        $fsdbDumpfile("build/02_logic.fsdb");
        $fsdbDumpvars(0, tb_02_logic);
`endif

        // T11 AND: 비트별 AND
        a = 32'h0000000a;
        b = 32'h0000000c;
        alucontrol = 3'b010;
        expected_result = 32'h00000008;
        expected_zero = 1'b0;
        #10;
        if ((result !== expected_result) || (zero !== expected_zero)) begin
            $display("FAIL: T11 AND a=%h b=%h result=%h zero=%b expected=%h/%b", a, b, result, zero, expected_result, expected_zero);
            $finish;
        end
        $display("OK: T11 AND a=%h b=%h result=%h zero=%b", a, b, result, zero);

        // T13 OR: 비트별 OR
        a = 32'h0000000a;
        b = 32'h0000000c;
        alucontrol = 3'b011;
        expected_result = 32'h0000000e;
        expected_zero = 1'b0;
        #10;
        if ((result !== expected_result) || (zero !== expected_zero)) begin
            $display("FAIL: T13 OR a=%h b=%h result=%h zero=%b expected=%h/%b", a, b, result, zero, expected_result, expected_zero);
            $finish;
        end
        $display("OK: T13 OR a=%h b=%h result=%h zero=%b", a, b, result, zero);

        // T14 XOR: 비트별 XOR
        a = 32'h0000000a;
        b = 32'h0000000c;
        alucontrol = 3'b100;
        expected_result = 32'h00000006;
        expected_zero = 1'b0;
        #10;
        if ((result !== expected_result) || (zero !== expected_zero)) begin
            $display("FAIL: T14 XOR a=%h b=%h result=%h zero=%b expected=%h/%b", a, b, result, zero, expected_result, expected_zero);
            $finish;
        end
        $display("OK: T14 XOR a=%h b=%h result=%h zero=%b", a, b, result, zero);

        // 모든 사례를 통과한 경우에만 전체 PASS가 출력됩니다.
        $display("PASS: W04_DEMO02 (3/3)");
        $finish;
    end
endmodule

// Local Variables:
// verilog-library-directories: ("." "../rtl")
// End:
