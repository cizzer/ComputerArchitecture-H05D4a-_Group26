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