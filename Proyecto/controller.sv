module controller(input  logic         clk, reset,
						input  logic [31:12] Instr,
						input  logic [3:0]   ALUFlags,
						output logic [1:0]   RegSrc,
						output logic         RegWrite,
						output logic [1:0]   ImmSrc,
						output logic         ALUSrc,
						output logic [1:0]   ALUControl,
						output logic         MemWrite, MemtoReg,
						output logic         PCSrc);
						
	logic [2:0] FlagW;
	logic       PCS, RegW, MemW;
	logic       NoWrite;
	
	decoder dec(Instr[27:26], Instr[25:20], Instr[15:12],
					FlagW, PCS, RegW, MemW,
					MemtoReg, ALUSrc, ImmSrc, RegSrc, ALUControl);
					
	assign NoWrite = (Instr[24:21] == 4'b1010) & Instr[20];
					
	condlogic cl(clk, reset, Instr[31:28], ALUFlags,
					 FlagW, PCS, RegW & ~NoWrite, MemW,
					 PCSrc, RegWrite, MemWrite);
endmodule