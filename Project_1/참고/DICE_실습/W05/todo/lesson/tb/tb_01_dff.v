`timescale 1ns/1ps
module tb_01_dff;
    reg clk;
    reg reset;
    reg data;
    wire q;

    dff u_dff (/*AUTOINST*/
	       // Outputs
	       .q			(q),
	       // Inputs
	       .clk			(clk),
	       .reset			(reset),
	       .data			(data));

    initial clk = 1'b0;
    always #5 clk = ~clk;  // 주기 10ns. 클럭 생성만 반복합니다.

    initial begin
        $dumpfile("build/01_dff.vcd");
        $dumpvars(0, tb_01_dff);
`ifdef DUMP_FSDB
        $fsdbDumpfile("build/01_dff.fsdb");
        $fsdbDumpvars(0, tb_01_dff);
`endif
    end

    initial begin
        reset = 1'b0;
        data = 1'b0;
        #2;
        reset = 1'b1;      // 첫 상승 에지 5ns보다 먼저 실제 0→1 전이를 만듭니다.
        #1;
        if (q !== 1'b0) begin
            $fatal(1, "FAIL D01 async reset: expected q=0, actual=%b", q);
        end

        @(posedge clk);
        #1;                // TB 관찰 지연: <=의 갱신이 끝난 뒤 읽습니다.
        if (q !== 1'b0) begin
            $fatal(1, "FAIL D02 reset held: expected q=0, actual=%b", q);
        end

        @(negedge clk);     // DUT가 읽는 상승 에지와 떨어진 시점에 입력을 바꿉니다.
        reset = 1'b0;
        data = 1'b1;
        #1;
        if (q !== 1'b0) begin
            $fatal(1, "FAIL D03 hold before edge: expected q=0, actual=%b", q);
        end
        @(posedge clk);
        #1;
        if (q !== 1'b1) begin
            $fatal(1, "FAIL D04 capture 1: expected q=1, actual=%b", q);
        end

        @(negedge clk);
        data = 1'b0;
        #1;
        if (q !== 1'b1) begin
            $fatal(1, "FAIL D05 hold before edge: expected q=1, actual=%b", q);
        end
        @(posedge clk);
        #1;
        if (q !== 1'b0) begin
            $fatal(1, "FAIL D06 capture 0: expected q=0, actual=%b", q);
        end

        @(negedge clk);
        data = 1'b1;
        @(posedge clk);
        #1;
        if (q !== 1'b1) begin
            $fatal(1, "FAIL D07 prepare reset: expected q=1, actual=%b", q);
        end
        #1;
        reset = 1'b1;      // q=1인 동작 중에도 다음 에지 전에 초기화되는지 봅니다.
        #1;
        if (q !== 1'b0) begin
            $fatal(1, "FAIL D08 async reset again: expected q=0, actual=%b", q);
        end
        $display("W05 DFF PASS (8/8)");
        $finish;
    end

    initial begin
        #1000;
        $fatal(1, "TIMEOUT");
    end
endmodule

// Local Variables:
// verilog-library-directories: ("." "../rtl")
// End:
