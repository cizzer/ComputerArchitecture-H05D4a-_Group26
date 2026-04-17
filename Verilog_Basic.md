This is a recap note for Verilog

# HDL (Hardware Description Language)

* Essentially describing hardware using a language 
* Specialized, text-based computer language used to design, model, and simulate digital systems (like FPGAs or ASICs)
* FPGA -> A field-programmable gate array (FPGA) is a type of configurable integrated circuit that can be repeatedly programmed after manufacturing.
* ASIC -> An Application-Specific Integrated Circuit
* Key idea -> Simulation => Inputs applied to the circuit
* Key idea II -> Synthesis => the automated process of converting high-level, human-readable code (like Verilog or VHDL) into a low-level, gate-level netlist (machine readable text file that defines the electronic circuit components) of logic gates and flip-flops
* Note the HDL is not programming language -> Its just describing the behaviour of the Hardware -> "What hardware do you expect"

Types of Module :
1) Behavioral module -> Describe what it does 
2) Structural Module -> Describe how its built 

## Example Verilog

'''
module example (input logic a, b, c,
                output logic y);
    //module body goes here
end module
'''

module/endmodule : required to begin/end module
example : name of the module
OPerators:
    ~ : NOT
    & : AND
    | : OR
    ^ : XOR
    ~ (a & b) : NAND
    ~ (a | b) : NOR
    &a : reduction opeartor
    ? : Ternary operator => Basically if else operation 
    
basically you can then see the waveform from this following data

* Note that the synthesis module is what turns the whole shabang into the gates itself

IMPORTANT NOTES:
* Verilog is case sensitive
* Nonames can start with numbers
* Whitespace is ignored
* Comments // single line /* */ multiline comment

note that inputy is always in the left and y is always in the right, a component can have multiple module
Instance name and module name is different 

# Describing Combinatorial logic with operators

input logic[3:0] just means that there is 4 bit input logic for a given input

recall that any instruction must be decoded into binary and the arrangement of the binary is dictated by the RISC-V architecture card

Session 1 -> Done, adjust the ALU and the ALU controller to get the new multiply function, always crosscheck with the RISCV
Session 2:
1) Obj-1 RTL sol3 pipeline mult 2
    * Get it to pipeline -> Inserting pipeline registers
    * Seperate the signals between the stages
    * Introduce pipeline registers to cpu.v
2) Obj-2 RTL sol4 hazard mult 3 


Recall that for the case of compoennts within CPU

module_name #( 
   .PARAM_NAME(value)
) instance_name(
   .port_name(signal_name),
   .another_port(another_signal)
);

in which:
1) Module name == Hardware block you are writing to
2) #(...) == Instantiate this module, but set its parameter(s) to these values
3) instance_name == the name of this specific copy of the module.
4) .port_name(signal_name) == This is named port connection syntax.

Note that port name refers to itself and the signal name is the external wire that connects to it

Also note that because then our data memory would only read/write 32 bits at a time and   CPU registers and ALU expect 64-bit values.

Pro tip : the book chapter 4 294 is literally the answer for session 2

also reg_arstn ==> always want the register to move forward every clock 
and reg_arst_en if you want  to pause the register (Use this one pre data hazard)

Note that in the modules the data_w = 16 is a declaration of parameters, default setting 

in the CPU the TA use .DATA_W cuz override

also data_w-1:0 means you need to know thw data_W before hand 

also also you pipeline the output of the control!


// QNA

1) .waddr(instruction_IF_ID[11:7]) // the destination register of whatever instruction is currently in ID, not the destination register of the instruction that is currently finishing WB. meaning that A few cycles later, when instruction 1 reaches WB, the ID stage might already be looking at instruction 3. so we still have to pipeline it  
2) Why pipeline control signals like jump, branch, reg_write, mem_read, mem_write, mem_2_reg that goes back? 
    * “because they are from the later stage going back doesn’t require for it to be pipelined”
    * They are decided in ID, but used later.

A control signal must be pipelined until the stage where it is actually used.

Read ports

Belong to ID

raddr_1
raddr_2
rdata_1
rdata_2
Write port

Belongs to WB

waddr
wdata
reg_write

That is why reg_write must be pipelined all the way to WB.