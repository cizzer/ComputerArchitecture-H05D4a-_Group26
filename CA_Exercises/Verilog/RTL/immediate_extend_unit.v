module immediate_extend_unit(
    input  wire [31:0] instruction,
    output reg  [63:0] immediate_extended
);

    wire [6:0] opcode;
    assign opcode = instruction[6:0];

    // RISC-V opcode[6:0]
    parameter integer ALU_R      = 7'b0110011;
    parameter integer ALU_I      = 7'b0010011;
    parameter integer BRANCH_EQ  = 7'b1100011;
    parameter integer JUMP       = 7'b1101111;
    parameter integer LOAD_WORD  = 7'b0000011;
    parameter integer STORE_WORD = 7'b0100011;

    always @(*) begin
        case (opcode)
            ALU_I: begin   // I-type, e.g. addi
                immediate_extended = {{52{instruction[31]}}, instruction[31:20]};
            end

            LOAD_WORD: begin   // I-type load
                immediate_extended = {{52{instruction[31]}}, instruction[31:20]};
            end

            STORE_WORD: begin  // S-type
                immediate_extended = {{52{instruction[31]}}, instruction[31:25], instruction[11:7]};
            end

            BRANCH_EQ: begin   // B-type
                immediate_extended = {{51{instruction[31]}}, instruction[31], instruction[7],
                                      instruction[30:25], instruction[11:8], 1'b0};
            end

            JUMP: begin        // J-type (jal)
                immediate_extended = {{43{instruction[31]}}, instruction[31], instruction[19:12],
                                      instruction[20], instruction[30:21], 1'b0};
            end

            default: begin
                immediate_extended = 64'b0;
            end
        endcase
    end

endmodule