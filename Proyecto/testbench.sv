`timescale 1ns / 1ps

module testbench();
    
    // Señales del procesador ARM
    logic        clk;
    logic        reset;
    logic [31:0] PC;
    logic [31:0] Instr;
    logic        MemWrite;
    logic [31:0] ALUResult, WriteData;
    logic [31:0] ReadData;
    
    // Memorias
    logic [31:0] ROM[63:0];
    logic [31:0] RAM[63:0];
    
    // Variables de simulación
    integer cycle_count = 0;
    integer test_num = 0;
    
    // Instanciar el procesador ARM
    arm dut(
        .clk(clk),
        .reset(reset),
        .PC(PC),
        .Instr(Instr),
        .MemWrite(MemWrite),
        .ALUResult(ALUResult),
        .WriteData(WriteData),
        .ReadData(ReadData)
    );
    
    // Inicializar ROM con el programa
    initial begin
        ROM[0]  = 32'hE3A08C01;  // MOV r8, #0x100
        ROM[1]  = 32'hE5980000;  // LDR r0, [r8, #0]   - Lee num1
        ROM[2]  = 32'hE5981004;  // LDR r1, [r8, #4]   - Lee num2
        ROM[3]  = 32'hE5982008;  // LDR r2, [r8, #8]   - Lee operación
        ROM[4]  = 32'hE3520000;  // CMP r2, #0
        ROM[5]  = 32'h0A000004;  // BEQ add_op
        ROM[6]  = 32'hE3520001;  // CMP r2, #1
        ROM[7]  = 32'h0A000004;  // BEQ sub_op
        ROM[8]  = 32'hE3520002;  // CMP r2, #2
        ROM[9]  = 32'h0A000004;  // BEQ and_op
        ROM[10] = 32'hEA000004;  // B orr_op
        ROM[11] = 32'hE0803001;  // ADD r3, r0, r1
        ROM[12] = 32'hEA000003;  // B store_result
        ROM[13] = 32'hE0403001;  // SUB r3, r0, r1
        ROM[14] = 32'hEA000001;  // B store_result
        ROM[15] = 32'hE0003001;  // AND r3, r0, r1
        ROM[16] = 32'hEA000000;  // B store_result
        ROM[17] = 32'hE1803001;  // ORR r3, r0, r1
        ROM[18] = 32'hE3A09C02;  // MOV r9, #0x200
        ROM[19] = 32'hE5893000;  // STR r3, [r9, #0]
        ROM[20] = 32'hEAFFFFF1;  // B loop (vuelve a dirección 1)
        
        // Resto de memoria en 0
        for (int i = 21; i < 64; i = i + 1) begin
            ROM[i] = 32'h00000000;
        end
        
        // Inicializar RAM
        for (int i = 0; i < 64; i = i + 1) begin
            RAM[i] = 32'h00000000;
        end
    end
    
    // Memoria ROM (instrucciones)
    assign Instr = ROM[PC[31:2]];
    
    // Lógica de memoria (simulando el comportamiento de top.sv)
    always_comb begin
        case (ALUResult)
            32'h00000100: ReadData = RAM[0];  // num1
            32'h00000104: ReadData = RAM[1];  // num2
            32'h00000108: ReadData = RAM[2];  // operación
            32'h00000200: ReadData = RAM[64]; // resultado
            default:      ReadData = RAM[ALUResult[31:2]];
        endcase
    end
    
    // Escritura en memoria
    always_ff @(posedge clk) begin
        if (MemWrite) begin
            if (ALUResult == 32'h00000200) begin
                RAM[64] <= WriteData;  // Guardar resultado
                $display("  → Resultado calculado: %0d (0x%h)", WriteData, WriteData);
            end else if (ALUResult < 32'h00000100) begin
                RAM[ALUResult[31:2]] <= WriteData;
            end
        end
    end
    
    // Generador de reloj - 10ns periodo
    always begin
        clk = 0;
        #5;
        clk = 1;
        #5;
    end
    
    // Contador de ciclos
    always @(posedge clk) begin
        if (!reset) cycle_count = cycle_count + 1;
    end
    
    // Tarea para ejecutar un test
    task ejecutar_test;
        input [31:0] num1;
        input [31:0] num2;
        input [31:0] op;
        input [31:0] resultado_esperado;
        input string operacion_str;
        
        integer ciclos_esperados;
        integer resultado_obtenido;
        
        begin
            test_num = test_num + 1;
            
            $display("\n========================================");
            $display("TEST %0d: %0d %s %0d", test_num, num1, operacion_str, num2);
            $display("========================================");
            
            // Configurar entradas en memoria
            RAM[0] = num1;
            RAM[1] = num2;
            RAM[2] = op;
            RAM[64] = 32'hFFFFFFFF;  // Valor inicial para detectar cambio
            
            $display("Entradas configuradas:");
            $display("  RAM[0x100] = %0d (num1)", num1);
            $display("  RAM[0x104] = %0d (num2)", num2);
            $display("  RAM[0x108] = %0d (op)", op);
            
            // Reset
            reset = 1;
            repeat(3) @(posedge clk);
            reset = 0;
            
            // Esperar a que se escriba el resultado
            ciclos_esperados = 0;
            while (RAM[64] == 32'hFFFFFFFF && ciclos_esperados < 100) begin
                @(posedge clk);
                ciclos_esperados = ciclos_esperados + 1;
            end
            
            // Dar unos ciclos más para estabilizar
            repeat(5) @(posedge clk);
            
            resultado_obtenido = RAM[64];
            
            $display("\nResultados:");
            $display("  Esperado: %0d", resultado_esperado);
            $display("  Obtenido: %0d", resultado_obtenido);
            $display("  Ciclos ejecutados: %0d", ciclos_esperados);
            
            // Verificar
            if (resultado_obtenido == resultado_esperado) begin
                $display("  ✓ TEST PASADO");
            end else begin
                $display("  ✗ TEST FALLADO");
            end
        end
    endtask
    
    // Secuencia de pruebas
    initial begin
        $display("\n╔════════════════════════════════════════╗");
        $display("║  TESTBENCH - PROGRAMA CALCULADORA ARM  ║");
        $display("╚════════════════════════════════════════╝\n");
        
        // Reset inicial
        reset = 1;
        #50;
        reset = 0;
        #20;
        
        // ===== TESTS DE SUMA (op = 0) =====
        ejecutar_test(5, 3, 0, 8, "ADD");
        ejecutar_test(9, 7, 0, 16, "ADD");
        ejecutar_test(15, 15, 0, 30, "ADD");
        ejecutar_test(0, 5, 0, 5, "ADD");
        
        // ===== TESTS DE RESTA (op = 1) =====
        ejecutar_test(10, 3, 1, 7, "SUB");
        ejecutar_test(15, 7, 1, 8, "SUB");
        ejecutar_test(5, 5, 1, 0, "SUB");
        
        // ===== TESTS DE AND (op = 2) =====
        ejecutar_test(15, 7, 2, 7, "AND");
        ejecutar_test(12, 10, 2, 8, "AND");
        ejecutar_test(0, 15, 2, 0, "AND");
        
        // ===== TESTS DE ORR (op = 3) =====
        ejecutar_test(5, 3, 3, 7, "ORR");
        ejecutar_test(12, 3, 3, 15, "ORR");
        ejecutar_test(0, 15, 3, 15, "ORR");
        ejecutar_test(8, 4, 3, 12, "ORR");
        
        $stop;
    end
    
    // Timeout
    initial begin
        #20000;
        $display("\n⚠ TIMEOUT");
        $stop;
    end
    
endmodule