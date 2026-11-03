`timescale 1ns/1ps
// 입력 대입 → #10 → result/zero의 독립된 기대 상수 비교 → 결과 출력.
// #10은 검사 대기 시간이며 실제 ALU 지연 또는 클록 주기가 아닙니다.
module tb_01_addsub;
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
        $dumpfile("build/01_addsub.vcd");
        $dumpvars(0, tb_01_addsub);
`ifdef DUMP_FSDB
        $fsdbDumpfile("build/01_addsub.fsdb");
        $fsdbDumpvars(0, tb_01_addsub);
`endif

        // T02 ADD: 일반 합
        a = 32'h00000003;
        b = 32'h00000005;
        alucontrol = 3'b000;
        expected_result = 32'h00000008;
        expected_zero = 1'b0;
        #10;
        if ((result !== expected_result) || (zero !== expected_zero)) begin
            $display("FAIL: T02 ADD a=%h b=%h result=%h zero=%b expected=%h/%b", a, b, result, zero, expected_result, expected_zero);
            $finish;
        end
        $display("OK: T02 ADD a=%h b=%h result=%h zero=%b", a, b, result, zero);

        // T06 SUB: borrow 없음
        a = 32'h00000008;
        b = 32'h00000003;
        alucontrol = 3'b001;
        expected_result = 32'h00000005;
        expected_zero = 1'b0;
        #10;
        if ((result !== expected_result) || (zero !== expected_zero)) begin
            $display("FAIL: T06 SUB a=%h b=%h result=%h zero=%b expected=%h/%b", a, b, result, zero, expected_result, expected_zero);
            $finish;
        end
        $display("OK: T06 SUB a=%h b=%h result=%h zero=%b", a, b, result, zero);

        // T08 SUB: 같은 수의 차
        a = 32'h00000005;
        b = 32'h00000005;
        alucontrol = 3'b001;
        expected_result = 32'h00000000;
        expected_zero = 1'b1;
        #10;
        if ((result !== expected_result) || (zero !== expected_zero)) begin
            $display("FAIL: T08 SUB a=%h b=%h result=%h zero=%b expected=%h/%b", a, b, result, zero, expected_result, expected_zero);
            $finish;
        end
        $display("OK: T08 SUB a=%h b=%h result=%h zero=%b", a, b, result, zero);

        // T04 ADD: carry=0, overflow=1
        a = 32'h7fffffff;
        b = 32'h00000001;
        alucontrol = 3'b000;
        expected_result = 32'h80000000;
        expected_zero = 1'b0;
        #10;
        if ((result !== expected_result) || (zero !== expected_zero)) begin
            $display("FAIL: T04 ADD a=%h b=%h result=%h zero=%b expected=%h/%b", a, b, result, zero, expected_result, expected_zero);
            $finish;
        end
        $display("OK: T04 ADD a=%h b=%h result=%h zero=%b", a, b, result, zero);

        // 모든 사례를 통과한 경우에만 전체 PASS가 출력됩니다.
        $display("PASS: W04_DEMO01 (4/4)");
        $finish;
    end
endmodule

// Local Variables:
// verilog-library-directories: ("." "../rtl")
// End:
