# Simulação e Testes

Este projeto utiliza duas abordagens complementares para verificação:
1. **Testbench Verilog (Icarus Verilog + GTKWave):** Para análise detalhada de sinais e temporização (waveforms).
2. **Simulação Visual em C++ (Verilator + SDL2):** Para validação funcional rápida e interativa do vídeo gerado.

## Por que Simulação em C++?

A simulação tradicional de HDL (como ModelSim ou Icarus Verilog) é extremamente precisa, mas lenta para simular milhões de pixels por segundo necessários para um frame de vídeo completo (640x480 @ 60Hz requer ~25 MHz de pixel clock).

Ao traduzir o Verilog para C++ usando o **Verilator**, conseguimos:
- **Performance:** A simulação roda centenas de vezes mais rápido que simuladores de eventos discretos.
- **Visualização:** Podemos conectar a saída VGA virtual diretamente a uma janela SDL2, permitindo ver a imagem como se fosse um monitor real.
- **Interatividade:** Podemos usar o teclado do PC para simular os botões da placa FPGA em tempo real.

## Executando a Simulação Visual (SDL2)

### Pré-requisitos
Certifique-se de ter as bibliotecas instaladas (Linux/Debian):
```bash
sudo apt install verilator libsdl2-dev g++
```

### Compilando e Rodando
No diretório raiz do projeto:
```bash
make run
```

Isso irá:
1. Compilar o código Verilog para C++ (via Verilator).
2. Compilar o wrapper C++ (`sim/sim_sdl.cpp`) com a biblioteca SDL2.
3. Abrir uma janela mostrando a saída VGA.

### Controles da Simulação
| Tecla | Função (Botão FPGA Simulado) |
|---|---|
| **M** | Alterna o Modo de Exibição (Quadrado, Mira, Xadrez) |
| **C** | Alterna a Cor de Fundo |
| **V** | Alterna a Cor do Quadrado |
| **F** | Alterna Tela Cheia |
| **ESC/Q** | Sair |

O simulador também salva automaticamente um screenshot (`sim_screenshot.bmp`) após 60 frames (1 segundo).

## Testbench Verilog (Waveforms)

Para verificar a temporização exata dos sinais de sincronismo (HSYNC/VSYNC), utilizamos um testbench tradicional.

### Executando
```bash
make test
```

### Visualizando Ondas
Para abrir o visualizador de ondas (GTKWave):
```bash
make wave
```

Isso permite verificar se os pulsos de sincronismo estão respeitando os padrões VESA (ex: HSYNC ativo por 3.8us, VSYNC por 64us, etc).
