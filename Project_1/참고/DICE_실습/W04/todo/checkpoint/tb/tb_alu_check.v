`timescale 1ns/1ps
// 입력 대입 → #10 → result/zero의 독립된 기대 상수 비교 → 결과 출력.
// #10은 검사 대기 시간이며 실제 ALU 지연 또는 클록 주기가 아닙니다.
module tb_alu_check;
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
        $dumpfile("build/alu_check.vcd");
        $dumpvars(0, tb_alu_check);
`ifdef DUMP_FSDB
        $fsdbDumpfile("build/alu_check.fsdb");
        $fsdbDumpvars(0, tb_alu_check);
`endif

        // T01 ADD: 0+0
        a = 32'h00000000;
        b = 32'h00000000;
        alucontrol = 3'b000;
        expected_result = 32'h00000000;
        expected_zero = 1'b1;
        #10;
        if ((result !== expected_result) || (zero !== expected_zero)) begin
            $display("FAIL: T01 ADD a=%h b=%h result=%h zero=%b expected=%h/%b", a, b, result, zero, expected_result, expected_zero);
            $finish;
        end
        $display("OK: T01 ADD a=%h b=%h result=%h zero=%b", a, b, result, zero);

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

        // T03 ADD: carry=1, overflow=0
        a = 32'hffffffff;
        b = 32'h00000001;
        alucontrol = 3'b000;
        expected_result = 32'h00000000;
        expected_zero = 1'b1;
        #10;
        if ((result !== expected_result) || (zero !== expected_zero)) begin
            $display("FAIL: T03 ADD a=%h b=%h result=%h zero=%b expected=%h/%b", a, b, result, zero, expected_result, expected_zero);
            $finish;
        end
        $display("OK: T03 ADD a=%h b=%h result=%h zero=%b", a, b, result, zero);

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

        // T05 ADD: carry=1, overflow=1
        a = 32'h80000000;
        b = 32'h80000000;
        alucontrol = 3'b000;
        expected_result = 32'h00000000;
        expected_zero = 1'b1;
        #10;
        if ((result !== expected_result) || (zero !== expected_zero)) begin
            $display("FAIL: T05 ADD a=%h b=%h result=%h zero=%b expected=%h/%b", a, b, result, zero, expected_result, expected_zero);
            $finish;
        end
        $display("OK: T05 ADD a=%h b=%h result=%h zero=%b", a, b, result, zero);

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

        // T07 SUB: borrow 있음
        a = 32'h00000003;
        b = 32'h00000008;
        alucontrol = 3'b001;
        expected_result = 32'hfffffffb;
        expected_zero = 1'b0;
        #10;
        if ((result !== expected_result) || (zero !== expected_zero)) begin
            $display("FAIL: T07 SUB a=%h b=%h result=%h zero=%b expected=%h/%b", a, b, result, zero, expected_result, expected_zero);
            $finish;
        end
        $display("OK: T07 SUB a=%h b=%h result=%h zero=%b", a, b, result, zero);

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

        // T09 SUB: 음수 방향 overflow
        a = 32'h80000000;
        b = 32'h00000001;
        alucontrol = 3'b001;
        expected_result = 32'h7fffffff;
        expected_zero = 1'b0;
        #10;
        if ((result !== expected_result) || (zero !== expected_zero)) begin
            $display("FAIL: T09 SUB a=%h b=%h result=%h zero=%b expected=%h/%b", a, b, result, zero, expected_result, expected_zero);
            $finish;
        end
        $display("OK: T09 SUB a=%h b=%h result=%h zero=%b", a, b, result, zero);

        // T10 SUB: 양수 방향 overflow
        a = 32'h7fffffff;
        b = 32'hffffffff;
        alucontrol = 3'b001;
        expected_result = 32'h80000000;
        expected_zero = 1'b0;
        #10;
        if ((result !== expected_result) || (zero !== expected_zero)) begin
            $display("FAIL: T10 SUB a=%h b=%h result=%h zero=%b expected=%h/%b", a, b, result, zero, expected_result, expected_zero);
            $finish;
        end
        $display("OK: T10 SUB a=%h b=%h result=%h zero=%b", a, b, result, zero);

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

        // T12 AND: 가산기 합이 아닌 최종 결과로 Zero
        a = 32'h000000f0;
        b = 32'h0000000f;
        alucontrol = 3'b010;
        expected_result = 32'h00000000;
        expected_zero = 1'b1;
        #10;
        if ((result !== expected_result) || (zero !== expected_zero)) begin
            $display("FAIL: T12 AND a=%h b=%h result=%h zero=%b expected=%h/%b", a, b, result, zero, expected_result, expected_zero);
            $finish;
        end
        $display("OK: T12 AND a=%h b=%h result=%h zero=%b", a, b, result, zero);

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

        // T15 XOR: 같은 비트패턴의 XOR
        a = 32'h55555555;
        b = 32'h55555555;
        alucontrol = 3'b100;
        expected_result = 32'h00000000;
        expected_zero = 1'b1;
        #10;
        if ((result !== expected_result) || (zero !== expected_zero)) begin
            $display("FAIL: T15 XOR a=%h b=%h result=%h zero=%b expected=%h/%b", a, b, result, zero, expected_result, expected_zero);
            $finish;
        end
        $display("OK: T15 XOR a=%h b=%h result=%h zero=%b", a, b, result, zero);

        // T16 SLT: 양수 비교 참
        a = 32'h00000003;
        b = 32'h00000008;
        alucontrol = 3'b101;
        expected_result = 32'h00000001;
        expected_zero = 1'b0;
        #10;
        if ((result !== expected_result) || (zero !== expected_zero)) begin
            $display("FAIL: T16 SLT a=%h b=%h result=%h zero=%b expected=%h/%b", a, b, result, zero, expected_result, expected_zero);
            $finish;
        end
        $display("OK: T16 SLT a=%h b=%h result=%h zero=%b", a, b, result, zero);

        // T17 SLT: 양수 비교 거짓
        a = 32'h00000008;
        b = 32'h00000003;
        alucontrol = 3'b101;
        expected_result = 32'h00000000;
        expected_zero = 1'b1;
        #10;
        if ((result !== expected_result) || (zero !== expected_zero)) begin
            $display("FAIL: T17 SLT a=%h b=%h result=%h zero=%b expected=%h/%b", a, b, result, zero, expected_result, expected_zero);
            $finish;
        end
        $display("OK: T17 SLT a=%h b=%h result=%h zero=%b", a, b, result, zero);

        // T18 SLT: 같으면 거짓
        a = 32'h00000003;
        b = 32'h00000003;
        alucontrol = 3'b101;
        expected_result = 32'h00000000;
        expected_zero = 1'b1;
        #10;
        if ((result !== expected_result) || (zero !== expected_zero)) begin
            $display("FAIL: T18 SLT a=%h b=%h result=%h zero=%b expected=%h/%b", a, b, result, zero, expected_result, expected_zero);
            $finish;
        end
        $display("OK: T18 SLT a=%h b=%h result=%h zero=%b", a, b, result, zero);

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

        // T23 SLL: 거리 0
        a = 32'h00000001;
        b = 32'h00000000;
        alucontrol = 3'b110;
        expected_result = 32'h00000001;
        expected_zero = 1'b0;
        #10;
        if ((result !== expected_result) || (zero !== expected_zero)) begin
            $display("FAIL: T23 SLL a=%h b=%h result=%h zero=%b expected=%h/%b", a, b, result, zero, expected_result, expected_zero);
            $finish;
        end
        $display("OK: T23 SLL a=%h b=%h result=%h zero=%b", a, b, result, zero);

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

        // T26 SLL: B=32지만 거리 0
        a = 32'h00000001;
        b = 32'h00000020;
        alucontrol = 3'b110;
        expected_result = 32'h00000001;
        expected_zero = 1'b0;
        #10;
        if ((result !== expected_result) || (zero !== expected_zero)) begin
            $display("FAIL: T26 SLL a=%h b=%h result=%h zero=%b expected=%h/%b", a, b, result, zero, expected_result, expected_zero);
            $finish;
        end
        $display("OK: T26 SLL a=%h b=%h result=%h zero=%b", a, b, result, zero);

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

        // T28 SRL: 거리 0
        a = 32'h80000000;
        b = 32'h00000000;
        alucontrol = 3'b111;
        expected_result = 32'h80000000;
        expected_zero = 1'b0;
        #10;
        if ((result !== expected_result) || (zero !== expected_zero)) begin
            $display("FAIL: T28 SRL a=%h b=%h result=%h zero=%b expected=%h/%b", a, b, result, zero, expected_result, expected_zero);
            $finish;
        end
        $display("OK: T28 SRL a=%h b=%h result=%h zero=%b", a, b, result, zero);

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

        // T31 SRL: B=32지만 거리 0
        a = 32'h80000000;
        b = 32'h00000020;
        alucontrol = 3'b111;
        expected_result = 32'h80000000;
        expected_zero = 1'b0;
        #10;
        if ((result !== expected_result) || (zero !== expected_zero)) begin
            $display("FAIL: T31 SRL a=%h b=%h result=%h zero=%b expected=%h/%b", a, b, result, zero, expected_result, expected_zero);
            $finish;
        end
        $display("OK: T31 SRL a=%h b=%h result=%h zero=%b", a, b, result, zero);

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

        // T33 SRL: 시프트 결과의 Zero
        a = 32'h00000001;
        b = 32'h00000001;
        alucontrol = 3'b111;
        expected_result = 32'h00000000;
        expected_zero = 1'b1;
        #10;
        if ((result !== expected_result) || (zero !== expected_zero)) begin
            $display("FAIL: T33 SRL a=%h b=%h result=%h zero=%b expected=%h/%b", a, b, result, zero, expected_result, expected_zero);
            $finish;
        end
        $display("OK: T33 SRL a=%h b=%h result=%h zero=%b", a, b, result, zero);

        // T34 OR: 논리 결과의 Zero
        a = 32'h00000000;
        b = 32'h00000000;
        alucontrol = 3'b011;
        expected_result = 32'h00000000;
        expected_zero = 1'b1;
        #10;
        if ((result !== expected_result) || (zero !== expected_zero)) begin
            $display("FAIL: T34 OR a=%h b=%h result=%h zero=%b expected=%h/%b", a, b, result, zero, expected_result, expected_zero);
            $finish;
        end
        $display("OK: T34 OR a=%h b=%h result=%h zero=%b", a, b, result, zero);

        // 모든 사례를 통과한 경우에만 전체 PASS가 출력됩니다.
        $display("PASS: W04_CHECKPOINT (34/34)");
        $finish;
    end
endmodule

// Local Variables:
// verilog-library-directories: ("." "../rtl")
// End:
