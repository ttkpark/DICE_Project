// Project 1 TOP port contract. Verilog-2001 only.
// Do not rename, resize, reorder, add, or remove ports.
// Student work: complete only the four TODO connections below.
module TOP (
    input  wire        CLK,
    input  wire        RESET,
    input  wire [31:0] RESERVED_IN0,
    input  wire [31:0] RESERVED_IN1,
    input  wire [31:0] RESERVED_IN2,
    input  wire [31:0] RESERVED_IN3,
    input  wire [31:0] RESERVED_IN4,
    input  wire [31:0] RESERVED_IN5,
    input  wire [31:0] RESERVED_IN6,
    input  wire [31:0] RESERVED_IN7,
    input  wire [31:0] RESERVED_IN8,
    input  wire [31:0] RESERVED_IN9,
    input  wire [31:0] RESERVED_IN10,
    input  wire [31:0] RESERVED_IN11,
    input  wire [31:0] RESERVED_IN12,
    input  wire [31:0] RESERVED_IN13,
    input  wire [31:0] RESERVED_IN14,
    input  wire [31:0] RESERVED_IN15,
    input  wire [31:0] RESERVED_IN16,
    input  wire [31:0] RESERVED_IN17,
    input  wire [31:0] RESERVED_IN18,
    input  wire [31:0] RESERVED_IN19,
    output wire [31:0] PC,
    output wire [31:0] INSTR,
    output wire        MEMWRITE,
    output wire [31:0] ALURESULT,
    output wire [31:0] WRITEDATA,
    output wire [31:0] RESERVED_OUT0,
    output wire [31:0] RESERVED_OUT1,
    output wire [31:0] RESERVED_OUT2,
    output wire [31:0] RESERVED_OUT3,
    output wire [31:0] RESERVED_OUT4,
    output wire [31:0] RESERVED_OUT5,
    output wire [31:0] RESERVED_OUT6,
    output wire [31:0] RESERVED_OUT7,
    output wire [31:0] RESERVED_OUT8,
    output wire [31:0] RESERVED_OUT9,
    output wire [31:0] RESERVED_OUT10,
    output wire [31:0] RESERVED_OUT11,
    output wire [31:0] RESERVED_OUT12,
    output wire [31:0] RESERVED_OUT13,
    output wire [31:0] RESERVED_OUT14,
    output wire [31:0] RESERVED_OUT15,
    output wire [31:0] RESERVED_OUT16,
    output wire [31:0] RESERVED_OUT17,
    output wire [31:0] RESERVED_OUT18,
    output wire [31:0] RESERVED_OUT19
);
    wire [31:0] readdata;

    // The official testbench drives every RESERVED_IN pin with 32'b0.
    // It leaves every RESERVED_OUT pin unconnected. Never rely on a
    // nonzero reserved input to make the required program work.
    assign RESERVED_OUT0  = 32'b0;
    assign RESERVED_OUT1  = 32'b0;
    assign RESERVED_OUT2  = 32'b0;
    assign RESERVED_OUT3  = 32'b0;
    assign RESERVED_OUT4  = 32'b0;
    assign RESERVED_OUT5  = 32'b0;
    assign RESERVED_OUT6  = 32'b0;
    assign RESERVED_OUT7  = 32'b0;
    assign RESERVED_OUT8  = 32'b0;
    assign RESERVED_OUT9  = 32'b0;
    assign RESERVED_OUT10 = 32'b0;
    assign RESERVED_OUT11 = 32'b0;
    assign RESERVED_OUT12 = 32'b0;
    assign RESERVED_OUT13 = 32'b0;
    assign RESERVED_OUT14 = 32'b0;
    assign RESERVED_OUT15 = 32'b0;
    assign RESERVED_OUT16 = 32'b0;
    assign RESERVED_OUT17 = 32'b0;
    assign RESERVED_OUT18 = 32'b0;
    assign RESERVED_OUT19 = 32'b0;

    CORE u_core (
        .CLK        (CLK),
        .RESET      (RESET),
        .INSTR      (INSTR),
        .READDATA   (readdata),
        .PC         (PC),
        .MEMWRITE   (MEMWRITE),
        .ALURESULT  (ALURESULT),
        .WRITEDATA  (WRITEDATA)
    );

    IMEM u_imem (
        .ADDR       (PC),
        .INSTR      (INSTR)
    );

    DMEM u_dmem (
        .CLK        (CLK),
        .MEMWRITE   (MEMWRITE),
        .ADDR       (ALURESULT),
        .WRITEDATA  (WRITEDATA),
        .READDATA   (readdata)
    );
endmodule
