`timescale 1ns/1ps
// 입력 대입 → #10 → result/zero의 독립된 기대 상수 비교 → 결과 출력.
// #10은 검사 대기 시간이며 실제 ALU 지연 또는 클록 주기가 아닙니다.
module tb_03_compare_shift;
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
        $dumpfile("build/03_compare_shift.vcd");
        $dumpvars(0, tb_03_compare_shift);
`ifdef DUMP_FSDB
        $fsdbDumpfile("build/03_compare_shift.fsdb");
        $fsdbDumpvars(0, tb_03_compare_shift);
`endif

        // T19 SLT: −1 < 1
        a = 32'hffffffff;
        b = 32'h00000001;
        alucontrol = 3'b101;
        expected_result = 32'h00000001;
        expected_zero = 1'b0;
        #10;
        if ((result !== expected_result) || (zero !== expected_zero)) begin
            $display("FAIL: T19 SLT a=%h b=%h result=%h zero=%b expected=%h/%b", a, b, result, zero, expected_result, expected_zero);
            $finish;
        end
        $display("OK: T19 SLT a=%h b=%h result=%h zero=%b", a, b, result, zero);

        // T20 SLT: 1 < −1은 거짓
        a = 32'h00000001;
        b = 32'hffffffff;
        alucontrol = 3'b101;
        expected_result = 32'h00000000;
        expected_zero = 1'b1;
        #10;
        if ((result !== expected_result) || (zero !== expected_zero)) begin
            $display("FAIL: T20 SLT a=%h b=%h result=%h zero=%b expected=%h/%b", a, b, result, zero, expected_result, expected_zero);
            $finish;
        end
        $display("OK: T20 SLT a=%h b=%h result=%h zero=%b", a, b, result, zero);

        // T21 SLT: 감산 overflow 보정 필요
        a = 32'h80000000;
        b = 32'h00000001;
        alucontrol = 3'b101;
        expected_result = 32'h00000001;
        expected_zero = 1'b0;
        #10;
        if ((result !== expected_result) || (zero !== expected_zero)) begin
            $display("FAIL: T21 SLT a=%h b=%h result=%h zero=%b expected=%h/%b", a, b, result, zero, expected_result, expected_zero);
            $finish;
        end
        $display("OK: T21 SLT a=%h b=%h result=%h zero=%b", a, b, result, zero);

        // T22 SLT: 반대 방향 overflow 보정
        a = 32'h7fffffff;
        b = 32'hffffffff;
        alucontrol = 3'b101;
        expected_result = 32'h00000000;
        expected_zero = 1'b1;
        #10;
        if ((result !== expected_result) || (zero !== expected_zero)) begin
            $display("FAIL: T22 SLT a=%h b=%h result=%h zero=%b expected=%h/%b", a, b, result, zero, expected_result, expected_zero);
            $finish;
        end
        $display("OK: T22 SLT a=%h b=%h result=%h zero=%b", a, b, result, zero);

        // T24 SLL: 거리 1
        a = 32'h00000001;
        b = 32'h00000001;
        alucontrol = 3'b110;
        expected_result = 32'h00000002;
        expected_zero = 1'b0;
        #10;
        if ((result !== expected_result) || (zero !== expected_zero)) begin
            $display("FAIL: T24 SLL a=%h b=%h result=%h zero=%b expected=%h/%b", a, b, result, zero, expected_result, expected_zero);
            $finish;
        end
        $display("OK: T24 SLL a=%h b=%h result=%h zero=%b", a, b, result, zero);

        // T25 SLL: 거리 31
        a = 32'h00000001;
        b = 32'h0000001f;
        alucontrol = 3'b110;
        expected_result = 32'h80000000;
        expected_zero = 1'b0;
        #10;
        if ((result !== expected_result) || (zero !== expected_zero)) begin
            $display("FAIL: T25 SLL a=%h b=%h result=%h zero=%b expected=%h/%b", a, b, result, zero, expected_result, expected_zero);
            $finish;
        end
        $display("OK: T25 SLL a=%h b=%h result=%h zero=%b", a, b, result, zero);

        // T27 SLL: B=36이지만 거리 4
        a = 32'h00000001;
        b = 32'h00000024;
        alucontrol = 3'b110;
        expected_result = 32'h00000010;
        expected_zero = 1'b0;
        #10;
        if ((result !== expected_result) || (zero !== expected_zero)) begin
            $display("FAIL: T27 SLL a=%h b=%h result=%h zero=%b expected=%h/%b", a, b, result, zero, expected_result, expected_zero);
            $finish;
        end
        $display("OK: T27 SLL a=%h b=%h result=%h zero=%b", a, b, result, zero);

        // T29 SRL: 부호 확장이 아닌 0 채움
        a = 32'h80000000;
        b = 32'h00000001;
        alucontrol = 3'b111;
        expected_result = 32'h40000000;
        expected_zero = 1'b0;
        #10;
        if ((result !== expected_result) || (zero !== expected_zero)) begin
            $display("FAIL: T29 SRL a=%h b=%h result=%h zero=%b expected=%h/%b", a, b, result, zero, expected_result, expected_zero);
            $finish;
        end
        $display("OK: T29 SRL a=%h b=%h result=%h zero=%b", a, b, result, zero);

        // T30 SRL: 거리 31
        a = 32'h80000000;
        b = 32'h0000001f;
        alucontrol = 3'b111;
        expected_result = 32'h00000001;
        expected_zero = 1'b0;
        #10;
        if ((result !== expected_result) || (zero !== expected_zero)) begin
            $display("FAIL: T30 SRL a=%h b=%h result=%h zero=%b expected=%h/%b", a, b, result, zero, expected_result, expected_zero);
            $finish;
        end
        $display("OK: T30 SRL a=%h b=%h result=%h zero=%b", a, b, result, zero);

        // T32 SRL: B=36이지만 거리 4
        a = 32'h80000000;
        b = 32'h00000024;
        alucontrol = 3'b111;
        expected_result = 32'h08000000;
        expected_zero = 1'b0;
        #10;
        if ((result !== expected_result) || (zero !== expected_zero)) begin
            $display("FAIL: T32 SRL a=%h b=%h result=%h zero=%b expected=%h/%b", a, b, result, zero, expected_result, expected_zero);
            $finish;
        end
        $display("OK: T32 SRL a=%h b=%h result=%h zero=%b", a, b, result, zero);

        // 모든 사례를 통과한 경우에만 전체 PASS가 출력됩니다.
        $display("PASS: W04_DEMO03 (10/10)");
        $finish;
    end
endmodule

// Local Variables:
// verilog-library-directories: ("." "../rtl")
// End:
