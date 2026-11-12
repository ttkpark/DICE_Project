`timescale 1ns/1ps
// Course PPA estimator, not a synthesized power meter.
// IMEM: one fetch per executed cycle. DMEM: one access for every legal load/store.
// The official scoring testbench will use its own unmodified copy.
module MEMORY_POWER (
    input wire        CLK,
    input wire        RESET,
    input wire [31:0] INSTR,
    input wire        MEMWRITE,
    input wire [31:0] ALURESULT,
    input wire [31:0] WRITEDATA,
    input wire [31:0] DONE_ADDR,
    input wire [31:0] DONE_TOKEN,
    input wire [31:0] IMEM_WORDS
);
    integer cycles;
    integer loads;
    integer stores;
    integer reported;
    real f_mhz;
    real a_imem_um2;
    real e_imem_pj;
    real p_mem_dynamic_mw;
    real p_mem_static_mw;
    real p_mem_mw;
    real t_us;

    initial begin
        f_mhz = 100.0;
        if (!$value$plusargs("F_MHZ=%f", f_mhz))
            $display("MEMORY_POWER: demo default F_MHZ=100; pass +F_MHZ for your declared clock");
        if (f_mhz <= 0.0) begin
            $display("FAIL MEMORY_POWER: F_MHZ must be positive");
            $finish;
        end
        cycles = 0;
        loads = 0;
        stores = 0;
        reported = 0;
    end

    always @(posedge CLK) begin
        if (RESET) begin
            cycles = 0;
            loads = 0;
            stores = 0;
            reported = 0;
        end else if (!reported) begin
            cycles = cycles + 1;
            if (INSTR[6:0] == 7'b0000011)
                loads = loads + 1;
            if (INSTR[6:0] == 7'b0100011)
                stores = stores + 1;

            if (MEMWRITE && ALURESULT == DONE_ADDR &&
                WRITEDATA == DONE_TOKEN) begin
                if (IMEM_WORDS < 1 || IMEM_WORDS > 512) begin
                    $display("FAIL MEMORY_POWER: IMEM_WORDS=%0d", IMEM_WORDS);
                    $finish;
                end
                if (IMEM_WORDS <= 64) begin
                    a_imem_um2 = 8713.50;
                    e_imem_pj = 2.23;
                end else if (IMEM_WORDS <= 256) begin
                    a_imem_um2 = 27352.30;
                    e_imem_pj = 7.00;
                end else begin
                    a_imem_um2 = 50667.68;
                    e_imem_pj = 12.97;
                end

                p_mem_dynamic_mw = (f_mhz / 1000.0) *
                                   (e_imem_pj + 12.97 * (loads + stores) / cycles);
                // Fixed course scoring proxy anchored to SAED32 SRAM macro area.
                // 0.020 mW / 1000 um^2 is NOT measured EDK leakage power.
                p_mem_static_mw = 0.020 * (a_imem_um2 + 50667.68) / 1000.0;
                p_mem_mw = p_mem_dynamic_mw + p_mem_static_mw;
                t_us = cycles / f_mhz;
                $display("MEMORY_PPA cycles=%0d LOAD=%0d STORE=%0d IMEM_words=%0d F_MHz=%0.3f",
                         cycles, loads, stores, IMEM_WORDS, f_mhz);
                $display("MEMORY_PPA IMEM_area_um2=%0.2f DMEM_area_um2=50667.68",
                         a_imem_um2);
                $display("MEMORY_PPA P_mem_dynamic_mW=%0.6f P_mem_static_proxy_mW=%0.6f",
                         p_mem_dynamic_mw, p_mem_static_mw);
                $display("MEMORY_PPA P_mem_total_mW=%0.6f T_us=%0.6f",
                         p_mem_mw, t_us);
                reported = 1;
            end
        end
    end
endmodule
