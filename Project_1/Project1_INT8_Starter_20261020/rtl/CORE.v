// W08 teaching core: RV32I subset from W07, no pipeline or exception handling.
module CORE (
    input  wire        CLK,
    input  wire        RESET,
    input  wire [31:0] INSTR,
    input  wire [31:0] READDATA,
    output reg  [31:0] PC,
    output wire        MEMWRITE,
    output reg  [31:0] ALURESULT,
    output wire [31:0] WRITEDATA
);
    wire        REGWRITE;
    wire        ALUSRC;
    wire [1:0]  RESULTSRC;
    wire [1:0]  IMMSRC;
    wire [2:0]  ALUCTRL;
    wire        PCSRC;
    wire        ILLEGAL;
    wire        ZERO;

    CONTROLLER u_controller (
        .INSTR      (INSTR),
        .ZERO       (ZERO),
        .REGWRITE   (REGWRITE),
        .MEMWRITE   (MEMWRITE),
        .ALUSRC     (ALUSRC),
        .RESULTSRC  (RESULTSRC),
        .IMMSRC     (IMMSRC),
        .ALUCTRL    (ALUCTRL),
        .PCSRC      (PCSRC),
        .ILLEGAL    (ILLEGAL)
    );

    reg [31:0] rf [0:31];
    integer i;
    wire [4:0] rs1 = INSTR[19:15];
    wire [4:0] rs2 = INSTR[24:20];
    wire [4:0] rd  = INSTR[11:7];
    wire [31:0] srca = (rs1 == 5'd0) ? 32'd0 : rf[rs1];
    wire [31:0] src2 = (rs2 == 5'd0) ? 32'd0 : rf[rs2];
    reg  [31:0] immext;
    wire [31:0] srcb = ALUSRC ? immext : src2;
    wire [31:0] pcplus4 = PC + 32'd4;
    wire [31:0] pctarget = PC + immext;
    wire [31:0] pcnext = PCSRC ? pctarget : pcplus4;
    reg  [31:0] result;
    assign WRITEDATA = src2;
    assign ZERO = (ALURESULT == 32'd0);

    always @* begin
        case (IMMSRC)
            2'b00: immext = {{20{INSTR[31]}}, INSTR[31:20]};
            2'b01: immext = {{20{INSTR[31]}}, INSTR[31:25], INSTR[11:7]};
            2'b10: immext = {{19{INSTR[31]}}, INSTR[31], INSTR[7],
                             INSTR[30:25], INSTR[11:8], 1'b0};
            2'b11: immext = {{11{INSTR[31]}}, INSTR[31], INSTR[19:12],
                             INSTR[20], INSTR[30:21], 1'b0};
            default: immext = 32'd0;
        endcase
    end

    always @* begin
        case (ALUCTRL)
            3'b000: ALURESULT = srca + srcb;
            3'b001: ALURESULT = srca - srcb;
            3'b010: ALURESULT = srca & srcb;
            default: ALURESULT = 32'd0;
        endcase
    end

    always @* begin
        case (RESULTSRC)
            2'b00: result = ALURESULT;
            2'b01: result = READDATA;
            2'b10: result = pcplus4;
            default: result = 32'd0;
        endcase
    end

    always @(posedge CLK) begin
        if (RESET) begin
            PC <= 32'd0;
            for (i = 0; i < 32; i = i + 1)
                rf[i] <= 32'd0;
        end else begin
            PC <= pcnext;
            if (REGWRITE && !ILLEGAL && (rd != 5'd0))
                rf[rd] <= result;
        end
    end
endmodule
