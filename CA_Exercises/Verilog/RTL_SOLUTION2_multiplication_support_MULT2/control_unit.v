// module: Control
// Function: Generates the control signals for each one of the datapath resources

// Big daddy that decodes everthing for us 

module control_unit(
      input  wire [6:0] opcode, // main input 7 bit input opcode
      output reg  [1:0] alu_op, // produces alu op
      output reg        reg_dst, // reg redstiation
      output reg        branch, // allowed to make branch target if it is true
      output reg        mem_read, // read data from memory if 1
      output reg        mem_2_reg, // Either writes memory or alu result
      output reg        mem_write, // write to data memory
      output reg        alu_src, // control the second operand source
      output reg        reg_write, // write to register file
      output reg        jump // jump
   );

   // RISC-V opcode[6:0] (see RISC-V greensheet) pretty much self explanatory
   parameter integer ALU_R      = 7'b0110011; 
   parameter integer ALU_I      = 7'b0010011;
   parameter integer BRANCH_EQ  = 7'b1100011;
   parameter integer JUMP       = 7'b1101111;
   parameter integer LOAD       = 7'b0000011;
   parameter integer STORE      = 7'b0100011;

   // RISC-V ALUOp[1:0] (see book Figure 4.12) Given operation to ALU
   parameter [1:0] ADD_OPCODE     = 2'b00;
   parameter [1:0] SUB_OPCODE     = 2'b01;
   parameter [1:0] R_TYPE_OPCODE  = 2'b10;

   //The behavior of the control unit can be found in Chapter 4, Figure 4.18

   always@(*)begin
      // safe defaults -> Basically giving every single ouput a default value
      alu_op    = ADD_OPCODE;
      reg_dst   = 1'b0;
      branch    = 1'b0;
      mem_read  = 1'b0;
      mem_2_reg = 1'b0;
      mem_write = 1'b0;
      alu_src   = 1'b0;
      reg_write = 1'b0;
      jump      = 1'b0;


      case(opcode) // the main boy
         ALU_R: begin 
            alu_src   = 1'b0; // Second ALU inputs comes from the register not immediate 
            mem_2_reg = 1'b0; // Write ALU result back, not memory data
            reg_write = 1'b1; // Write result to destination register
            mem_read  = 1'b0; // No memory read
            mem_write = 1'b0; // No memory write
            branch    = 1'b0; // Not a branch 
            alu_op    = R_TYPE_OPCODE; // Tell ALU-control to inspect function bits
            jump      = 1'b0; // not a jump
            reg_dst   = 1'b1;   // only if reg_dst is actually used
         end
         
         ALU_I: begin   // ADDI
            alu_src   = 1'b1; // Second ALU inputs comes from the immediate 
            mem_2_reg = 1'b0; // Write ALU result back, not memory data
            reg_write = 1'b1; // Write result to destination register
            mem_read  = 1'b0; // No memory read
            mem_write = 1'b0; // No memory write
            branch    = 1'b0; // Not a branch 
            alu_op    = ADD_OPCODE; // Tell ALU just adds
            jump      = 1'b0; // not a jump
            reg_dst   = 1'b1; // only if reg_dst is actually used
         end

         LOAD: begin    // LD
            alu_src   = 1'b1; // use immediate 
            mem_2_reg = 1'b1; // write memory data into register
            reg_write = 1'b1; // destination register gets writte
            mem_read  = 1'b1; // read mem
            mem_write = 1'b0; // dont write, duh its a load command
            branch    = 1'b0; // dont branch
            alu_op    = ADD_OPCODE; // Tell ALU to add
            jump      = 1'b0; // not a jump
            reg_dst   = 1'b1; // only if reg_dst is actually used
         end

         
         STORE: begin   // SD store
            alu_src   = 1'b1; // use immediate offset
            mem_2_reg = 1'b0; // dont care
            reg_write = 1'b0; // don't write to register
            mem_read  = 1'b0; // don't read to mem
            mem_write = 1'b1; // write to mem
            branch    = 1'b0; // not a branch
            alu_op    = ADD_OPCODE; // Tell alu to add
            jump      = 1'b0; // not a jump
            reg_dst   = 1'b0; // don't care
         end

         BRANCH_EQ: begin   // BEQ
            alu_src   = 1'b0; // sceond soruce comes from reg 
            mem_2_reg = 1'b0; // don't care => dont write memory into register, duh its a branch why would you write
            reg_write = 1'b0; // not a write 
            mem_read  = 1'b0; // not a mem read
            mem_write = 1'b0; // not a mem write
            branch    = 1'b1; // this is literally a branch if equal then yea
            alu_op    = SUB_OPCODE; // ALU subtract cuz if its equal then subs == 0
            jump      = 1'b0; // not a jump
            reg_dst   = 1'b0; // don't care
         end


         JUMP: begin   // JAL-style jump
            alu_src   = 1'b0; 
            mem_2_reg = 1'b0;
            reg_write = 1'b0;   // unless your datapath writes PC+4 to rd
            mem_read  = 1'b0;
            mem_write = 1'b0;
            branch    = 1'b0;
            alu_op    = ADD_OPCODE; // don't care
            jump      = 1'b1; // the only thing that matters here
            reg_dst   = 1'b0;
         end
            // Declare the control signals for each one of the instructions here...

         default:begin // if the opcode is unknown basically do nothing here
            alu_src   = 1'b0;
            mem_2_reg = 1'b0;
            reg_write = 1'b0;
            mem_read  = 1'b0;
            mem_write = 1'b0;
            branch    = 1'b0;
            alu_op    = R_TYPE_OPCODE;
            jump      = 1'b0;
         end
      endcase
   end

endmodule



