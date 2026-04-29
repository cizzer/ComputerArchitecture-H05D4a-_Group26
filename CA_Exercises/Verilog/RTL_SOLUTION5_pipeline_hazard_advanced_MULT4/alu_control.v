//Module: ALU control
//Function: ALU control is a combinational circuit that takes the ALU control signals from the Control unit as well as the function field of the instruction, and generates the control signals for the ALU

module alu_control(
      input wire [6:0] func7, // expanding the func unit instead of func7_5 (7 bit)
      // note that 7 bit here is because the RISCV ISA needs it to be 7
      input wire [2:0] func3, // input is a wire that takes 3 bit (From instruction bit)
      input wire [1:0] alu_op, // input is a wire that takes 2 bit (From main control)
      output reg [3:0] alu_control
   );

   parameter [1:0] ADD_OPCODE    = 2'b00;
   parameter [1:0] SUB_OPCODE    = 2'b01;
   parameter [1:0] R_TYPE_OPCODE = 2'b10;

   parameter [3:0] AND_OP = 4'd0; // Same thing the opcode is defined by the book, literally copy pasted from page 252
   parameter [3:0] OR_OP  = 4'd1;
   parameter [3:0] ADD_OP = 4'd2;
   parameter [3:0] SLL_OP = 4'd3;
   parameter [3:0] SRL_OP = 4'd4;
   parameter [3:0] SUB_OP = 4'd6;
   parameter [3:0] SLT_OP = 4'd7;
   parameter [3:0] MUL_OP = 4'd8;  // New op

   // note that the ALU OP is still 4 bit because it is not decoding, its a control singal

   // Look at RISCV-ISA cheat sheet
   wire [9:0] function_field = {func7, func3}; // now we take func 7 + 3 = 10 underscore to make it easier to read
   parameter [9:0] FUNC_ADD      = 10'b0000000_000; // ADD
   parameter [9:0] FUNC_SUB      = 10'b0100000_000; // SUB
   parameter [9:0] FUNC_AND      = 10'b0000000_111; // AND
   parameter [9:0] FUNC_OR       = 10'b0000000_110; // OR
   parameter [9:0] FUNC_SLT      = 10'b0000000_010; // OR
   parameter [9:0] FUNC_SLL      = 10'b0000000_010; // SLL
   parameter [9:0] FUNC_SRL      = 10'b0000000_101; // SRL
   parameter [9:0] FUNC_MULT     = 10'b0000001_000; // MULT


   reg [3:0] rtype_op; // internal register, stores ALU operation selected for R-type instructions

   always @(*) begin
      case ({function_field})
		   FUNC_ADD	:  rtype_op = ADD_OP;
		   FUNC_SUB	:  rtype_op = SUB_OP;
		   FUNC_AND	:  rtype_op = AND_OP;
		   FUNC_OR 	:  rtype_op = OR_OP; 
		   FUNC_SLT	:  rtype_op = SLT_OP;
		   FUNC_SLL	:  rtype_op = SLL_OP;
		   FUNC_SRL	:  rtype_op = SRL_OP;
         FUNC_MULT:  rtype_op = MUL_OP; // mul
         default:    rtype_op = ADD_OP;
      endcase
   end

   always @(*) begin
      case (alu_op) // Basically decodes and tells from the Rcode what to output
         ADD_OPCODE:    alu_control = ADD_OP;
         SUB_OPCODE:    alu_control = SUB_OP;
         R_TYPE_OPCODE: alu_control = rtype_op;
         default:       alu_control = ADD_OP;
      endcase
   end

endmodule

