//Module: ALU control
/* Function: ALU control is a combinational circuit that takes the 
ALU control signals from the Control unit as well as the function 
field of the instruction, and generates the control signals for the ALU */

module alu_control(
      input wire [6:0] func7, // expanding the func unit instead of func7_5
      input wire [2:0] func3,
      input wire [1:0] alu_op,
      output reg [3:0] alu_control
   );

   parameter [1:0] ADD_OPCODE    = 2'b00;
   parameter [1:0] SUB_OPCODE    = 2'b01;
   parameter [1:0] R_TYPE_OPCODE = 2'b10;

   parameter [3:0] AND_OP = 4'd0;
   parameter [3:0] OR_OP  = 4'd1;
   parameter [3:0] ADD_OP = 4'd2;
   parameter [3:0] SLL_OP = 4'd3;
   parameter [3:0] SRL_OP = 4'd4;
   parameter [3:0] SUB_OP = 4'd6;
   parameter [3:0] SLT_OP = 4'd7;
   parameter [3:0] MUL_OP = 4'd8;  // New op

   reg [3:0] rtype_op;

   always @(*) begin
      case ({func7, func3})
         10'b0000000_000: rtype_op = ADD_OP; // add
         10'b0100000_000: rtype_op = SUB_OP; // sub
         10'b0000000_111: rtype_op = AND_OP; // and
         10'b0000000_110: rtype_op = OR_OP;  // or
         10'b0000000_010: rtype_op = SLT_OP; // slt
         10'b0000000_001: rtype_op = SLL_OP; // sll
         10'b0000000_101: rtype_op = SRL_OP; // srl
         10'b0000001_000: rtype_op = MUL_OP; // mul
         default:         rtype_op = ADD_OP;
      endcase
   end

   always @(*) begin
      case (alu_op)
         ADD_OPCODE:    alu_control = ADD_OP;
         SUB_OPCODE:    alu_control = SUB_OP;
         R_TYPE_OPCODE: alu_control = rtype_op;
         default:       alu_control = ADD_OP;
      endcase
   end

endmodule

