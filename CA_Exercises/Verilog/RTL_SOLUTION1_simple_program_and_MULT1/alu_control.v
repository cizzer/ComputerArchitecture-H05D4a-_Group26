/* Module: ALU control

Function: ALU control is a combinational circuit that takes the ALU control signals 
from the Control unit as well as the function field of the instruction, 
and generates the control signals for the ALU 

/* 
TLDR; What it does is:
1.) Take instruction info 
2.) Figure out which ALU operation is needed
3.) Output a 4-bit control singal to the ALU

Essentially -> Either it do an add,sub, etc.
*/

module alu_control( // Define the module name (alu_control)
      input wire       func7_5, // input is a wire that takes 1 bit (From instruction bit)
      input wire [2:0] func3, // input is a wire that takes 3 bit (From instruction bit)
		input wire [1:0] alu_op, // input is a wire that takes 2 bit (From main control)
		output reg [3:0] alu_control // results into the reg with 4 bit
   );

   // Takess alu_op func7_5 and func3 into alu_controler -> Basically a decoder

   
   //The ALUOP codes can be found
   //in chapter 4.4 of the book.
   
   parameter [1:0] ADD_OPCODE    = 2'b00; // Basically defines the opcode as 2 (Size = 2) ' (seperator) b (Base = binary) 00 (The actual data)
   parameter [1:0] SUB_OPCODE    = 2'b01; // 01
   parameter [1:0] R_TYPE_OPCODE = 2'b10; // 10

   //The ALU control codes can be found
   //in chapter 4.4 of the book. The book is hella goated

   parameter [3:0] AND_OP        = 4'd0; // Same thing the opcode is defined by the book, literally copy pasted from page 252
   parameter [3:0] OR_OP         = 4'd1; // 0001
   parameter [3:0] ADD_OP        = 4'd2; // 0010
   parameter [3:0] SLL_OP        = 4'd3; // 0011
   parameter [3:0] SRL_OP        = 4'd4; // 0100
   parameter [3:0] SUB_OP        = 4'd6; // 0110
   parameter [3:0] SLT_OP        = 4'd7; // 0111

   // idk why it is in decimal? should have been in binary -> doesnt matter, easier when handling new op, got it
   
   //The decoding of the instruction funtion field into the desired
   //alu operation can be found in Figure 4.12 of the Patterson Book,
   //section 4.4

   wire [3:0] function_field = {func7_5, func3}; // takes both of the 1 bit and the 3 bit then mash them into a 4 bit to get the desired func
   parameter [3:0] FUNC_ADD      = 4'b0000;
   parameter [3:0] FUNC_SUB      = 4'b1000;
   parameter [3:0] FUNC_AND      = 4'b0111;
   parameter [3:0] FUNC_OR       = 4'b0110;
   parameter [3:0] FUNC_SLT      = 4'b0010;
   parameter [3:0] FUNC_SLL      = 4'b0001;
   parameter [3:0] FUNC_SRL      = 4'b0101;

	reg [3:0] rtype_op; // internal register, stores ALU operation selected for R-type instructions
   
   // decodes the exact R-type operation into Rtype_op
   

   always @(*) begin // recompute whenever any input is used in this block changes => Combinational logic
		case(function_field) // Looks at the 4 bit funciton field and decide what R-type operation it represents
		   FUNC_ADD	:  rtype_op = ADD_OP;
		   FUNC_SUB	:  rtype_op = SUB_OP;
		   FUNC_AND	:  rtype_op = AND_OP;
		   FUNC_OR 	:  rtype_op = OR_OP; 
		   FUNC_SLT	:  rtype_op = SLT_OP;
		   FUNC_SLL	:  rtype_op = SLL_OP;
		   FUNC_SRL	:  rtype_op = SRL_OP;
			default:    rtype_op = 4'd0; // Note that 4'd0 is also AND_OP --> IF unknown fallback to 0
		endcase
	end

	always @(*) begin
		case(alu_op) // Basically decodes and tells from the Rcode what to output
			ADD_OPCODE    : alu_control = ADD_OP;	/* add */
			SUB_OPCODE    : alu_control = SUB_OP;	/* sub */
			R_TYPE_OPCODE : alu_control = rtype_op;
			default       : alu_control = 'b0;
		endcase
	end

endmodule

