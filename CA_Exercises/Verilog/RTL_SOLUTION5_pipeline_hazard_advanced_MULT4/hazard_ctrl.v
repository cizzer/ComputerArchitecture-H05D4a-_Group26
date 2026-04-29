//Module: Hazard Control 
//Function: Ensures that data hazard is prevented

/*
1) Detects hazard
2) Stalls IF/ID 
3) Inserts Bubble
*/

module hazard_ctrl(
    // We don't need data parameter since the wires are set
    input wire [4:0]   raddr_1,     // First address     
    input wire [4:0]   raddr_2,     // Second address
    input wire         mem_read,    // Controller mem_read (From the ID_EX)
    input wire [4:0]   rd,         // read_dest (Post ID_EX)
    output reg         pc_write,    // If 1 PC advances normally, else PC stays the same
    output reg         if_id_write,// Allows for stalls, basically either new structions goes in (1) or no (0)
    output reg         flush      // Sadly not poker 
);
    // key hazard -> It loads to a register that will be used by a data behind it
    always@(*)begin
        if((mem_read == 1 && rd != 5'd0) && ((rd == raddr_1) || (rd == raddr_2))) begin // Checks if the next command is a mem read and the rd is valid 
            pc_write = 1'b0; // stalls if 0
            if_id_write = 1'b0; // do not accept new instruction
            flush = 1'b1;
        end else begin // default pc_write and if_id_write == 1s
            pc_write = 1'b1;
            if_id_write = 1'b1;
            flush = 1'b0;
        end

    end 

endmodule

