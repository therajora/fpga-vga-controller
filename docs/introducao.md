# Introdução

## O Problema

A geração de sinais de vídeo em hardware digital exige temporização rigorosamente controlada. Diferentemente de sistemas baseados em software, onde a renderização depende de instruções sequenciais em um processador, a implementação em FPGA requer a descrição explícita de circuitos síncronos capazes de produzir sinais compatíveis com o padrão VGA.

O padrão **VGA (Video Graphics Array)** permanece amplamente suportado por monitores CRT e LCD, especialmente no modo 640×480 @ 60 Hz. Contudo, a exibição estável exige que os sinais de sincronismo (HSYNC e VSYNC) respeitem rigorosamente a norma **VESA** — desvios na largura dos pulsos podem causar distorções, instabilidade ou ausência de imagem.

## Escopo

Implementação de um controlador VGA **640×480 @ 60 Hz** na FPGA **Altera Cyclone III (EP3C16F484)**, cobrindo:

- Síntese de frequência via PLL para gerar o pixel clock de 25,175 MHz
- Geração de sinais de sincronismo conforme a norma VESA
- Renderização procedural de padrões gráficos dinâmicos
- Interface interativa via botões físicos da placa

## Objetivos Técnicos

1. **Dominar temporização VESA** — gerar sinais HSYNC e VSYNC com erro inferior a ±0,5%
2. **Arquitetura modular** — separar claramente PLL, sincronismo e lógica de exibição
3. **Renderização sem frame buffer** — utilizar lógica combinacional procedural para economia de RAM
4. **Interface dinâmica** — implementar objeto móvel e padrões geométricos controlados por botões
5. **Validação via simulação** — criar testbench automatizado para verificar conformidade com a norma

## Desafios Técnicos

```{mermaid}
graph TD
    %% Estilo Global Sóbrio
    classDef default fill:#f9f9f9,stroke:#333,stroke-width:1px,color:#000;
    classDef root fill:#e0e0e0,stroke:#000,stroke-width:2px,font-weight:bold;
    classDef cat fill:#ffffff,stroke:#666,stroke-width:1px,font-weight:bold;

    ROOT((Desafios)):::root

    %% Categorias
    ROOT --> TEMP[Temporização]:::cat
    ROOT --> HARD[Hardware]:::cat
    ROOT --> IMPL[Implementação]:::cat

    %% Detalhes Temporização
    TEMP --> T1[Pixel clock preciso]
    TEMP --> T2[Tolerância VESA ±0.5%]
    TEMP --> T3[Sincronismo H/V]

    %% Detalhes Hardware
    HARD --> H1[Limites do PLL Cyclone III]
    HARD --> H2[Pino nCEO K22]
    HARD --> H3[RAM limitada a 504Kbit]

    %% Detalhes Implementação
    IMPL --> I1[Variável única por always]
    IMPL --> I2[Debounce de botões]
    IMPL --> I3[Anti-tearing via VBlank]
```

- **Precisão do PLL**: O valor exato 25,175 MHz não é atingível diretamente — a fração ideal 1007/2000 excede os limites dos contadores (máx. 512). A melhor aproximação foi **71/141**, resultando em 25,177 MHz (erro de 0,005%).
- **Memória limitada**: Um frame buffer completo (640×480×12bit ≈ 3,7 Mbit) excede a RAM interna (504 Kbit). A solução foi **renderização procedural** — cada pixel é calculado em tempo real.
- **Reconfiguração de pino**: O pino K22 possui função nativa `nCEO` e precisou ser reconfigurado manualmente como I/O regular no Quartus II.
- **Anti-tearing**: Transições de modo gráfico ocorrem exclusivamente durante o intervalo de *Vertical Blanking*.
