# Controlador de Vídeo VGA em FPGA

Documentação técnica do projeto de um **controlador VGA 640×480 @ 60 Hz** implementado em Verilog HDL na plataforma **FPGA Altera Cyclone III (EP3C16F484)**.

```{mermaid}
flowchart LR
    CLK50["🔲 Clock 50 MHz"] --> PLL["⚙️ PLL"]
    PLL -->|25.175 MHz| SYNC["📐 vga_sync"]
    SYNC -->|pixel_x, pixel_y| DISP["🎨 vga_display"]
    BTN["🔘 Botões"] --> DISP
    DISP -->|RGB 12-bit| VGA["🖥️ Monitor VGA"]
    SYNC -->|hsync, vsync| VGA
```

## Navegação

```{toctree}
:maxdepth: 2

introducao
arquitetura
pll
sincronismo
exibicao
simulacao
rtl_modules
squads
resultados
```

## Resumo do Projeto

| Item | Detalhe |
|---|---|
| **Resolução** | 640 × 480 pixels @ 60 Hz |
| **Pixel Clock** | 25,175 MHz (via PLL) |
| **FPGA** | Altera Cyclone III EP3C16F484 |
| **Linguagem** | Verilog HDL |
| **Profundidade de cor** | 12 bits (4-4-4 RGB) |
| **Frame buffer** | Não utilizado (renderização procedural) |
| **Modos gráficos** | Quadrado móvel, mira central, xadrez |
