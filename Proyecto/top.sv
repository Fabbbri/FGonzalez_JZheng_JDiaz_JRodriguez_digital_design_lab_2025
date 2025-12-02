module top(
    input  logic        clk, reset,
	 input  logic [3:0]  switches_num1,
    input  logic [3:0]  switches_num2,
    input  logic [1:0]  switches_op,
	 output logic [6:0]  HEX0,           // Display para resultado (unidades)
    output logic [6:0]  HEX1,           // Display para resultado (decenas)
    output logic [6:0]  HEX2,           // Display para num1
    output logic [6:0]  HEX3,           // Display para num2
    output logic [6:0]  HEX4,           // Display para operación
	 output logic [9:0]  LEDR
);

    logic [31:0] PC, Instr, ReadData, WriteData, DataAdr;
	 logic [31:0] RAMReadData;
	 logic        MemWrite;
    logic [31:0] result_reg;

    // instantiate processor and memories
    arm arm  (clk, reset, PC, Instr, MemWrite, DataAdr, WriteData, ReadData);
    rom rom  (PC[9:2], clk, Instr);
	 ram ram (DataAdr[9:2], clk, WriteData, MemWrite && (DataAdr < 32'h00000100), RAMReadData);
	 
	 always_comb begin
        // Direcciones de I/O
        case (DataAdr)
            32'h00000100: ReadData = {28'b0, switches_num1}; // Dirección 0x100
            32'h00000104: ReadData = {28'b0, switches_num2}; // Dirección 0x104
            32'h00000108: ReadData = {30'b0, switches_op};   // Dirección 0x108
				32'h00000200: ReadData = result_reg; 
            default:      ReadData = RAMReadData;              // RAM normal
        endcase
    end
	 
	 always_ff @(posedge clk or posedge reset) begin
        if (reset)
            result_reg <= 32'b0;
        else if (MemWrite && DataAdr == 32'h00000200)
            result_reg <= WriteData;
    end
	 
	 hex_7seg display_result_units(
        .hex(result_reg[3:0]),
        .seg(HEX0)
    );
    
    // Display para resultado (decenas) - solo si resultado > 15
    hex_7seg display_result_tens(
        .hex(result_reg[7:4]),
        .seg(HEX1)
    );
    
    // Display para número 1
    hex_7seg display_num1(
        .hex(switches_num1),
        .seg(HEX2)
    );
    
    // Display para número 2
    hex_7seg display_num2(
        .hex(switches_num2),
        .seg(HEX3)
    );
    
    // Display para operación
    operation_display display_op(
        .op(switches_op),
        .seg(HEX4)
    );

endmodule
