module operation_display(
    input  logic [1:0] op,
    output logic [6:0] seg
);
    always_comb begin
        case (op)
            2'b00: seg = 7'b0001000; // A (ADD)
            2'b01: seg = 7'b0010010; // S (SUB)
            2'b10: seg = 7'b1000000; // & (AND) - mostrar como "0"
            2'b11: seg = 7'b1000000; // | (ORR) - mostrar como "0"
            default: seg = 7'b1111111; // Apagado
        endcase
    end
endmodule