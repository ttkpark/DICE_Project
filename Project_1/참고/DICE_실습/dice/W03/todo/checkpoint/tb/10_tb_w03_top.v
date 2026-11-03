`timescale 1ns/1ps
// 입력 설정 → #10 대기 → 독립된 기대 상수와 비교.
// !==는 X/Z 출력도 실패로 검사. #10은 테스트벤치에서만 사용.
module tb_w03_top;
    reg [7:0] SW;
    wire [6:0] HEX0, HEX1;
    integer errors; // 실패 개수이며 합성되는 회로가 아닙니다.

    W03_TOP u_top (
        .SW(SW),
        .HEX0(HEX0),
        .HEX1(HEX1)
    );

    initial begin
        errors = 0;

        // SW=00, 표시=00
        SW = 8'h00;
        #10;
        if (HEX0 !== 7'b1000000) begin
            $display("FAIL: SW=00, 표시=00, HEX0=%b", HEX0);
            errors = errors + 1;
        end
        if (HEX1 !== 7'b1000000) begin
            $display("FAIL: SW=00, 표시=00, HEX1=%b", HEX1);
            errors = errors + 1;
        end

        // SW=53, 표시=08
        SW = 8'h53;
        #10;
        if (HEX0 !== 7'b0000000) begin
            $display("FAIL: SW=53, 표시=08, HEX0=%b", HEX0);
            errors = errors + 1;
        end
        if (HEX1 !== 7'b1000000) begin
            $display("FAIL: SW=53, 표시=08, HEX1=%b", HEX1);
            errors = errors + 1;
        end

        // SW=37, 표시=10
        SW = 8'h37;
        #10;
        if (HEX0 !== 7'b1000000) begin
            $display("FAIL: SW=37, 표시=10, HEX0=%b", HEX0);
            errors = errors + 1;
        end
        if (HEX1 !== 7'b1111001) begin
            $display("FAIL: SW=37, 표시=10, HEX1=%b", HEX1);
            errors = errors + 1;
        end

        // SW=1F, 표시=16
        SW = 8'h1F;
        #10;
        if (HEX0 !== 7'b0000010) begin
            $display("FAIL: SW=1F, 표시=16, HEX0=%b", HEX0);
            errors = errors + 1;
        end
        if (HEX1 !== 7'b1111001) begin
            $display("FAIL: SW=1F, 표시=16, HEX1=%b", HEX1);
            errors = errors + 1;
        end

        // SW=FF, 표시=30
        SW = 8'hFF;
        #10;
        if (HEX0 !== 7'b1000000) begin
            $display("FAIL: SW=FF, 표시=30, HEX0=%b", HEX0);
            errors = errors + 1;
        end
        if (HEX1 !== 7'b0110000) begin
            $display("FAIL: SW=FF, 표시=30, HEX1=%b", HEX1);
            errors = errors + 1;
        end

        if (errors == 0) $display("PASS: W03_TOP");
        else             $display("FAIL: W03_TOP, errors=%d", errors);
        $finish;
    end
    // VCS 실행 시 파형 저장. 기존 입력과 검사 코드는 그대로 유지합니다.
`ifdef DUMP_FSDB
    initial begin
        $fsdbDumpfile("build/w03_top/waves.fsdb");
        $fsdbDumpvars(0, tb_w03_top);
    end
`endif
endmodule
