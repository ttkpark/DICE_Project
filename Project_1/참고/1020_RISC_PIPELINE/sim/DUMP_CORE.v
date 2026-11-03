`timescale 1ns/1ps
// Power-activity helper: dumps the CORE hierarchy to build/core.vcd.
// Compiled only with DUMP=1 in run.sh (extra top-level module). tb_top_demo.v is not modified.
module DUMP_CORE;
    initial begin
        $dumpfile("build/core.vcd");
        $dumpvars(0, TB_TOP_DEMO.dut.u_core);
    end
endmodule
