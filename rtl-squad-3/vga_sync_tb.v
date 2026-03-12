`timescale 1ps/1ps
`include "vga_top.v"

module vga_sync_tb();
    
    reg clk = 0;
    reg reset = 1;
    wire hsync, vsync;
    wire botao_cor_tela, botao_cor_quadrado, botao_modo;
    wire [3:0] R, G, B;

    localparam clock_esperado = 25.175;
   
    vga_top uut (
        .clk(clk),
        .reset(reset),
        .botao_cor_tela(botao_cor_tela),
        .botao_cor_quadrado(botao_cor_quadrado),
        .botao_modo(botao_modo),
        .hsync(hsync),
        .vsync(vsync),
        .R(R),
        .G(G),
        .B(B)
    );

    // 25.175 MHz
    always #19860 clk = ~clk;

    // função que calcula o valor absoluto
    function real abs_real(input real val);
        begin
            abs_real = (val < 0.0) ? -val : val;
        end
    endfunction

    // Inicio da Task check_vesa_clock
    task Teste_vesa_clock;
        real periodo, frequencia, erro;    // variaveis de calculo 
        time t1, t2;       // sinais de tempo                         
    begin
        $display("\n==== Teste CLOCK VESA ====");

        @(posedge clk); t1 = $time; // tempo de uma primeira borda de subida do clock
        @(posedge clk); t2 = $time; // tempo da próxima borda de subida do clock
        periodo = t2 - t1;             
        frequencia = 1_000_000.0 / periodo; //caculo da frequencia MHz
        erro = ((frequencia- 25.175) / 25.175) * 100.0; // margem de erro

        $display("Pixel clock: %f MHz | Erro: %0.3f%% | %s", 
            frequencia, abs_real(erro), (abs_real(erro) <= 0.5) ? "[OK]" : "[FORA]");
    end
    endtask
    // ----------------- Calculo dos parametros Horizontais  ---------------------
   //teste Hsynk
    task Teste_vesa_Hsynk;
        real erro, tempo_hsync;
        time t1, t2;                                
    begin
        $display("\n==== Tempo Hsynk VESA ====");

        @(negedge hsync); t1 = $time; // tempo decida hsynk
        @(posedge hsync); t2 = $time; // tempo subida hsink
        
        tempo_hsync = (t2 - t1)/1000.0;//ps para ns
        erro = ((tempo_hsync - 3813.12) / 3813.12) * 100.0;//calculo do erro

        $display("Tempo Hsynk: %f ns | Erro: %0.3f%% | %s",
            tempo_hsync,abs_real(erro),(abs_real(erro) <= 0.5) ? "[OK]" : "[FORA]");
    end
    endtask

    //teste H Front
     task Teste_vesa_H_Front_Porch;
        real erro, Front_Porch;   // variaveis de calculo 
        time t1, t2;             // sinais de tempo
    begin
        $display("\n==== Front_Porch H VESA ====");

        wait(uut.sync_inst.pixel_x == 640);// aguarda o pixel 640
           t1 = $time; //tempo pixel 640

        @(negedge hsync); t2 = $time; // tempo sinal hsync
        Front_Porch = t2 - t1;             //Front Porch
        Front_Porch = Front_Porch/1000;//ps para ns
        erro = ((Front_Porch - 635.520) / 635.520) * 100.0; // margem de erro

        $display("Front_Porch H: %f ns | Erro: %0.3f%% | %s", 
            Front_Porch, abs_real(erro), (abs_real(erro) <= 0.5) ? "[OK]" : "[FORA]");
    end
    endtask

    //teste H back
    task Teste_vesa_H_Back_Porch;
        real erro, Back_Porch;   // variaveis de calculo 
        time t1, t2;            // sinais de tempo
    begin
        $display("\n==== Back_Porch H VESA ====");

        @(posedge hsync); t1 = $time; // tempo sinal hsync

        wait(uut.sync_inst.h_count == 0);
        @(posedge clk); t2 = $time; // tempo da próxima borda de subida do clock
      
        Back_Porch = t2 - t1;             //Back Porch
        Back_Porch = Back_Porch/1000;//ps para ns
        erro = ((Back_Porch - 1906.56) / 1906.56) * 100.0; // margem de erro
        
        $display("Back_Porch H: %f ns | Erro: %0.3f%% | %s", 
            Back_Porch, abs_real(erro), (abs_real(erro) <= 0.5) ? "[OK]" : "[FORA]");
    end
    endtask
    //teste H Visible
    task Teste_H_VISIBLE;
        time t1, t2;  // sinais de tempo
        real tempo, erro; // variaveis de calculo 
    begin
        $display("\n==== Tempo H_VISIBLE VESA ====");

        // Espera início da linha visível
        wait (uut.sync_inst.h_count == 0); 
        @(posedge clk);
        t1 = $time;

        // Espera fim da área visível
        wait (uut.sync_inst.h_count == 640);
        @(posedge clk);
        t2 = $time;

        tempo = (t2 - t1) / 1000.0;//ps para ns
        erro = ((tempo - 25420.8) / 25420.8) * 100.0;
        $display("Tempo H_VISIBLE: %f ns | Erro: %0.3f%% | %s",
            tempo,abs_real(erro),(abs_real(erro) <= 0.5) ? "[OK]" : "[FORA]");
    end
    endtask

    //teste H total
     task Teste_H_TOTAL;
        time t1, t2;        // sinais de tempo
        real tempo, erro;   // variaveis de calculo 
    begin
        $display("\n==== Tempo H_TOTAL VESA ====");
        

        // Espera início da linha visível
        wait (uut.sync_inst.h_count == 0); 
        @(posedge clk);
        t1 = $time;
        //Espera a contagem da linha
        wait (uut.sync_inst.h_count != 0);
        // Espera fim da área visível
        wait (uut.sync_inst.h_count == 0);
        @(posedge clk);
        t2 = $time;

        tempo = (t2 - t1) / 1000000.0;//ps para ns
        erro = ((tempo - 31.776) / 31.776) * 100.0;
        $display("Tempo H_Total: %f ns | Erro: %0.3f%% | %s",
            tempo,abs_real(erro),(abs_real(erro) <= 0.5) ? "[OK]" : "[FORA]");
    end
    endtask
    // ----------------- Calculo dos parametros Verticais  ---------------------
    //teste V Front
     task Teste_vesa_V_Front_Porch;
        real erro, Front_Porch;   // variaveis de calculo 
        time t1, t2;              // sinais de tempo
    begin
        $display("\n==== Front_Porch V VESA ====");
        
        wait(uut.sync_inst.pixel_y == 480);  // fim área ativa
            t1 = $time;
        @(negedge vsync); t2 = $time; // tempo da próxima borda de subida do v sync
        Front_Porch = t2 - t1;         //Front Porch
        Front_Porch = Front_Porch/1000000;//ps para ms
        erro = ((Front_Porch - 317.780) / 317.780) * 100.0; // margem de erro  
  
        $display("Front_Porch V: %f ms | Erro: %0.3f%% | %s", 
            Front_Porch, abs_real(erro), (abs_real(erro) <= 0.5) ? "[OK]" : "[FORA]");
    end
    
    endtask
    
     //teste V back
    task Teste_vesa_V_Back_Porch;
        real erro, Back_Porch;   // variaveis de calculo 
        time t1, t2;             // sinais de tempo
    begin
        $display("\n==== Back_Porch V VESA ====");

        @(posedge vsync); t1 = $time; // tempo de uma primeira borda de subida do clock
         

        @(posedge uut.sync_inst.display); t2 = $time; // tempo da próxima borda de subida do clock
        Back_Porch = t2 - t1;             //Back Porch
        Back_Porch = Back_Porch/1000000;//ps para ms
        erro = ((Back_Porch - 1048.67) / 1048.67) * 100.0; // margem de erro
        
        $display("Back_Porch V: %f ns | Erro: %0.3f%% | %s", 
            Back_Porch, abs_real(erro), (abs_real(erro) <= 0.5) ? "[OK]" : "[FORA]");
    end
    endtask

    //teste Vsynk
    task Teste_vesa_Vsynk;
        real erro, tempo_vsync; // variaveis de calculo 
        time t1, t2;  // sinais de tempo
    
     begin                             
        $display("\n==== Tempo Vsynk VESA ====");

        @(negedge vsync); t1 = $time; // tempo decida vsynk
        @(posedge vsync); t2 = $time; // tempo subida vsynk
        
        tempo_vsync = (t2 - t1)/1_000_000.0; // ps para ms
        erro = ((tempo_vsync - 63.552) / 63.552) * 100.0;

        $display("Tempo Vsynk: %f ms | Erro: %0.3f%% | %s", 
            vsync, abs_real(erro), (abs_real(erro) <= 0.5) ? "[OK]" : "[FORA]");

    end
    endtask

    //teste V visible

     task Teste_V_VISIBLE;
        time t1, t2;    // sinais de tempo
        real tempo, erro; // variaveis de calculo
    begin
        $display("\n==== Tempo V_VISIBLE VESA ====");
        
        // Espera início da linha visível
        wait (uut.sync_inst.v_count == 0); 
        @(posedge clk);
        t1 = $time;

        // Espera fim da área visível
        wait (uut.sync_inst.v_count == 480);
        @(posedge clk);
        t2 = $time;

        tempo = (t2 - t1)/1_000_000.0; //ps para ms
        erro = ((tempo - 15253.44) / 15253.44) * 100.0;

        
        $display("Tempo V_VISIBLE: %f ms | Erro: %0.3f%% | %s",
            tempo,abs_real(erro),(abs_real(erro) <= 0.5) ? "[OK]" : "[FORA]");
    end
    endtask
    // teste V total
     task Teste_V_TOTAL;
        time t1, t2;  // sinais de tempo
        real tempo, erro; // variaveis de calculo
    begin
        $display("\n==== Tempo V_TOTAL VESA ====");
        

        // Espera início da linha visível
        wait (uut.sync_inst.v_count == 0); 
        @(posedge clk);
        t1 = $time;
        wait (uut.sync_inst.v_count != 0);
        // Espera fim da área visível
        wait (uut.sync_inst.v_count == 0);
        @(posedge clk);
        t2 = $time;

        tempo = (t2 - t1) / 1_000_000.0;//ps para ms
        erro = ((tempo - 16683.45) / 16683.45) * 100.0;
        $display("Tempo V_Total: %f ms | Erro: %0.3f%% | %s",
            tempo,abs_real(erro),(abs_real(erro) <= 0.5) ? "[OK]" : "[FORA]");
    end
    endtask

     // Inicialização do Sistema
    task init_system;
    begin
         reset = 1;
         #1000;
         reset = 0;
         repeat(1000) @(posedge clk);
    end
    endtask

    //Chamada das funçoes

    initial begin
        init_system();
        Teste_vesa_clock();

        //H
        Teste_H_VISIBLE();
        Teste_vesa_H_Front_Porch();
        Teste_vesa_Hsynk();
        Teste_vesa_H_Back_Porch();
        Teste_H_TOTAL();

        //V
        Teste_V_VISIBLE();
        Teste_vesa_V_Front_Porch();
        Teste_vesa_Vsynk();
        Teste_vesa_V_Back_Porch();
        Teste_V_TOTAL();
 
        #40000000; 
        $finish;
    end
endmodule