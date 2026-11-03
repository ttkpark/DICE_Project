`timescale 1ns/1ps
// 고정 검사기입니다. 학생은 rtl/PC.v만 수정합니다.
module tb_checkpoint;
    reg clk;
    reg reset;
    reg [31:0] imm_ext;
    reg pc_src;
    wire [31:0] pc;

    /* PC AUTO_TEMPLATE (
        .PC(pc[]),
        .ImmExt(imm_ext[]),
        .PCSrc(pc_src),
    ); */
    PC u_pc (/*AUTOINST*/
	     // Outputs
	     .PC			(pc[31:0]),		 // Templated
	     // Inputs
	     .clk			(clk),
	     .reset			(reset),
	     .ImmExt			(imm_ext[31:0]),	 // Templated
	     .PCSrc			(pc_src));		 // Templated

    initial clk = 1'b0;
    always #5 clk = ~clk;

    initial begin
        $dumpfile("build/checkpoint.vcd");
        $dumpvars(0, tb_checkpoint);
`ifdef DUMP_FSDB
        $fsdbDumpfile("build/checkpoint.fsdb");
        $fsdbDumpvars(0, tb_checkpoint);
`endif
    end

    initial begin
        reset = 1'b0;       // 초기 X에 의존하지 않고 명시적인 reset 상승을 만듭니다.
        pc_src = 1'b1;
        imm_ext = 32'd16;
        #2;
        reset = 1'b1;       // C01: 2ns 인가, 첫 posedge 5ns 전에 검사합니다.
        #1;
        if (pc !== 32'd0) begin
            $fatal(1, "FAIL C01 async reset: expected PC=0, actual=%h", pc);
        end
        $display("C01 OK PC=%0d", pc);

        @(posedge clk);     // C02: 분기 입력이 있어도 reset이 우선입니다.
        #1;                // <= 갱신이 끝난 뒤 읽기 위한 TB 관찰 지연입니다.
        if (pc !== 32'd0) begin
            $fatal(1, "FAIL C02 reset priority: expected PC=0, actual=%h", pc);
        end
        $display("C02 OK PC=%0d", pc);

        @(negedge clk);     // C03: 상승 에지와 입력 변경이 겹치지 않게 합니다.
        reset = 1'b0;
        pc_src = 1'b0;
        imm_ext = 32'd16;
        @(posedge clk);
        #1;
        if (pc !== 32'd4) begin
            $fatal(1, "FAIL C03 sequential: expected PC=4, actual=%h", pc);
        end
        $display("C03 OK PC=%0d", pc);

        @(negedge clk);     // C04: 저장된 현재 값에서 다시 4 증가합니다.
        pc_src = 1'b0;
        @(posedge clk);
        #1;
        if (pc !== 32'd8) begin
            $fatal(1, "FAIL C04 sequential: expected PC=8, actual=%h", pc);
        end
        $display("C04 OK PC=%0d", pc);

        @(negedge clk);     // C05: 현재 PC 8을 기준으로 16바이트 분기합니다.
        pc_src = 1'b1;
        imm_ext = 32'd16;
        @(posedge clk);
        #1;
        if (pc !== 32'd24) begin
            $fatal(1, "FAIL C05 branch: expected PC=24, actual=%h", pc);
        end
        $display("C05 OK PC=%0d", pc);

        @(negedge clk);     // C06: 분기 뒤 순차 갱신으로 돌아갑니다.
        pc_src = 1'b0;
        @(posedge clk);
        #1;
        if (pc !== 32'd28) begin
            $fatal(1, "FAIL C06 sequential: expected PC=28, actual=%h", pc);
        end
        $display("C06 OK PC=%0d", pc);

        @(negedge clk);     // C07: 32비트 2의 보수 -4를 더하여 24로 돌아갑니다.
        pc_src = 1'b1;
        imm_ext = 32'hFFFF_FFFC;
        @(posedge clk);
        #1;
        if (pc !== 32'd24) begin
            $fatal(1, "FAIL C07 negative offset: expected PC=24, actual=%h", pc);
        end
        $display("C07 OK PC=%0d", pc);

        @(negedge clk);     // C08: 오프셋 0을 선택하면 현재 주소를 다시 저장합니다.
        pc_src = 1'b1;
        imm_ext = 32'd0;
        @(posedge clk);
        #1;
        if (pc !== 32'd24) begin
            $fatal(1, "FAIL C08 zero offset: expected PC=24, actual=%h", pc);
        end
        $display("C08 OK PC=%0d", pc);

        @(negedge clk);     // C09: 70ns에 두 조합 입력만 바꿉니다.
        pc_src = 1'b0;
        imm_ext = 32'd100;
        #1;                // 71ns 검사: 다음 posedge 75ns보다 먼저 확인합니다.
        if (pc !== 32'd24) begin
            $fatal(1, "FAIL C09 hold between edges: expected PC=24, actual=%h", pc);
        end
        $display("C09 OK PC=%0d", pc);

        #1;
        reset = 1'b1;       // C10: 72ns에 실제 0→1, PC=24에서 비동기 초기화합니다.
        #1;                // 73ns 검사이므로 동기 reset 구현은 통과할 수 없습니다.
        if (pc !== 32'd0) begin
            $fatal(1, "FAIL C10 async reset again: expected PC=0, actual=%h", pc);
        end
        $display("C10 OK PC=%0d", pc);

        @(negedge clk);     // C11: reset 해제 뒤 다시 4부터 시작합니다.
        reset = 1'b0;
        pc_src = 1'b0;
        @(posedge clk);
        #1;
        if (pc !== 32'd4) begin
            $fatal(1, "FAIL C11 restart: expected PC=4, actual=%h", pc);
        end
        $display("C11 OK PC=%0d", pc);
        $display("W05 CHECKPOINT PASS (11/11)");
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
