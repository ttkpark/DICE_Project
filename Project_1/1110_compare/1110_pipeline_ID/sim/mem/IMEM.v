// Simulation-only instruction memory. The interface is fixed.
// One 32-bit word per line in the HEX file; PC is a byte address.
module IMEM (
    input  wire [31:0] ADDR,
    output wire [31:0] INSTR
);
    reg [31:0] RAM [0:511];
    reg [2047:0] program_file;
    integer k;
    integer LOADED_WORDS;

    initial begin
        if (!$value$plusargs("PROGRAM=%s", program_file))
            program_file = "baseline_int8_fc_slow.hex";
        for (k = 0; k < 512; k = k + 1)
            RAM[k] = 32'hxxxxxxxx;
        $readmemh(program_file, RAM);
        LOADED_WORDS = 0;
        for (k = 0; k < 512; k = k + 1)
            if (RAM[k] !== 32'hxxxxxxxx)
                LOADED_WORDS = k + 1;
        if (LOADED_WORDS < 1) begin
            $display("FAIL IMEM: no valid instruction word loaded");
            $finish;
        end
    end

    assign INSTR = (ADDR[31:11] == 21'd0 && ADDR[1:0] == 2'b00)
                 ? RAM[ADDR[10:2]] : 32'hxxxxxxxx;
endmodule
