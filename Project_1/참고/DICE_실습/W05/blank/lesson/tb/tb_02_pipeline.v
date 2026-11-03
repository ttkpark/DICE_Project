`timescale 1ns/1ps
module tb_02_pipeline;
    reg clk;
    reg reset;
    reg data;
    wire good_q1;
    wire good_q2;
    wire bad_q1;
    wire bad_q2;

    /* pipeline_good AUTO_TEMPLATE (
        .q1(good_q1),
        .q2(good_q2),
    ); */
    pipeline_good u_good (/*AUTOINST*/
			  // Outputs
			  .q1			(good_q1),	 // Templated
			  .q2			(good_q2),	 // Templated
			  // Inputs
			  .clk			(clk),
			  .reset		(reset),
			  .data			(data));

    /* pipeline_bad AUTO_TEMPLATE (
        .q1(bad_q1),
        .q2(bad_q2),
    ); */
    pipeline_bad u_bad (/*AUTOINST*/
			// Outputs
			.q1		(bad_q1),		 // Templated
			.q2		(bad_q2),		 // Templated
			// Inputs
			.clk		(clk),
			.reset		(reset),
			.data		(data));

    initial clk = 1'b0;
    always #5 clk = ~clk;

    initial begin
        $dumpfile("build/02_pipeline.vcd");
        $dumpvars(0, tb_02_pipeline);
`ifdef DUMP_FSDB
        $fsdbDumpfile("build/02_pipeline.fsdb");
        $fsdbDumpvars(0, tb_02_pipeline);
`endif
    end

    initial begin
        reset = 1'b0;
        data = 1'b0;
        #2;
        reset = 1'b1;       // 두 모듈에 동일한 비동기 reset을 줍니다.
        #1;
        if ({good_q1, good_q2, bad_q1, bad_q2} !== 4'b0000) begin
            $fatal(1, "FAIL P01 async reset: good=%b%b bad=%b%b", good_q1, good_q2, bad_q1, bad_q2);
        end

        @(negedge clk);
        reset = 1'b0;
        data = 1'b1;
        @(posedge clk);
        #1;                // <= 갱신 이후 읽어 두 모듈을 동일한 관찰 시점에 비교합니다.
        if ({good_q1, good_q2} !== 2'b10) begin
            $fatal(1, "FAIL P02 first edge: expected good=10, actual=%b%b", good_q1, good_q2);
        end
        if ({bad_q1, bad_q2} !== 2'b11) begin
            $fatal(1, "FAIL P03 first edge: expected bad=11, actual=%b%b", bad_q1, bad_q2);
        end
        $display("First edge: good=(1,0), bad=(1,1)");

        @(posedge clk);
        #1;
        if ({good_q1, good_q2, bad_q1, bad_q2} !== 4'b1111) begin
            $fatal(1, "FAIL P04 second edge: good=%b%b bad=%b%b", good_q1, good_q2, bad_q1, bad_q2);
        end
        $display("Second edge: good=(1,1), bad=(1,1)");

        @(negedge clk);
        data = 1'b0;
        @(posedge clk);
        #1;
        if ({good_q1, good_q2, bad_q1, bad_q2} !== 4'b0100) begin
            $fatal(1, "FAIL P05 capture 0: good=%b%b bad=%b%b", good_q1, good_q2, bad_q1, bad_q2);
        end
        @(posedge clk);
        #1;
        if ({good_q1, good_q2, bad_q1, bad_q2} !== 4'b0000) begin
            $fatal(1, "FAIL P06 second zero: good=%b%b bad=%b%b", good_q1, good_q2, bad_q1, bad_q2);
        end
        $display("W05 PIPELINE PASS (6/6)");
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
