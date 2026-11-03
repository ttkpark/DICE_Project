`timescale 1ns/1ps
module tb_03_pc;
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
        $dumpfile("build/03_pc.vcd");
        $dumpvars(0, tb_03_pc);
`ifdef DUMP_FSDB
        $fsdbDumpfile("build/03_pc.fsdb");
        $fsdbDumpvars(0, tb_03_pc);
`endif
    end

    initial begin
        reset = 1'b0;
        pc_src = 1'b0;
        imm_ext = 32'd0;
        #2;
        reset = 1'b1;
        #1;
        if (pc !== 32'd0) begin
            $fatal(1, "FAIL L01 async reset: expected PC=0, actual=%h", pc);
        end
        $display("PC=%0d", pc);

        @(negedge clk);
        reset = 1'b0;
        pc_src = 1'b0;
        @(posedge clk);
        #1;                // <= 갱신이 끝난 뒤 현재 PC를 관찰합니다.
        if (pc !== 32'd4) begin
            $fatal(1, "FAIL L02 sequential: expected PC=4, actual=%h", pc);
        end
        $display("PC=%0d", pc);

        @(negedge clk);
        pc_src = 1'b0;
        @(posedge clk);
        #1;
        if (pc !== 32'd8) begin
            $fatal(1, "FAIL L03 sequential: expected PC=8, actual=%h", pc);
        end
        $display("PC=%0d", pc);

        @(negedge clk);
        pc_src = 1'b1;
        imm_ext = 32'd16;   // EDIT A: offset=8 실습에서는 32'd8로 바꿉니다.
        #1;
        if (pc !== 32'd8) begin
            $fatal(1, "FAIL L04 hold before edge: expected PC=8, actual=%h", pc);
        end
        // PCNext는 입력 변경 직후 달라지지만 PC는 아직 8입니다.
        $display("Before branch edge: PC=%0d (inspect PCNext in waveform)", pc);
        @(posedge clk);
        #1;
        if (pc !== 32'd24) begin // EDIT B: offset=8이면 기대값과 아래 메시지를 16으로 수정합니다.
            $fatal(1, "FAIL L05 branch: expected PC=24, actual=%h", pc);
        end
        $display("PC=%0d", pc);

        @(negedge clk);
        pc_src = 1'b0;
        @(posedge clk);
        #1;
        if (pc !== 32'd28) begin // EDIT C: offset=8이면 기대값과 아래 메시지를 20으로 수정합니다.
            $fatal(1, "FAIL L06 sequential: expected PC=28, actual=%h", pc);
        end
        $display("PC=%0d", pc);
        $display("W05 PC LESSON PASS (6/6)");
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
