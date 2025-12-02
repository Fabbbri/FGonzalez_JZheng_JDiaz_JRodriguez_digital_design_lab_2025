// Testbench simplificado para Quartus
// Compatible con ModelSim-Altera

`timescale 1ns / 1ps

module testbench();
    
    // Señales del DUT
    logic        clk;
    logic        reset;
    logic [31:0] WriteData, DataAdr;
    logic        MemWrite;
    
    // Contadores
    integer cycle_count = 0;
    integer instr_count = 0;
    
    // Instantiate device under test
    top dut(clk, reset, WriteData, DataAdr, MemWrite);
    
    // Inicializar memoria de datos
    initial begin
        #1; // Pequeño delay
    end
    
    // Reset inicial
    initial begin
        reset = 1;
        #22;
        reset = 0;
    end
    
    // Generador de reloj - 10ns de periodo (100MHz)
    always begin
        clk = 0;
        #5;
        clk = 1;
        #5;
    end
    
    // Monitor simple de ciclos
    always @(posedge clk) begin
        if (!reset) begin
            cycle_count = cycle_count + 1;
        end
    end
    
    // Monitor de escrituras en memoria
    always @(negedge clk) begin
        if (MemWrite && !reset) begin
            $display("Time=%0t: STORE to Addr=0x%h, Data=0x%h", 
                     $time, DataAdr, WriteData);
        end
    end
    
    // Detener después de 200 ciclos
    initial begin
        #2000; // 200 ciclos * 10ns
        $display("\n========================================");
        $display("Simulación completada");
        $display("Ciclos ejecutados: %0d", cycle_count);
        $display("========================================");

		 
        $stop;
    end
    
endmodule