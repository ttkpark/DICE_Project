// RV32I subset: ADD, SUB, AND, ADDI, LW, SW, BEQ, JAL.
// Five stages: IF / ID / EX / MEM / WB. Branches and JAL resolve in ID.
// Fetch continues at PC+4 until ID redirects; no direction predictor is used.
// ID comparison forwards EX > MEM > WB > register file (x0 is always zero).
// A load in EX stalls its next user. BEQ also waits for a matching load in MEM.
// A stall holds PC and IF/ID, and inserts an ID/EX bubble.
// A taken BEQ or JAL discards only the fetched instruction, not the ID instruction.
// RESET is synchronous active-high. IMEM/DMEM remain outside the CPU.
module CORE (
    input  wire        CLK,
    input  wire        RESET,
    input  wire [31:0] INSTR,
    input  wire [31:0] READDATA,
    output reg  [31:0] PC,
    output wire        MEMWRITE,
    output wire [31:0] ALURESULT,
    output wire [31:0] WRITEDATA
);
    localparam [1:0] RESULT_ALU = 2'b00,
                     RESULT_LOAD = 2'b01,
                     RESULT_LINK = 2'b10;
    localparam [6:0] OP_REGISTER = 7'b0110011,
                     OP_IMMEDIATE = 7'b0010011,
                     OP_LOAD = 7'b0000011,
                     OP_STORE = 7'b0100011,
                     OP_BRANCH = 7'b1100011,
                     OP_JAL = 7'b1101111;

    // IF/ID: the instruction whose operands and branch decision are decoded.
    reg [31:0] instruction_id;
    reg [31:0] instruction_pc_id;
    reg [31:0] sequential_pc_id;

    // ID/EX: operands, destination, and controls for the ALU stage.
    reg [31:0] operand1_ex;
    reg [31:0] operand2_ex;
    reg [31:0] immediate_ex;
    reg [31:0] link_address_ex;
    reg [4:0]  source1_ex;
    reg [4:0]  source2_ex;
    reg [4:0]  destination_ex;
    reg        write_register_ex;
    reg        write_memory_ex;
    reg        use_immediate_ex;
    reg [1:0]  result_select_ex;
    reg [2:0]  alu_operation_ex;

    // EX/MEM: these registers drive the external data-memory interface.
    reg [31:0] alu_result_mem;
    reg [31:0] store_data_mem;
    reg [31:0] link_address_mem;
    reg [4:0]  destination_mem;
    reg        write_register_mem;
    reg        write_memory_mem;
    reg [1:0]  result_select_mem;

    // MEM/WB: asynchronous memory data is captured before register writeback.
    reg [31:0] alu_result_wb;
    reg [31:0] load_data_wb;
    reg [31:0] link_address_wb;
    reg [4:0]  destination_wb;
    reg        write_register_wb;
    reg [1:0]  result_select_wb;
    reg [31:0] writeback_value;

    reg [31:0] reg_file [0:31];
    integer register_index;

    wire       decode_write_register;
    wire       decode_write_memory;
    wire       decode_use_immediate;
    wire [1:0] decode_result_select;
    wire [1:0] decode_immediate_format;
    wire [2:0] decode_alu_operation;
    wire       decode_pc_select;
    wire       decode_illegal;

    wire [6:0] opcode_id = instruction_id[6:0];
    wire [4:0] source1_id = instruction_id[19:15];
    wire [4:0] source2_id = instruction_id[24:20];
    wire [4:0] destination_id = instruction_id[11:7];
    wire branch_id = !decode_illegal && (opcode_id == OP_BRANCH);
    wire jump_id = !decode_illegal && (opcode_id == OP_JAL);

    // Immediate bits in rs2's position are not a register dependency.
    wire uses_source1_id = !decode_illegal &&
                          ((opcode_id == OP_REGISTER) ||
                           (opcode_id == OP_IMMEDIATE) ||
                           (opcode_id == OP_LOAD) ||
                           (opcode_id == OP_STORE) ||
                           (opcode_id == OP_BRANCH));
    wire uses_source2_id = !decode_illegal &&
                          ((opcode_id == OP_REGISTER) ||
                           (opcode_id == OP_STORE) ||
                           (opcode_id == OP_BRANCH));

    // WB bypass gives a same-cycle register read the value being written.
    wire [31:0] register_value1_id =
        (source1_id == 5'd0) ? 32'd0 :
        (write_register_wb && destination_wb == source1_id) ?
        writeback_value : reg_file[source1_id];
    wire [31:0] register_value2_id =
        (source2_id == 5'd0) ? 32'd0 :
        (write_register_wb && destination_wb == source2_id) ?
        writeback_value : reg_file[source2_id];

    reg [31:0] immediate_id;
    always @* begin
        case (decode_immediate_format)
            2'b00: immediate_id = {{20{instruction_id[31]}}, instruction_id[31:20]};
            2'b01: immediate_id = {{20{instruction_id[31]}}, instruction_id[31:25],
                                   instruction_id[11:7]};
            2'b10: immediate_id = {{19{instruction_id[31]}}, instruction_id[31],
                                   instruction_id[7], instruction_id[30:25],
                                   instruction_id[11:8], 1'b0};
            2'b11: immediate_id = {{11{instruction_id[31]}}, instruction_id[31],
                                   instruction_id[19:12], instruction_id[20],
                                   instruction_id[30:21], 1'b0};
            default: immediate_id = 32'd0;
        endcase
    end

    wire load_ex = write_register_ex && (result_select_ex == RESULT_LOAD);
    wire load_mem = write_register_mem && (result_select_mem == RESULT_LOAD);

    // All four comparisons use the CURRENT ID instruction's source indices.
    wire source1_from_ex_id = (source1_id != 5'd0) &&
                             write_register_ex && (destination_ex == source1_id);
    wire source2_from_ex_id = (source2_id != 5'd0) &&
                             write_register_ex && (destination_ex == source2_id);
    wire source1_from_mem_id = (source1_id != 5'd0) &&
                              write_register_mem && (destination_mem == source1_id);
    wire source2_from_mem_id = (source2_id != 5'd0) &&
                              write_register_mem && (destination_mem == source2_id);

    wire wait_for_load_ex = load_ex &&
                           ((uses_source1_id && source1_from_ex_id) ||
                            (uses_source2_id && source2_from_ex_id));

    // ID does not forward READDATA directly. A BEQ must wait until LW reaches WB.
    // A newer EX writer to the SAME operand supersedes an older MEM load.
    wire wait_for_branch_load_mem = branch_id && load_mem &&
        ((source1_from_mem_id && !source1_from_ex_id) ||
         (source2_from_mem_id && !source2_from_ex_id));
    wire stall_decode = wait_for_load_ex || wait_for_branch_load_mem;

    reg [31:0] alu_result_ex;
    wire [31:0] forward_value_ex =
        (result_select_ex == RESULT_LINK) ? link_address_ex : alu_result_ex;
    wire [31:0] forward_value_mem =
        (result_select_mem == RESULT_LINK) ? link_address_mem : alu_result_mem;

    // ID has its own equality comparator, independent of the EX ALU.
    // Load values are unavailable here; stall_decode blocks decisions until ready.
    reg [31:0] compare_value1_id;
    reg [31:0] compare_value2_id;
    always @* begin
        compare_value1_id = register_value1_id;
        compare_value2_id = register_value2_id;
        if (source1_from_ex_id && !load_ex)
            compare_value1_id = forward_value_ex;
        else if (source1_from_mem_id && !load_mem)
            compare_value1_id = forward_value_mem;
        if (source2_from_ex_id && !load_ex)
            compare_value2_id = forward_value_ex;
        else if (source2_from_mem_id && !load_mem)
            compare_value2_id = forward_value_mem;
    end
    wire operands_equal_id = (compare_value1_id == compare_value2_id);

    CONTROLLER u_controller (
        .INSTR      (instruction_id),
        .ZERO       (operands_equal_id),
        .REGWRITE   (decode_write_register),
        .MEMWRITE   (decode_write_memory),
        .ALUSRC     (decode_use_immediate),
        .RESULTSRC  (decode_result_select),
        .IMMSRC     (decode_immediate_format),
        .ALUCTRL    (decode_alu_operation),
        .PCSRC      (decode_pc_select),
        .ILLEGAL    (decode_illegal)
    );

    // Never redirect OR flush a BEQ while it is waiting for a load result.
    wire redirect_id = !stall_decode && (branch_id || jump_id) && decode_pc_select;
    wire [31:0] branch_target_id = instruction_pc_id + immediate_id;
    wire [31:0] sequential_pc_if = PC + 32'd4;

    always @(posedge CLK) begin
        if (RESET)
            PC <= 32'd0;
        else if (!stall_decode)
            PC <= redirect_id ? branch_target_id : sequential_pc_if;
    end

    always @(posedge CLK) begin
        if (RESET || redirect_id) begin
            instruction_id <= 32'd0;
            instruction_pc_id <= 32'd0;
            sequential_pc_id <= 32'd0;
        end else if (!stall_decode) begin
            instruction_id <= INSTR;
            instruction_pc_id <= PC;
            sequential_pc_id <= sequential_pc_if;
        end
    end

    always @(posedge CLK) begin
        if (RESET || stall_decode) begin
            operand1_ex <= 32'd0;
            operand2_ex <= 32'd0;
            immediate_ex <= 32'd0;
            link_address_ex <= 32'd0;
            source1_ex <= 5'd0;
            source2_ex <= 5'd0;
            destination_ex <= 5'd0;
            write_register_ex <= 1'b0;
            write_memory_ex <= 1'b0;
            use_immediate_ex <= 1'b0;
            result_select_ex <= RESULT_ALU;
            alu_operation_ex <= 3'b000;
        end else begin
            operand1_ex <= register_value1_id;
            operand2_ex <= register_value2_id;
            immediate_ex <= immediate_id;
            link_address_ex <= sequential_pc_id;
            source1_ex <= source1_id;
            source2_ex <= source2_id;
            destination_ex <= destination_id;
            write_register_ex <= decode_write_register && !decode_illegal;
            write_memory_ex <= decode_write_memory && !decode_illegal;
            use_immediate_ex <= decode_use_immediate;
            result_select_ex <= decode_result_select;
            alu_operation_ex <= decode_alu_operation;
        end
    end

    // EX forwarding also covers the value stored by SW.
    reg [31:0] alu_operand1_ex;
    reg [31:0] store_value_ex;
    always @* begin
        alu_operand1_ex = operand1_ex;
        store_value_ex = operand2_ex;
        if (source1_ex != 5'd0) begin
            if (write_register_mem && !load_mem && destination_mem == source1_ex)
                alu_operand1_ex = forward_value_mem;
            else if (write_register_wb && destination_wb == source1_ex)
                alu_operand1_ex = writeback_value;
        end
        if (source2_ex != 5'd0) begin
            if (write_register_mem && !load_mem && destination_mem == source2_ex)
                store_value_ex = forward_value_mem;
            else if (write_register_wb && destination_wb == source2_ex)
                store_value_ex = writeback_value;
        end
    end
    wire [31:0] alu_operand2_ex = use_immediate_ex ? immediate_ex : store_value_ex;
    always @* begin
        case (alu_operation_ex)
            3'b000: alu_result_ex = alu_operand1_ex + alu_operand2_ex;
            3'b001: alu_result_ex = alu_operand1_ex - alu_operand2_ex;
            3'b010: alu_result_ex = alu_operand1_ex & alu_operand2_ex;
            default: alu_result_ex = 32'd0;
        endcase
    end

    always @(posedge CLK) begin
        if (RESET) begin
            alu_result_mem <= 32'd0;
            store_data_mem <= 32'd0;
            link_address_mem <= 32'd0;
            destination_mem <= 5'd0;
            write_register_mem <= 1'b0;
            write_memory_mem <= 1'b0;
            result_select_mem <= RESULT_ALU;
        end else begin
            alu_result_mem <= alu_result_ex;
            store_data_mem <= store_value_ex;
            link_address_mem <= link_address_ex;
            destination_mem <= destination_ex;
            write_register_mem <= write_register_ex;
            write_memory_mem <= write_memory_ex;
            result_select_mem <= result_select_ex;
        end
    end
    assign ALURESULT = alu_result_mem;
    assign WRITEDATA = store_data_mem;
    assign MEMWRITE = write_memory_mem;

    always @(posedge CLK) begin
        if (RESET) begin
            alu_result_wb <= 32'd0;
            load_data_wb <= 32'd0;
            link_address_wb <= 32'd0;
            destination_wb <= 5'd0;
            write_register_wb <= 1'b0;
            result_select_wb <= RESULT_ALU;
        end else begin
            alu_result_wb <= alu_result_mem;
            load_data_wb <= READDATA;
            link_address_wb <= link_address_mem;
            destination_wb <= destination_mem;
            write_register_wb <= write_register_mem;
            result_select_wb <= result_select_mem;
        end
    end
    always @* begin
        case (result_select_wb)
            RESULT_ALU: writeback_value = alu_result_wb;
            RESULT_LOAD: writeback_value = load_data_wb;
            RESULT_LINK: writeback_value = link_address_wb;
            default: writeback_value = 32'd0;
        endcase
    end
    always @(posedge CLK) begin
        if (RESET) begin
            for (register_index = 0; register_index < 32; register_index = register_index + 1)
                reg_file[register_index] <= 32'd0;
        end else if (write_register_wb && destination_wb != 5'd0) begin
            reg_file[destination_wb] <= writeback_value;
        end
    end
endmodule
