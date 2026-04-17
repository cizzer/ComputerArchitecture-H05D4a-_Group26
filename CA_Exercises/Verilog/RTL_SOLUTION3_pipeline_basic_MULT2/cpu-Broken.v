//Module: CPU
//Function: CPU is the top design of the RISC-V processor

//Inputs:
//	clk: main clock
//	arst_n: reset 
// enable: Starts the execution
//	addr_ext: Address for reading/writing content to Instruction Memory
//	wen_ext: Write enable for Instruction Memory
// ren_ext: Read enable for Instruction Memory
//	wdata_ext: Write word for Instruction Memory
//	addr_ext_2: Address for reading/writing content to Data Memory
//	wen_ext_2: Write enable for Data Memory
// ren_ext_2: Read enable for Data Memory
//	wdata_ext_2: Write word for Data Memory

// Outputs:
//	rdata_ext: Read data from Instruction Memory
//	rdata_ext_2: Read data from Data Memory

/* 

General flow
1) Comes and goes PC to fetch instructions
2) Decode the instruction
3) Read source registers
4) Generate immediate if needed
5) Decide ALU operation
6) Execute ALU operation 
7) Access data memory if needed
8) Choose what gets written back to registers
9) Update the PC for next instruction

*/
module cpu(
		input  wire			  clk,         // clock
		input  wire         arst_n,      // active-low reset
		input  wire         enable,      // allows PC to advance 
		input  wire	[63:0]  addr_ext,    // address exit signal (external access ports)
		input  wire         wen_ext,     // write enable external exit signal (external access ports) (SW)
		input  wire         ren_ext,     // read enable external exit signal (external access ports)
		input  wire [31:0]  wdata_ext,   // write data exit signal (external access ports)
		input  wire	[63:0]  addr_ext_2,  // address exit 2 signal 
		input  wire         wen_ext_2,   // write enable external exit signal
		input  wire         ren_ext_2,   // read enable external exit signal
		input  wire [63:0]  wdata_ext_2, // write data exit signal
		
		output wire	[31:0]  rdata_ext,   // external readback from instruction memory
		output wire	[63:0]  rdata_ext_2  // external readback from data memory

   );

// NOTE THAT EXT WIRES ARE ONLY FOR TEST BENCH DO NOT TOUCH!!!!!!

//----------------------------------------------------------------------------------------------------------------------------
//                                                 Wires : PC/FETCH
//----------------------------------------------------------------------------------------------------------------------------

wire [63:0] branch_pc;        // target address if branch is taken
wire [63:0] updated_pc;       // PC + 4 next normal instruction address
wire [63:0] current_pc;       // current program counter
wire [63:0] jump_pc;          // jump target address 
wire [31:0] instruction;      // current 32 bit instruction from ins mem

//----------------------------------------------------------------------------------------------------------------------------
//                                                 Wires : Control
//----------------------------------------------------------------------------------------------------------------------------

wire [1:0]  alu_op;           // coarse ALU operation from control unit
wire [3:0]  alu_control;      // exact ALU command from ALU control
wire        reg_dst;          // register destination (unused in this datapath but kept for control unit compatibility)
wire        branch;           // if 1 branch
wire        mem_read;         // if 1 should read from data mem
wire        mem_2_reg;        // if 1 write memory data 2 reg else ALU result back
wire        mem_write;        // if 1 write to data memory
wire        alu_src;          // if 0 ALU input comes from reg else from immediate
wire        reg_write;        // if 1 reg write to rd
wire        jump;             // if 1 jump

//----------------------------------------------------------------------------------------------------------------------------
//                                                 Wires : Register files
//----------------------------------------------------------------------------------------------------------------------------

wire [63:0] regfile_wdata;    // the actual value written back
wire [63:0] regfile_rdata_1;  // first value read from reg
wire [63:0] regfile_rdata_2;  // second value read from reg

//----------------------------------------------------------------------------------------------------------------------------
//                                                 Wires : ALU Path
//----------------------------------------------------------------------------------------------------------------------------

wire [63:0] alu_out;          // ALU output
wire [63:0] alu_operand_2;    // actual second input of ALU after mux
wire        zero_flag;        // Becomes 1 when the ALU result is zero 

//----------------------------------------------------------------------------------------------------------------------------
//                                                 Wires : Memory Path
//----------------------------------------------------------------------------------------------------------------------------

wire [63:0] mem_data;         // read from mem

//----------------------------------------------------------------------------------------------------------------------------
//                                                 Wires : Immediate Path
//----------------------------------------------------------------------------------------------------------------------------

wire signed [63:0] immediate_extended; // sign extended immediate

//----------------------------------------------------------------------------------------------------------------------------
//                                                 Wires : Pipeline IF/ID
//----------------------------------------------------------------------------------------------------------------------------

wire [31:0] instruction_IF_ID; // instruction after IF/ID pipeline register
wire [63:0] current_pc_IF_ID;  // current PC after IF/ID pipeline register

//----------------------------------------------------------------------------------------------------------------------------
//                                                 Wires : Pipeline ID/EX
//----------------------------------------------------------------------------------------------------------------------------

wire [63:0] current_pc_ID_EX;
wire [63:0] immediate_extended_ID_EX;
wire [63:0] regfile_rdata_1_ID_EX;
wire [63:0] regfile_rdata_2_ID_EX;
wire [4:0]  rd_ID_EX;
wire [6:0]  func7_ID_EX;
wire [2:0]  func3_ID_EX;

wire [1:0]  alu_op_ID_EX;
wire        alu_src_ID_EX;
wire        mem_read_ID_EX;
wire        mem_write_ID_EX;
wire        mem_2_reg_ID_EX;
wire        reg_write_ID_EX;
wire        branch_ID_EX;
wire        jump_ID_EX;

//----------------------------------------------------------------------------------------------------------------------------
//                                                 Wires : Pipeline EX/MEM
//----------------------------------------------------------------------------------------------------------------------------

wire [63:0] alu_out_EX_MEM;
wire [63:0] regfile_rdata_2_EX_MEM;
wire [4:0]  rd_EX_MEM;

wire        mem_read_EX_MEM;
wire        mem_write_EX_MEM;
wire        mem_2_reg_EX_MEM;
wire        reg_write_EX_MEM;

//----------------------------------------------------------------------------------------------------------------------------
//                                                 Wires : Pipeline MEM/WB
//----------------------------------------------------------------------------------------------------------------------------

wire [63:0] mem_data_MEM_WB;
wire [63:0] alu_out_MEM_WB;
wire [4:0]  rd_MEM_WB;

wire        mem_2_reg_MEM_WB;
wire        reg_write_MEM_WB;

// ===========================================================================================================================
//                                                 IF : Instruction Fetch
// ===========================================================================================================================

pc #( // Programme counter block
   .DATA_W(64) // Instantiate with 64 bit data width
) program_counter (
   .clk       (clk         ), 
   .arst_n    (arst_n      ), // reset is triggered when the signal is 0, not 1
   .branch_pc (branch_pc   ), // input from branch unit
   .jump_pc   (jump_pc     ), // input from branch unit
   .zero_flag (zero_flag   ), // input from ALU in EX stage
   .branch    (branch_ID_EX), // use pipelined branch control from EX stage
   .jump      (jump_ID_EX  ), // use pipelined jump control from EX stage
   .current_pc(current_pc  ), // main output
   .enable    (enable      ), 
   .updated_pc(updated_pc  )  // main output
);

sram_BW32 #( // 32 bit wide SRAM 
   .ADDR_W(9 ) // Address parameter is set to 9
) instruction_memory( 
   .clk      (clk        ), // Connect its clk port with CPU clock
   .addr     (current_pc ), // Use the current PC as the address to read the instruction from
   .wen      (1'b0       ), // Write enable is hardwired to 0 during normal CPU execution
   .ren      (1'b1       ), // Read enable is hardwired to 1
   .wdata    (32'b0      ), // write data is just tied to zero
   .rdata    (instruction), // output instruction
   .addr_ext (addr_ext   ), // External address input
   .wen_ext  (wen_ext    ), // External write enable
   .ren_ext  (ren_ext    ), // External read enable
   .wdata_ext(wdata_ext  ), // testbench stuff
   .rdata_ext(rdata_ext  )  // testbench stuff
);

// ===========================================================================================================================
//                                                 IF/ID : Pipeline
// ===========================================================================================================================

reg_arstn_en #(
   .DATA_W(32)
) Pipeline_IF_ID_instr(
   .clk    (clk             ),
   .arst_n (arst_n          ),
   .en     (enable          ),
   .din    (instruction     ),
   .dout   (instruction_IF_ID)
);

reg_arstn_en #(
   .DATA_W(64)
) Pipeline_IF_ID_pc(
   .clk    (clk           ),
   .arst_n (arst_n        ),
   .en     (enable        ),
   .din    (current_pc    ),
   .dout   (current_pc_IF_ID)
);

// ===========================================================================================================================
//                                                 ID : Instruction Decode
// ===========================================================================================================================

control_unit control_unit(
   .opcode   (instruction_IF_ID[6:0]), // Bottom 7 from the IF/ID instruction
   .alu_op   (alu_op                ), // Coarse ALU
   .reg_dst  (reg_dst               ), 
   .branch   (branch                ), // branch logic
   .mem_read (mem_read              ), // Enables data-memory read for ld
   .mem_2_reg(mem_2_reg             ), // Controls whether writeback comes from memory or ALU
   .mem_write(mem_write             ), // Enables data-memory write for sd
   .alu_src  (alu_src               ), // Selects ALU reg or immediate
   .reg_write(reg_write             ), // Reg file write enable
   .jump     (jump                  )  // PC logic to jump
);

register_file #(
   .DATA_W(64)
) register_file(
   .clk      (clk                      ),
   .arst_n   (arst_n                   ),
   .reg_write(reg_write_MEM_WB         ), // writeback control comes from WB stage
   .raddr_1  (instruction_IF_ID[19:15] ),
   .raddr_2  (instruction_IF_ID[24:20] ),
   .waddr    (rd_MEM_WB                ), // destination register comes from WB stage
   .wdata    (regfile_wdata            ), // writeback data comes from WB mux
   .rdata_1  (regfile_rdata_1          ),
   .rdata_2  (regfile_rdata_2          )
);

immediate_extend_unit immediate_extend_u(
    .instruction        (instruction_IF_ID   ), // decode uses IF/ID instruction
    .immediate_extended (immediate_extended  )  // outputs 64 bit thus wire must be 64 bit
); 

// ===========================================================================================================================
//                                                 ID/EX : Second Pipeline
// ===========================================================================================================================

reg_arstn_en #(
   .DATA_W(64)
) Pipeline_pc_ID_EX(
   .clk    (clk             ),
   .arst_n (arst_n          ),
   .en     (enable          ),
   .din    (current_pc_IF_ID),
   .dout   (current_pc_ID_EX)
);

reg_arstn_en #(
   .DATA_W(64)
) Pipeline_immediate_extended_ID_EX(
   .clk    (clk                     ),
   .arst_n (arst_n                  ),
   .en     (enable                  ),
   .din    (immediate_extended      ),
   .dout   (immediate_extended_ID_EX)
);

reg_arstn_en #(
   .DATA_W(64)
) Pipeline_regfile_rdata_1_ID_EX(
   .clk    (clk               ),
   .arst_n (arst_n            ),
   .en     (enable            ),
   .din    (regfile_rdata_1   ),
   .dout   (regfile_rdata_1_ID_EX)
);

reg_arstn_en #(
   .DATA_W(64)
) Pipeline_regfile_rdata_2_ID_EX(
   .clk    (clk               ),
   .arst_n (arst_n            ),
   .en     (enable            ),
   .din    (regfile_rdata_2   ),
   .dout   (regfile_rdata_2_ID_EX)
);

reg_arstn_en #(
   .DATA_W(5)
) Pipeline_rd_ID_EX(
   .clk    (clk                  ),
   .arst_n (arst_n               ),
   .en     (enable               ),
   .din    (instruction_IF_ID[11:7]),
   .dout   (rd_ID_EX             )
);

reg_arstn_en #(
   .DATA_W(7)
) Pipeline_func7_ID_EX(
   .clk    (clk                   ),
   .arst_n (arst_n                ),
   .en     (enable                ),
   .din    (instruction_IF_ID[31:25]),
   .dout   (func7_ID_EX           )
);

reg_arstn_en #(
   .DATA_W(3)
) Pipeline_func3_ID_EX(
   .clk    (clk                   ),
   .arst_n (arst_n                ),
   .en     (enable                ),
   .din    (instruction_IF_ID[14:12]),
   .dout   (func3_ID_EX           )
);

// --------------------------------------------
// control signals must also cross ID -> EX
// --------------------------------------------

reg_arstn_en #(
   .DATA_W(2)
) Pipeline_alu_op_ID_EX(
   .clk    (clk         ),
   .arst_n (arst_n      ),
   .en     (enable      ),
   .din    (alu_op      ),
   .dout   (alu_op_ID_EX)
);

reg_arstn_en #(
   .DATA_W(1)
) Pipeline_alu_src_ID_EX(
   .clk    (clk          ),
   .arst_n (arst_n       ),
   .en     (enable       ),
   .din    (alu_src      ),
   .dout   (alu_src_ID_EX)
);

reg_arstn_en #(
   .DATA_W(1)
) Pipeline_mem_read_ID_EX(
   .clk    (clk           ),
   .arst_n (arst_n        ),
   .en     (enable        ),
   .din    (mem_read      ),
   .dout   (mem_read_ID_EX)
);

reg_arstn_en #(
   .DATA_W(1)
) Pipeline_mem_write_ID_EX(
   .clk    (clk            ),
   .arst_n (arst_n         ),
   .en     (enable         ),
   .din    (mem_write      ),
   .dout   (mem_write_ID_EX)
);

reg_arstn_en #(
   .DATA_W(1)
) Pipeline_mem_2_reg_ID_EX(
   .clk    (clk             ),
   .arst_n (arst_n          ),
   .en     (enable          ),
   .din    (mem_2_reg       ),
   .dout   (mem_2_reg_ID_EX )
);

reg_arstn_en #(
   .DATA_W(1)
) Pipeline_reg_write_ID_EX(
   .clk    (clk             ),
   .arst_n (arst_n          ),
   .en     (enable          ),
   .din    (reg_write       ),
   .dout   (reg_write_ID_EX )
);

reg_arstn_en #(
   .DATA_W(1)
) Pipeline_branch_ID_EX(
   .clk    (clk          ),
   .arst_n (arst_n       ),
   .en     (enable       ),
   .din    (branch       ),
   .dout   (branch_ID_EX )
);

reg_arstn_en #(
   .DATA_W(1)
) Pipeline_jump_ID_EX(
   .clk    (clk        ),
   .arst_n (arst_n     ),
   .en     (enable     ),
   .din    (jump       ),
   .dout   (jump_ID_EX )
);

// ===========================================================================================================================
//                                                 EX : Execute
// ===========================================================================================================================

mux_2 #(
   .DATA_W(64)
) alu_operand_mux (
   .input_a (immediate_extended_ID_EX),
   .input_b (regfile_rdata_2_ID_EX   ),
   .select_a(alu_src_ID_EX           ),
   .mux_out (alu_operand_2           )
);

alu_control alu_ctrl(
   .func7       (func7_ID_EX  ),
   .func3       (func3_ID_EX  ),
   .alu_op      (alu_op_ID_EX ),
   .alu_control (alu_control  )
);

alu #(
   .DATA_W(64)
) alu(
   .alu_in_0 (regfile_rdata_1_ID_EX),
   .alu_in_1 (alu_operand_2        ),
   .alu_ctrl (alu_control          ),
   .alu_out  (alu_out              ),
   .zero_flag(zero_flag            ),
   .overflow (                     )  // not used in this CPU
);

branch_unit #(
   .DATA_W(64)
) branch_unit_u(
   .current_pc         (current_pc_ID_EX         ),
   .immediate_extended (immediate_extended_ID_EX ),
   .branch_pc          (branch_pc                ),
   .jump_pc            (jump_pc                  )
);

// ===========================================================================================================================
//                                                 EX/MEM : Third Pipeline
// ===========================================================================================================================

reg_arstn_en #(
   .DATA_W(64)
) Pipeline_ALU_EX_MEM(
   .clk    (clk          ),
   .arst_n (arst_n       ),
   .en     (enable       ),
   .din    (alu_out      ),
   .dout   (alu_out_EX_MEM)
);

reg_arstn_en #(
   .DATA_W(64)
) Pipeline_regfile_rdata_2_EX_MEM(
   .clk    (clk                  ),
   .arst_n (arst_n               ),
   .en     (enable               ),
   .din    (regfile_rdata_2_ID_EX),
   .dout   (regfile_rdata_2_EX_MEM)
);

reg_arstn_en #(
   .DATA_W(5)
) Pipeline_rd_EX_MEM(
   .clk    (clk      ),
   .arst_n (arst_n   ),
   .en     (enable   ),
   .din    (rd_ID_EX ),
   .dout   (rd_EX_MEM)
);

// --------------------------------------------
// control signals must also cross EX -> MEM
// --------------------------------------------

reg_arstn_en #(
   .DATA_W(1)
) Pipeline_mem_read_EX_MEM(
   .clk    (clk           ),
   .arst_n (arst_n        ),
   .en     (enable        ),
   .din    (mem_read_ID_EX),
   .dout   (mem_read_EX_MEM)
);

reg_arstn_en #(
   .DATA_W(1)
) Pipeline_mem_write_EX_MEM(
   .clk    (clk            ),
   .arst_n (arst_n         ),
   .en     (enable         ),
   .din    (mem_write_ID_EX),
   .dout   (mem_write_EX_MEM)
);

reg_arstn_en #(
   .DATA_W(1)
) Pipeline_mem_2_reg_EX_MEM(
   .clk    (clk            ),
   .arst_n (arst_n         ),
   .en     (enable         ),
   .din    (mem_2_reg_ID_EX),
   .dout   (mem_2_reg_EX_MEM)
);

reg_arstn_en #(
   .DATA_W(1)
) Pipeline_reg_write_EX_MEM(
   .clk    (clk             ),
   .arst_n (arst_n          ),
   .en     (enable          ),
   .din    (reg_write_ID_EX ),
   .dout   (reg_write_EX_MEM)
);

// ===========================================================================================================================
//                                                 MEM : Memory
// ===========================================================================================================================

sram_BW64 #(
   .ADDR_W(10) // address width and data width are different things, this is fine
) data_memory(
   .clk      (clk                 ),
   .addr     (alu_out_EX_MEM      ),
   .wen      (mem_write_EX_MEM    ),
   .ren      (mem_read_EX_MEM     ),
   .wdata    (regfile_rdata_2_EX_MEM),
   .rdata    (mem_data            ),
   .addr_ext (addr_ext_2          ),
   .wen_ext  (wen_ext_2           ),
   .ren_ext  (ren_ext_2           ),
   .wdata_ext(wdata_ext_2         ),
   .rdata_ext(rdata_ext_2         )
);

// ===========================================================================================================================
//                                                 MEM/WB : Fourth Pipeline
// ===========================================================================================================================

reg_arstn_en #(
   .DATA_W(64)
) Pipeline_ALU_RES_MEM_WB(
   .clk    (clk            ),
   .arst_n (arst_n         ),
   .en     (enable         ),
   .din    (alu_out_EX_MEM ),
   .dout   (alu_out_MEM_WB )
);

reg_arstn_en #(
   .DATA_W(64)
) Pipeline_mem_data_MEM_WB(
   .clk    (clk            ),
   .arst_n (arst_n         ),
   .en     (enable         ),
   .din    (mem_data       ),
   .dout   (mem_data_MEM_WB)
);

reg_arstn_en #(
   .DATA_W(5)
) Pipeline_rd_MEM_WB(
   .clk    (clk       ),
   .arst_n (arst_n    ),
   .en     (enable    ),
   .din    (rd_EX_MEM ),
   .dout   (rd_MEM_WB )
);

// --------------------------------------------
// control signals must also cross MEM -> WB
// --------------------------------------------

reg_arstn_en #(
   .DATA_W(1)
) Pipeline_mem_2_reg_MEM_WB(
   .clk    (clk             ),
   .arst_n (arst_n          ),
   .en     (enable          ),
   .din    (mem_2_reg_EX_MEM),
   .dout   (mem_2_reg_MEM_WB)
);

reg_arstn_en #(
   .DATA_W(1)
) Pipeline_reg_write_MEM_WB(
   .clk    (clk             ),
   .arst_n (arst_n          ),
   .en     (enable          ),
   .din    (reg_write_EX_MEM),
   .dout   (reg_write_MEM_WB)
);

// ===========================================================================================================================
//                                                 WB : Write Back
// ===========================================================================================================================

mux_2 #(
   .DATA_W(64)
) regfile_data_mux (
   .input_a  (mem_data_MEM_WB ),
   .input_b  (alu_out_MEM_WB  ),
   .select_a (mem_2_reg_MEM_WB),
   .mux_out  (regfile_wdata   )
);

endmodule