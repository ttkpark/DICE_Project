// Simulation-only 512-word data memory. The interface is fixed.
// Asynchronous read, edge-triggered write. Power is estimated by
// MEMORY_POWER.v from completed instruction and LW/SW counts.
module DMEM (
    input  wire        CLK,
    input  wire        MEMWRITE,
    input  wire [31:0] ADDR,
    input  wire [31:0] WRITEDATA,
    output wire [31:0] READDATA
);
    reg [31:0] RAM [0:511];
    reg [2047:0] data_file;
    integer k;

    initial begin
        if (!$value$plusargs("DATA=%s", data_file))
            data_file = "cases/demo_dmem.hex";
        for (k = 0; k < 512; k = k + 1)
            RAM[k] = 32'd0;
        $readmemh(data_file, RAM);
    end

    assign READDATA = (ADDR[31:11] == 21'd0 && ADDR[1:0] == 2'b00)
                    ? RAM[ADDR[10:2]] : 32'hxxxxxxxx;

    always @(posedge CLK) begin
        if (MEMWRITE) begin
            if (ADDR[31:11] != 21'd0 || ADDR[1:0] != 2'b00) begin
                $display("FAIL DMEM: invalid byte address %08x", ADDR);
                $finish;
            end else begin
                RAM[ADDR[10:2]] <= WRITEDATA;
            end
        end
    end
endmodule
