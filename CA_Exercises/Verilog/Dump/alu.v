//Module: ALU
//Function: The ALU is a combinational circuit that executes the arithmetic or logical operation taking into account the control signals and input operands.

module alu #(
   parameter integer DATA_W = 16
   )(
      input   wire signed [DATA_W-1:0] alu_in_0,
      input   wire signed [DATA_W-1:0] alu_in_1,
      input   wire        [3:0]        alu_ctrl,
      output  reg  signed [DATA_W-1:0] alu_out,
      output  reg                      zero_flag,
      output  reg                      overflow
   );

   // ALU control codes
   parameter [3:0] AND_OP = 4'd0;
   parameter [3:0] OR_OP  = 4'd1;
   parameter [3:0] ADD_OP = 4'd2;
   parameter [3:0] SLL_OP = 4'd3;
   parameter [3:0] SRL_OP = 4'd4;
   parameter [3:0] SUB_OP = 4'd6;
   parameter [3:0] SLT_OP = 4'd7;
   parameter [3:0] MUL_OP = 4'd8;

   // Internal signals
   reg signed [DATA_W-1:0] sub_out, add_out, and_out, or_out;
   reg signed [DATA_W-1:0] slt_out, sll_out, srl_out, mul_out;
   reg                     overflow_add, overflow_sub, msb_equal_flag;

   // ZERO FLAG
   always @(*) begin
      if (alu_out == {DATA_W{1'b0}})
         zero_flag = 1'b1;
      else
         zero_flag = 1'b0;
   end

   // ARITHMETIC and LOGIC OPERATIONS
   always @(*) begin
      add_out = alu_in_0 + alu_in_1;
      sub_out = alu_in_0 - alu_in_1;
      and_out = alu_in_0 & alu_in_1;
      or_out  = alu_in_0 | alu_in_1;
      sll_out = alu_in_0 << alu_in_1[5:0];
      srl_out = alu_in_0 >> alu_in_1[5:0];
      slt_out = (alu_in_0 < alu_in_1) ? {{(DATA_W-1){1'b0}}, 1'b1} : {DATA_W{1'b0}};
      mul_out = alu_in_0 * alu_in_1;
   end

   // Output select
   always @(*) begin
      case (alu_ctrl)
         AND_OP: alu_out = and_out;
         OR_OP : alu_out = or_out;
         ADD_OP: alu_out = add_out;
         SLL_OP: alu_out = sll_out;
         SRL_OP: alu_out = srl_out;
         SUB_OP: alu_out = sub_out;
         SLT_OP: alu_out = slt_out;
         MUL_OP: alu_out = mul_out;
         default: alu_out = {DATA_W{1'b0}};
      endcase
   end

   // OVERFLOW DETECTION
   always @(*) begin
      if (alu_in_0[DATA_W-1] == alu_in_1[DATA_W-1])
         msb_equal_flag = 1'b1;
      else
         msb_equal_flag = 1'b0;
   end

   always @(*) begin
      if ((msb_equal_flag == 1'b1) && (add_out[DATA_W-1] != alu_in_0[DATA_W-1]))
         overflow_add = 1'b1;
      else
         overflow_add = 1'b0;
   end

   always @(*) begin
      if ((msb_equal_flag == 1'b1) && (sub_out[DATA_W-1] != alu_in_0[DATA_W-1]))
         overflow_sub = 1'b1;
      else
         overflow_sub = 1'b0;
   end

   always @(*) begin
      if (alu_ctrl == ADD_OP)
         overflow = overflow_add;
      else
         overflow = overflow_sub;
   end

endmodule