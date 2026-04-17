//Module: fw_unit
//Function: Decide to forward Alu result

/*
It needs to decied whether it should use the normal register value or 
should I get the value from the later stages if both reg_write and destiation is ready then take
1) From Register
2) From ALU
3) From MEM/WB
*/

module fw_unit(
    // We don't need data parameter since the wires are set
    input  wire [4:0]   raddr_1_ID_EX,    // Source register number 1 [19:15]
    input  wire [4:0]   raddr_2_ID_EX,    // Source register number 1 [24:20]
    input  wire         reg_write_EX_MEM,     // Controller settings
    input  wire         reg_write_MEM_WB,     // Controller settings
    input  wire [4:0]   rd_EX_MEM,  // register read > Destination register number @ EX/MEM (5bit)
    input  wire [4:0]   rd_MEM_WB,  // register read > Destination register number @ MEM/WB (5bit)
    output reg  [1:0]   forwardA,   // 1 or 0 based on the given command must be a 2 bit output
    output reg  [1:0]   forwardB   // 1 or 0 based on the given command must be a 2 bit output
);

   // Goal is to decide whether to forward the data from a later pipeline stage or not

   always@(*)begin // Forward A
    if((reg_write_EX_MEM && rd_EX_MEM != 5'b0) && (rd_EX_MEM == raddr_1_ID_EX)) begin
        forwardA = 2'b10; // Take from ALU
    end else if((reg_write_MEM_WB && rd_MEM_WB != 5'b0) && (rd_MEM_WB == raddr_1_ID_EX)) begin
        forwardA = 2'b01; // Take from MEM
    end else begin
        forwardA = 2'b00; // Take from register (Else case)
    end
    end

    // Pro tip, since the input is a 5 bit register then we should also compare it with a 5 bit value

    always@(*)begin // Forward B
    if((reg_write_EX_MEM && rd_EX_MEM != 5'b0) && (rd_EX_MEM == raddr_2_ID_EX)) begin
        forwardB = 2'b10; // Take from ALU
    end else if((reg_write_MEM_WB && rd_MEM_WB != 5'b0) && (rd_MEM_WB == raddr_2_ID_EX)) begin
        forwardB = 2'b01; // Take from MEM
    end else begin
        forwardB = 2'b00; // Take from register (Else case)
    end
    end

endmodule

