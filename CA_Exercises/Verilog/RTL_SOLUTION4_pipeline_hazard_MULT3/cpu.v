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

// ext for test bench
   
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

wire [3:0]  alu_control;      // exact ALU command from ALU control

wire [1:0]  alu_op;           // coarse ALU operation from control unit
wire        reg_dst;          // register destination (unused in this datapath but kept for control unit compatibility)
wire        branch;           // if 1 branch
wire        mem_read;         // if 1 should read from data mem
wire        mem_2_reg;        // if 1 write memory data 2 reg else ALU result back
wire        mem_write;        // if 1 write to data memory
wire        alu_src;          // if 0 ALU input comes from reg else from immediate
wire        reg_write;        // if 1 reg write to rd
wire        jump;             // if 1 jump

// Additional wire for hazard

wire        if_id_write_wire; // Either continue or no
wire        pc_write_wire;    // Either write or no
wire        flush_wire;       // Either flush or no

// Get muxed

wire [1:0]  muxed_alu_op;           // coarse ALU operation from control unit
wire        muxed_reg_dst;          // register destination (unused in this datapath but kept for control unit compatibility)
wire        muxed_branch;           // if 1 branch
wire        muxed_mem_read;         // if 1 should read from data mem
wire        muxed_mem_2_reg;        // if 1 write memory data 2 reg else ALU result back
wire        muxed_mem_write;        // if 1 write to data memory
wire        muxed_alu_src;          // if 0 ALU input comes from reg else from immediate
wire        muxed_reg_write;        // if 1 reg write to rd
wire        muxed_jump;             // if 1 jump

//----------------------------------------------------------------------------------------------------------------------------
//                                                 Wires : Register files
//----------------------------------------------------------------------------------------------------------------------------

wire [63:0] regfile_wdata;    // the actual value written back
wire [63:0] regfile_rdata_1;  // first value read from reg
wire [63:0] regfile_rdata_2;  // second value read from reg
wire [4:0] raddr_1_ID_EX;  // raddr1
wire [4:0] raddr_2_ID_EX;  // raddr2
//----------------------------------------------------------------------------------------------------------------------------
//                                                 Wires : ALU Path
//----------------------------------------------------------------------------------------------------------------------------

wire [63:0] alu_out;          // ALU output
wire [63:0] alu_operand_2;    // actual second input of ALU after mux
wire        zero_flag;        // Becomes 1 when the ALU result is zero
wire [63:0] mux_a_wire;       // connecting mux_a with alu
wire [63:0] mux_b_wire;       // connecting mux_b with mux_2
wire [63:0] mux_c_wire;       // connecting mux_2 with alu
wire [1:0]  forwardA_wire;     // Connecting FWU with MUX3
wire [1:0]  forwardB_wire;     // Connecting FWU with MUX3 

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

pc #(
   .DATA_W(64)
) program_counter (
   .clk       (clk            ),
   .arst_n    (arst_n         ),
   .branch_pc (branch_pc      ), //INPUT
   .jump_pc   (jump_pc        ), //INPUT
   .zero_flag (zero_flag      ), //INPUT
   .branch    (branch_ID_EX   ), //INPUT
   .jump      (jump_ID_EX     ), //INPUT
   .current_pc(current_pc     ), //OUTPUT
   .enable    (enable && pc_write_wire), // Now it is linked with the hazard ctr
   .updated_pc(updated_pc     )  //OUTPUT
);

sram_BW32 #(
   .ADDR_W(9 )
) instruction_memory(
   .clk      (clk           ),
   .addr     (current_pc    ), // INPUT 
   .wen      (1'b0          ), // INPUT (Overwritten = 0)
   .ren      (1'b1          ), // INPUT (Overwritten = 1)
   .wdata    (32'b0         ), // INPUT (Overwritten = 0)
   .rdata    (instruction   ), // OUTPUT   
   .addr_ext (addr_ext      ),
   .wen_ext  (wen_ext       ), 
   .ren_ext  (ren_ext       ),
   .wdata_ext(wdata_ext     ),
   .rdata_ext(rdata_ext     )
);

//----------------------------------------------------------------------------------------------------------------------------
//                                                          IF/ID
//----------------------------------------------------------------------------------------------------------------------------

// 2 INPUT 2 OUPTUT

reg_arstn_en #(
   .DATA_W(64)
) Pipeline_IF_ID_current_pc(
   .clk    (clk             ),
   .arst_n (arst_n          ),
   .en     (enable && if_id_write_wire),
   .din    (current_pc     ),
   .dout   (current_pc_IF_ID)
);


reg_arstn_en #(
   .DATA_W(32)
) Pipeline_IF_ID_instr(
   .clk    (clk             ),
   .arst_n (arst_n          ),
   .en     (enable && if_id_write_wire),
   .din    (instruction     ),
   .dout   (instruction_IF_ID)
);

// ===========================================================================================================================
//                                                 ID : Instruction Decode
// ===========================================================================================================================

control_unit control_unit(
   .opcode   (instruction_IF_ID[6:0]),
   .alu_op   (alu_op          ),
   .reg_dst  (reg_dst         ),
   .branch   (branch          ),
   .mem_read (mem_read        ),
   .mem_2_reg(mem_2_reg       ),
   .mem_write(mem_write       ),
   .alu_src  (alu_src         ),
   .reg_write(reg_write       ),
   .jump     (jump            )
);

register_file #(
   .DATA_W(64)
) register_file(
   .clk      (clk                      ),
   .arst_n   (arst_n                   ),
   .reg_write(reg_write_MEM_WB         ), // INPUT on Write port, thus it must pass through all WB 
   .raddr_1  (instruction_IF_ID[19:15] ), // INPUT
   .raddr_2  (instruction_IF_ID[24:20] ), // INPUT
   .waddr    (rd_MEM_WB                ), // INPUT on Write port, thus it must pass through all WB
   .wdata    (regfile_wdata            ), // INPUT on Write port
   .rdata_1  (regfile_rdata_1          ), // OUTPUT
   .rdata_2  (regfile_rdata_2          ) // OUTPUT
);

immediate_extend_unit immediate_extend_u(
    .instruction         (instruction_IF_ID),
    .immediate_extended  (immediate_extended)
);

hazard_ctrl hazard_ctrl( // Hazard control unit
   .raddr_1       (instruction_IF_ID[19:15]), //INPUT
   .raddr_2       (instruction_IF_ID[24:20]), //INPUT
   .mem_read      (mem_read_ID_EX), //INPUT
   .rd            (rd_ID_EX), //INPUT
   .pc_write      (pc_write_wire), //OUTPUT
   .if_id_write   (if_id_write_wire), //OUTPUT
   .flush         (flush_wire) //OUTPUT
); 

// When flushing we should flush all control signals!!!!!!!!!!

mux_2 #(
   .DATA_W(2)
) mux_flush_alu_op ( // mux that decides whether to flush or not
   .input_a (2'b00), // INPUT
   .input_b (alu_op), // INPUT
   .select_a(flush_wire), // INPUT
   .mux_out (muxed_alu_op)  // OUTPUT
);

mux_2 #(
   .DATA_W(1)
) mux_flush_reg_dst ( // mux that decides whether to flush or not
   .input_a (1b'0), // INPUT
   .input_b (reg_dst), // INPUT
   .select_a(flush_wire), // INPUT
   .mux_out (muxed_reg_dst)  // OUTPUT
);

mux_2 #(
   .DATA_W(1)
) mux_flush_branch ( // mux that decides whether to flush or not
   .input_a (1'b0), // INPUT
   .input_b (branch), // INPUT
   .select_a(flush_wire), // INPUT
   .mux_out (muxed_branch)  // OUTPUT
);

mux_2 #(
   .DATA_W(1)
) mux_flush_mem_read ( // mux that decides whether to flush or not
   .input_a (1'b0), // INPUT
   .input_b (mem_read), // INPUT
   .select_a(flush_wire), // INPUT
   .mux_out (muxed_mem_read)  // OUTPUT
);

mux_2 #(
   .DATA_W(1)
) mux_flush_mem_2_reg ( // mux that decides whether to flush or not
   .input_a (1'b0), // INPUT
   .input_b (mem_2_reg), // INPUT
   .select_a(flush_wire), // INPUT
   .mux_out (muxed_mem_2_reg)  // OUTPUT
);

mux_2 #(
   .DATA_W(1)
) mux_flush_mem_write ( // mux that decides whether to flush or not
   .input_a (1'b0), // INPUT
   .input_b (mem_write), // INPUT
   .select_a(flush_wire), // INPUT
   .mux_out (muxed_mem_write)  // OUTPUT
);

mux_2 #(
   .DATA_W(1)
) mux_flush_alu_src ( // mux that decides whether to flush or not
   .input_a (1'b0), // INPUT
   .input_b (alu_src), // INPUT
   .select_a(flush_wire), // INPUT
   .mux_out (muxed_alu_src)  // OUTPUT
);

mux_2 #(
   .DATA_W(1)
) mux_flush_reg_write ( // mux that decides whether to flush or not
   .input_a (1'b0), // INPUT
   .input_b (reg_write), // INPUT
   .select_a(flush_wire), // INPUT
   .mux_out (muxed_reg_write)  // OUTPUT
);

mux_2 #(
   .DATA_W(1)
) mux_flush_jump ( // mux that decides whether to flush or not
   .input_a (1'b0), // INPUT
   .input_b (jump), // INPUT
   .select_a(flush_wire), // INPUT
   .mux_out (muxed_jump)  // OUTPUT
);




//----------------------------------------------------------------------------------------------------------------------------
//                                                          ID/EX
//----------------------------------------------------------------------------------------------------------------------------

// 12 input 12 output

// Controllsssss
reg_arstn_en #(
   .DATA_W(64)
) Pipeline_ID_EX_current_pc(
   .clk    (clk             ),
   .arst_n (arst_n          ),
   .en     (enable          ),
   .din    (current_pc_IF_ID),
   .dout   (current_pc_ID_EX)
);

reg_arstn_en #(
   .DATA_W(2)
) Pipeline_ID_EX_alu_op(
   .clk    (clk             ),
   .arst_n (arst_n          ),
   .en     (enable          ),
   .din    (muxed_alu_op),
   .dout   (alu_op_ID_EX)
);

reg_arstn_en #(
   .DATA_W(1) // Fixed this to 1
) Pipeline_ID_EX_branch(
   .clk    (clk             ),
   .arst_n (arst_n          ),
   .en     (enable          ),
   .din    (muxed_branch),
   .dout   (branch_ID_EX) // Branch and jump should be exectued in EX so I will just write it here
);

reg_arstn_en #(
   .DATA_W(1)
) Pipeline_ID_EX_mem_read(
   .clk    (clk             ),
   .arst_n (arst_n          ),
   .en     (enable          ),
   .din    (muxed_mem_read),
   .dout   (mem_read_ID_EX)
);

reg_arstn_en #(
   .DATA_W(1)
) Pipeline_ID_EX_mem_2_reg(
   .clk    (clk               ),
   .arst_n (arst_n            ),
   .en     (enable            ),
   .din    (muxed_mem_2_reg         ),
   .dout   (mem_2_reg_ID_EX   )
);

reg_arstn_en #(
   .DATA_W(1)
) Pipeline_ID_EX_mem_write(
   .clk    (clk             ),
   .arst_n (arst_n          ),
   .en     (enable          ),
   .din    (muxed_mem_write),
   .dout   (mem_write_ID_EX)
);

reg_arstn_en #(
   .DATA_W(1)
) Pipeline_ID_EX_alu_src(
   .clk    (clk             ),
   .arst_n (arst_n          ),
   .en     (enable          ),
   .din    (muxed_alu_src),
   .dout   (alu_src_ID_EX)
);

reg_arstn_en #(
   .DATA_W(1)
) Pipeline_ID_EX_reg_write(
   .clk    (clk             ),
   .arst_n (arst_n          ),
   .en     (enable          ),
   .din    (muxed_reg_write),
   .dout   (reg_write_ID_EX)
);

reg_arstn_en #(
   .DATA_W(1)
) Pipeline_ID_EX_jump(
   .clk    (clk             ),
   .arst_n (arst_n          ),
   .en     (enable          ),
   .din    (muxed_jump),
   .dout   (jump_ID_EX) // Branch and jump should be exectued in EX so I will just write it here
);

// Note to self, at this stage of the cpu I have not resolved the jump and branch

reg_arstn_en #(
   .DATA_W(64)
) Pipeline_ID_EX_regfile_rdata_1(
   .clk    (clk             ),
   .arst_n (arst_n          ),
   .en     (enable          ),
   .din    (regfile_rdata_1),
   .dout   (regfile_rdata_1_ID_EX)
);

reg_arstn_en #(
   .DATA_W(64)
) Pipeline_ID_EX_immediate_extended(
   .clk    (clk             ),
   .arst_n (arst_n          ),
   .en     (enable          ),
   .din    (immediate_extended),
   .dout   (immediate_extended_ID_EX)
);

reg_arstn_en #(
   .DATA_W(64)
) Pipeline_ID_EX_regfile_rdata_2(
   .clk    (clk             ),
   .arst_n (arst_n          ),
   .en     (enable          ),
   .din    (regfile_rdata_2),
   .dout   (regfile_rdata_2_ID_EX)
);

reg_arstn_en #(
   .DATA_W(7)
) Pipeline_ID_EX_func7(
   .clk    (clk             ),
   .arst_n (arst_n          ),
   .en     (enable          ),
   .din    (instruction_IF_ID[31:25]),
   .dout   (func7_ID_EX)
);

reg_arstn_en #(
   .DATA_W(3)
) Pipeline_ID_EX_func3(
   .clk    (clk             ),
   .arst_n (arst_n          ),
   .en     (enable          ),
   .din    (instruction_IF_ID[14:12]), // [14:12] here not [31:25]
   .dout   (func3_ID_EX)
);

reg_arstn_en #(
   .DATA_W(5)
) Pipeline_ID_EX_rb( // For the writeback of the address into register (Many mistakes were done here)
   .clk    (clk             ),
   .arst_n (arst_n          ),
   .en     (enable          ),
   .din    (instruction_IF_ID[11:7]),
   .dout   (rd_ID_EX)
);

reg_arstn_en #(
   .DATA_W(5)
) Pipeline_raddr_1( // For the writeback of the address into register (Many mistakes were done here)
   .clk    (clk             ),
   .arst_n (arst_n          ),
   .en     (enable          ),
   .din    (instruction_IF_ID[19:15]),
   .dout   (raddr_1_ID_EX)
);

reg_arstn_en #(
   .DATA_W(5)
) Pipeline_raddr_2( // For the writeback of the address into register (Many mistakes were done here)
   .clk    (clk             ),
   .arst_n (arst_n          ),
   .en     (enable          ),
   .din    (instruction_IF_ID[24:20]),
   .dout   (raddr_2_ID_EX)
);



// ===========================================================================================================================
//                                                 EX : Execute
// ===========================================================================================================================


branch_unit#(
   .DATA_W(64)
)branch_unit(
   .current_pc         (current_pc_ID_EX           ), // INPUT
   .immediate_extended (immediate_extended_ID_EX   ), // INPUT
   .branch_pc          (branch_pc                  ), // OUTPUT
   .jump_pc            (jump_pc                    ) // OUTPUT
);

mux_3 #(
   .DATA_W(64)
) mux_a (
   .input_a (regfile_rdata_1_ID_EX     ), // INPUT
   .input_b (regfile_wdata             ), // INPUT
   .input_c (alu_out_EX_MEM            ), // INPUT
   .select_a(forwardA_wire             ), // INPUT
   .mux_out (mux_a_wire                )  // OUTPUT
);

mux_3 #(
   .DATA_W(64)
) mux_b (
   .input_a (regfile_rdata_2_ID_EX  ), // INPUT
   .input_b (regfile_wdata             ), // INPUT
   .input_c (alu_out_EX_MEM            ), // INPUT
   .select_a(forwardB_wire             ), // INPUT
   .mux_out (mux_b_wire                )  // OUTPUT
);


mux_2 #(
   .DATA_W(64)
) mux_c (
   .input_a (immediate_extended_ID_EX  ), // INPUT
   .input_b (mux_b_wire                ), // INPUT
   .select_a(alu_src_ID_EX             ), // INPUT
   .mux_out (mux_c_wire             )  // OUTPUT
);

alu_control alu_ctrl(
   .func7       (func7_ID_EX  ), // INPUT
   .func3       (func3_ID_EX  ), // INPUT
   .alu_op      (alu_op_ID_EX ), // INPUT
   .alu_control (alu_control  )  // OUTPUT
);

alu#(
   .DATA_W(64)
) alu(
   .alu_in_0 (mux_a_wire ), // INPUT
   .alu_in_1 (mux_c_wire   ), // INPUT
   .alu_ctrl (alu_control     ), // INPUT
   .alu_out  (alu_out         ), // OUTPUT
   .zero_flag(zero_flag       ), // OUTPUT
   .overflow (                ) // OUTPUT
);

fw_unit fw_unit(
   .raddr_1_ID_EX       (raddr_1_ID_EX),     // INPUT
   .raddr_2_ID_EX       (raddr_2_ID_EX),     // INPUT
   .reg_write_EX_MEM    (reg_write_EX_MEM),  // INPUT
   .reg_write_MEM_WB    (reg_write_MEM_WB),  // INPUT
   .rd_EX_MEM           (rd_EX_MEM),         // INPUT
   .rd_MEM_WB           (rd_MEM_WB),          // INPUT
   .forwardA            (forwardA_wire),     // OUTPUT
   .forwardB            (forwardB_wire)      // OUTPUT
);


//----------------------------------------------------------------------------------------------------------------------------
//                                                          EX/MEM
//----------------------------------------------------------------------------------------------------------------------------

// 7 INPUT 7 OUTPUT

reg_arstn_en #(
   .DATA_W(1)
) Pipeline_EX_MEM_mem_read(
   .clk    (clk             ),
   .arst_n (arst_n          ),
   .en     (enable          ),
   .din    (mem_read_ID_EX),
   .dout   (mem_read_EX_MEM)
);

reg_arstn_en #(
   .DATA_W(1)
) Pipeline_EX_MEM_mem_2_reg(
   .clk    (clk             ),
   .arst_n (arst_n          ),
   .en     (enable          ),
   .din    (mem_2_reg_ID_EX),
   .dout   (mem_2_reg_EX_MEM)
);

reg_arstn_en #(
   .DATA_W(1)
) Pipeline_EX_MEM_mem_write(
   .clk    (clk             ),
   .arst_n (arst_n          ),
   .en     (enable          ),
   .din    (mem_write_ID_EX),
   .dout   (mem_write_EX_MEM)
);

reg_arstn_en #(
   .DATA_W(1)
) Pipeline_EX_MEM_reg_write(
   .clk    (clk             ),
   .arst_n (arst_n          ),
   .en     (enable          ),
   .din    (reg_write_ID_EX),
   .dout   (reg_write_EX_MEM)
);

reg_arstn_en #(
   .DATA_W(64)
) Pipeline_EX_MEM_alu_out(
   .clk    (clk             ),
   .arst_n (arst_n          ),
   .en     (enable          ),
   .din    (alu_out),
   .dout   (alu_out_EX_MEM)
);

reg_arstn_en #(
   .DATA_W(64)
) Pipeline_EX_MEM_regfile_rdata_2(
   .clk    (clk             ),
   .arst_n (arst_n          ),
   .en     (enable          ),
   .din    (regfile_rdata_2_ID_EX),
   .dout   (regfile_rdata_2_EX_MEM)
);

reg_arstn_en #(
   .DATA_W(5)
) Pipeline_EX_MEM_rb( // For the writeback of the address into register (Many mistakes were done here)
   .clk    (clk             ),
   .arst_n (arst_n          ),
   .en     (enable          ),
   .din    (rd_ID_EX),
   .dout   (rd_EX_MEM)
);

// ===========================================================================================================================
//                                                 MEM : Memory
// ===========================================================================================================================


sram_BW64 #( //64 bit here!
   .ADDR_W(10)
) data_memory(
   .clk      (clk            ),
   .addr     (alu_out_EX_MEM  ), // INPUT
   .wen      (mem_write_EX_MEM      ), // INPUT
   .ren      (mem_read_EX_MEM       ), // INPUT
   .wdata    (regfile_rdata_2_EX_MEM), // INPUT
   .rdata    (mem_data       ), // OUTPUT
   .addr_ext (addr_ext_2     ),
   .wen_ext  (wen_ext_2      ),
   .ren_ext  (ren_ext_2      ),
   .wdata_ext(wdata_ext_2    ),
   .rdata_ext(rdata_ext_2    )
);


//----------------------------------------------------------------------------------------------------------------------------
//                                                     MEM/WB
//----------------------------------------------------------------------------------------------------------------------------

reg_arstn_en #(
   .DATA_W(64)
) Pipeline_MEM_WB_mem_data(
   .clk    (clk             ),
   .arst_n (arst_n          ),
   .en     (enable          ),
   .din    (mem_data),
   .dout   (mem_data_MEM_WB)
);

reg_arstn_en #(
   .DATA_W(64)
) Pipeline_MEM_WB_alu_out(
   .clk    (clk             ),
   .arst_n (arst_n          ),
   .en     (enable          ),
   .din    (alu_out_EX_MEM),
   .dout   (alu_out_MEM_WB)
);

reg_arstn_en #(
   .DATA_W(1)
) Pipeline_MEM_WB_mem_2_reg(
   .clk    (clk             ),
   .arst_n (arst_n          ),
   .en     (enable          ),
   .din    (mem_2_reg_EX_MEM),
   .dout   (mem_2_reg_MEM_WB)
);

reg_arstn_en #(
   .DATA_W(5)
) Pipeline_MEM_WB_rb( // For the writeback of the address into register (Many mistakes were done here)
   .clk    (clk             ),
   .arst_n (arst_n          ),
   .en     (enable          ),
   .din    (rd_EX_MEM),
   .dout   (rd_MEM_WB)
);

reg_arstn_en #(
   .DATA_W(1)
) Pipeline_MEM_WB_reg_write( // Typo here
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
   .input_a  (mem_data_MEM_WB),
   .input_b  (alu_out_MEM_WB ),
   .select_a (mem_2_reg_MEM_WB),
   .mux_out  (regfile_wdata)
);

endmodule


