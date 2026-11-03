`timescale 1ns/1ps
// Set an input, wait briefly, then compare with an expected constant.
module tb_W03_HEX_DEMO;
    reg [3:0] SW;
    wire [6:0] HEX0;
    integer errors;

    W03_HEX_DEMO u_demo (
        .SW(SW),
        .HEX0(HEX0)
    );

    initial begin
        // 파형 저장: 실행 전에 현재 폴더에서 mkdir -p build 실행.
        // 0은 아래 모든 회로 계층을 기록한다는 뜻. 합성용 RTL에는 넣지 않음.
        $dumpfile("build/demo.vcd");
        $dumpvars(0, tb_W03_HEX_DEMO);

        errors = 0;

        SW = 4'd0;
        #10;
        if (HEX0 !== 7'b1000000) begin
            $display("FAIL: SW=0 HEX0=%b", HEX0);
            errors = errors + 1;
        end

        SW = 4'd1;
        #10;
        if (HEX0 !== 7'b1111001) begin
            $display("FAIL: SW=1 HEX0=%b", HEX0);
            errors = errors + 1;
        end

        SW = 4'd2;
        #10;
        if (HEX0 !== 7'b0100100) begin
            $display("FAIL: SW=2 HEX0=%b", HEX0);
            errors = errors + 1;
        end

        SW = 4'd3;
        #10;
        if (HEX0 !== 7'b0110000) begin
            $display("FAIL: SW=3 HEX0=%b", HEX0);
            errors = errors + 1;
        end

        SW = 4'd4;
        #10;
        if (HEX0 !== 7'b0011001) begin
            $display("FAIL: SW=4 HEX0=%b", HEX0);
            errors = errors + 1;
        end

        SW = 4'd5;
        #10;
        if (HEX0 !== 7'b0010010) begin
            $display("FAIL: SW=5 HEX0=%b", HEX0);
            errors = errors + 1;
        end

        SW = 4'd6;
        #10;
        if (HEX0 !== 7'b0000010) begin
            $display("FAIL: SW=6 HEX0=%b", HEX0);
            errors = errors + 1;
        end

        SW = 4'd7;
        #10;
        if (HEX0 !== 7'b1111000) begin
            $display("FAIL: SW=7 HEX0=%b", HEX0);
            errors = errors + 1;
        end

        SW = 4'd8;
        #10;
        if (HEX0 !== 7'b0000000) begin
            $display("FAIL: SW=8 HEX0=%b", HEX0);
            errors = errors + 1;
        end

        SW = 4'd9;
        #10;
        if (HEX0 !== 7'b0010000) begin
            $display("FAIL: SW=9 HEX0=%b", HEX0);
            errors = errors + 1;
        end

        SW = 4'd10;
        #10;
        if (HEX0 !== 7'b1111111) begin
            $display("FAIL: SW=10 should be blank, HEX0=%b", HEX0);
            errors = errors + 1;
        end

        SW = 4'd15;
        #10;
        if (HEX0 !== 7'b1111111) begin
            $display("FAIL: SW=15 should be blank, HEX0=%b", HEX0);
            errors = errors + 1;
        end

        if (errors == 0) $display("PASS: W03_HEX_DEMO (0..9, 10, 15)");
        else             $display("FAIL: W03_HEX_DEMO errors=%d", errors);
        $finish;
    end
endmodule
