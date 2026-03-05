module vga_display                                               
(
    input  wire        clk,                                          // Clock de 25 MHz (pixel clock do VGA)
    input  wire        reset,                                        // Reset assíncrono do sistema
    input  wire [9:0]  hsinc,                                        // Coordenada horizontal atual (0–799 incluindo porches)
    input  wire [9:0]  vsinc,                                        // Coordenada vertical atual (0–524 incluindo porches)
    input  wire        area_visivel,                                 // Indica se estamos dentro da área visível (640x480)

    input  wire        botao_cor_tela,                               // Botão para alternar a cor do fundo
    input  wire        botao_cor_quadrado,                           // Botão para alternar a cor do quadrado
    input  wire        botao_modo,                                   // Botão para alternar o modo da FSM

    output reg  [3:0]  R,                                            // Saída do canal vermelho (4 bits)
    output reg  [3:0]  G,                                            // Saída do canal verde (4 bits)
    output reg  [3:0]  B                                             // Saída do canal azul (4 bits)
);

    parameter largura_de_tela     = 640;                             // Largura da área visível
    parameter altura_de_tela      = 480;                             // Altura da área visível
    parameter tamanho_do_quadrado = 50;                              // Tamanho do quadrado móvel

    parameter modo_quadrado = 2'd0;                                  // Estado 0 → Exibe quadrado móvel
    parameter modo_mira     = 2'd1;                                  // Estado 1 → Exibe mira central
    parameter modo_xadrez  = 2'd2;                                   // Estado 2 → Exibe padrão xadrez

    reg [1:0] modo_atual;                                            // Registrador que armazena o estado atual

    reg bt_m1;                                                       // Primeiro flip-flop de sincronização do botão modo
    reg bt_m2;                                                       // Segundo flip-flop de sincronização do botão modo
    wire bt_m_subida;                                                // Pulso de borda de subida do botão modo

    reg [9:0] pos_hsinc;                                             // Posição horizontal atual do quadrado
    reg [9:0] pos_vsinc;                                             // Posição vertical atual do quadrado

    reg signed [3:0] vel_hsinc;                                      // Velocidade horizontal (-8 a +7)
    reg signed [3:0] vel_vsinc;                                      // Velocidade vertical (-8 a +7)

    reg [1:0] cor_quadrado;                                          // Seleção de cor do quadrado (0 a 3)
    reg [1:0] cor_fundo_tela;                                        // Seleção de cor do fundo (0 a 3)

    reg bt_f1;                                                       // Primeiro flip-flop botão fundo
    reg bt_f2;                                                       // Segundo flip-flop botão fundo
    reg bt_q1;                                                       // Primeiro flip-flop botão quadrado
    reg bt_q2;                                                       // Segundo flip-flop botão quadrado

    wire bt_f_subida;                                                // Detecta borda de subida botão fundo
    wire bt_q_subida;                                                // Detecta borda de subida botão quadrado

    always @(posedge clk)                                            // Sincroniza todos os botões ao clock
    begin
        bt_f1 <= botao_cor_tela;                                     // Primeiro estágio botão fundo
        bt_f2 <= bt_f1;                                              // Segundo estágio botão fundo

        bt_q1 <= botao_cor_quadrado;                                 // Primeiro estágio botão quadrado
        bt_q2 <= bt_q1;                                              // Segundo estágio botão quadrado

        bt_m1 <= botao_modo;                                         // Primeiro estágio botão modo
        bt_m2 <= bt_m1;                                              // Segundo estágio botão modo
    end

    assign bt_f_subida = bt_f1 & ~bt_f2;                             // Gera pulso de 1 clock na borda de subida fundo
    assign bt_q_subida = bt_q1 & ~bt_q2;                             // Gera pulso de 1 clock na borda de subida quadrado
    assign bt_m_subida = bt_m1 & ~bt_m2;                             // Gera pulso de 1 clock na borda de subida modo

    wire fim_frame;                                                  // Indica último pixel do frame completo
    assign fim_frame = (hsinc == 10'd799) && (vsinc == 10'd524);     // Ativo no último pixel incluindo porches

    wire dentro_horizontal;                                          // Verifica se pixel está dentro da faixa horizontal
    assign dentro_horizontal =
        (hsinc >= pos_hsinc) &&                                      // Pixel maior ou igual à borda esquerda
        (hsinc <  pos_hsinc + tamanho_do_quadrado);                  // Pixel menor que borda direita

    wire dentro_vertical;                                            // Verifica se pixel está dentro da faixa vertical
    assign dentro_vertical =
        (vsinc >= pos_vsinc) &&                                      // Pixel maior ou igual à borda superior
        (vsinc <  pos_vsinc + tamanho_do_quadrado);                  // Pixel menor que borda inferior

    wire formacao_quadrado;                                          // Indica se pixel pertence ao quadrado
    assign formacao_quadrado = dentro_horizontal && dentro_vertical; // AND lógico das duas direções

    always @(posedge clk or posedge reset)                           // Bloco síncrono com reset assíncrono
    begin
        if (reset== 1'b1)                                            // Se reset ativado
        begin
            pos_hsinc      <= 10'd200;                               // Inicializa posição horizontal
            pos_vsinc      <= 10'd150;                               // Inicializa posição vertical
            vel_hsinc      <= 4'sd1;                                 // Velocidade inicial horizontal
            vel_vsinc      <= 4'sd1;                                 // Velocidade inicial vertical
            cor_quadrado   <= 2'd0;                                  // Cor inicial quadrado
            cor_fundo_tela <= 2'd0;                                  // Cor inicial fundo
            modo_atual     <= modo_quadrado;                         // Estado inicial da FSM

            R <= 0;                                                  // Inicializa canal vermelho
            G <= 0;                                                  // Inicializa canal verde
            B <= 0;                                                  // Inicializa canal azul
        end
        else                                                         
        begin

            if (bt_m_subida== 1'b1)                                   // Se botão modo pressionado
            begin
                if (modo_atual == modo_xadrez)                       // Se estiver no último modo
                    modo_atual <=modo_quadrado;                     // Retorna ao primeiro
                else
                    modo_atual <= modo_atual + 1'b1;               // Avança para próximo modo
            end

            if (fim_frame == 1'b1)                                    // Atualiza apenas no fim do frame
            begin
                pos_hsinc <= pos_hsinc + vel_hsinc;                  // Atualiza posição horizontal
                pos_vsinc <= pos_vsinc + vel_vsinc;                  // Atualiza posição vertical

                if (pos_hsinc <= 0)                                  // Colisão borda esquerda
                    vel_hsinc <= 4'sd1;                              // Inverte para direita
                else if (pos_hsinc + tamanho_do_quadrado >= largura_de_tela)
                    vel_hsinc <= -4'sd1;                             // Inverte para esquerda

                if (pos_vsinc <= 0)                                  // Colisão borda superior
                    vel_vsinc <= 4'sd1;                              // Inverte para baixo
                else if (pos_vsinc + tamanho_do_quadrado >= altura_de_tela)
                    vel_vsinc <= -4'sd1;                             // Inverte para cima
            end



            if (bt_f_subida== 1'b1)                                         // Se botão fundo pressionado
                cor_fundo_tela <= cor_fundo_tela + 1'b1;             // Incrementa seleção

            if (bt_q_subida== 1'b1)                                         // Se botão quadrado pressionado
                cor_quadrado <= cor_quadrado + 1'b1;                 // Incrementa seleção



            if (area_visivel == 1'b0)                                       // Fora da área visível
            begin
                R <= 0;                                              // Preto
                G <= 0;                                              // Preto
                B <= 0;                                              // Preto
            end
            else
            begin
                case (modo_atual)                                    // Seleciona comportamento por estado

                    modo_quadrado:                                   // Estado quadrado
                    begin
                        if (formacao_quadrado== 1'b1)                       // Se pixel pertence ao quadrado
                        begin
                            case (cor_quadrado)                      // Seleciona cor
                                2'd0: begin R <= 4'hF; G <= 0;    B <= 0;    end
                                2'd1: begin R <= 0;    G <= 4'hF; B <= 0;    end
                                2'd2: begin R <= 0;    G <= 0;    B <= 4'hF; end
                                2'd3: begin R <= 4'hF; G <= 4'hF; B <= 0;    end
                            endcase
                        end
                        else
                        begin
                            case (cor_fundo_tela)                    // Cor do fundo
                                2'd0: begin R <= 0;    G <= 0;    B <= 0;    end
                                2'd1: begin R <= 0;    G <= 4'hF; B <= 4'hF; end
                                2'd2: begin R <= 4'hF; G <= 0;    B <= 4'hF; end
                                2'd3: begin R <= 4'h8; G <= 4'h8; B <= 4'h8; end
                            endcase
                        end
                    end

                    modo_mira:                                       // Estado mira
                    begin
                        if (hsinc == 320 || vsinc == 240)            // Linha vertical ou horizontal central faz uma cuz
                        begin
                            R <= 4'hF;                               // Branco
                            G <= 4'hF;
                            B <= 4'hF;
                        end
                        else
                        begin
                            R <= 0;                                  // Preto
                            G <= 0;
                            B <= 0;
                        end
                    end

                    modo_xadrez:                                     // Estado xadrez
                    begin
                        if (hsinc[5] ^ vsinc[5])                     // Alternância usando XOR de bits
                        begin
                            R <= 4'hF;                               // Branco
                            G <= 4'hF;
                            B <= 4'hF;
                        end
                        else
                        begin
                            R <= 0;                                  // Preto
                            G <= 0;
                            B <= 0;
                        end
                    end

                    default:
                            begin
                                R <= 0;                              // Preto
                                G <= 0;
                                B <= 0;
                            end
                endcase
            end
        end
    end

endmodule                                                           // Fim do módulo