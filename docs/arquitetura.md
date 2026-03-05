# Arquitetura do Sistema

## Visão Geral

A arquitetura foi projetada de forma **modular**, permitindo que cada subsistema seja desenvolvido e testado independentemente. O módulo `vga_top` é o *top-level entity* que instancia e interconecta os três blocos funcionais.

```{mermaid}
flowchart TB
    subgraph TOP["vga_top (Top-Level)"]
        direction TB
        PLL["pll<br/>50 MHz → 25.175 MHz"]
        SYNC["vga_sync<br/>Contadores H/V<br/>HSYNC, VSYNC, blanking"]
        DISP["vga_display<br/>FSM + Renderização<br/>RGB 12-bit"]
    end

    CLK["Clock 50 MHz<br/>(placa)"] --> PLL
    PLL -->|pixel_clk| SYNC
    PLL -->|pixel_clk| DISP

    SYNC -->|pixel_x[9:0]| DISP
    SYNC -->|pixel_y[9:0]| DISP
    SYNC -->|display_enable| DISP

    BTN["Botões<br/>(3 pushbuttons)"] --> DISP

    SYNC -->|hsync| VGA["Conector VGA<br/>D-sub 15 pinos"]
    SYNC -->|vsync| VGA
    DISP -->|R[3:0], G[3:0], B[3:0]| DAC["Rede Resistiva<br/>4-bit DAC"] --> VGA
```

## Módulos

### `pll` — Síntese de Frequência

Converte o clock base de **50 MHz** da Cyclone III para **25,175 MHz** (pixel clock exigido pela VESA). Utiliza o bloco PLL dedicado do FPGA configurado via MegaWizard.

→ Detalhes em [PLL – Síntese de Frequência](pll.md)

### `vga_sync` — Unidade de Sincronismo

Núcleo de controle temporal. Contém dois contadores de 10 bits (horizontal 0–799, vertical 0–524) e gera:

| Sinal | Função |
|---|---|
| `hsync` | Pulso de sincronismo horizontal (ativo baixo) |
| `vsync` | Pulso de sincronismo vertical (ativo baixo) |
| `display_enable` | Máscara para área visível (640×480) |
| `pixel_x[9:0]` | Coordenada X do pixel atual |
| `pixel_y[9:0]` | Coordenada Y do pixel atual |

→ Detalhes em [Sincronismo VGA](sincronismo.md)

### `vga_display` — Lógica de Exibição

Recebe as coordenadas espaciais e renderiza os pixels em tempo real. Contém:

- **FSM de modos** — alterna entre quadrado móvel, mira e xadrez
- **FSM de debounce** — filtra ruído mecânico dos botões (50 ms)
- **Lógica de cor** — mapeia coordenadas para R/G/B com mascaramento de blanking

→ Detalhes em [Lógica de Exibição](exibicao.md)

## Fluxo de Dados por Pixel

A cada ciclo do pixel clock, o sistema executa **em paralelo**:

```{mermaid}
sequenceDiagram
    participant CK as Pixel Clock
    participant SC as vga_sync
    participant DP as vga_display
    participant VGA as Monitor

    CK->>SC: posedge clk
    SC->>SC: h_count++, verifica limites
    SC->>DP: pixel_x, pixel_y, display_enable
    DP->>DP: Avalia modo (FSM), calcula cor
    DP->>VGA: R[3:0], G[3:0], B[3:0]
    SC->>VGA: hsync, vsync
```

## Recursos do FPGA

| Recurso | Disponível (EP3C16) | Utilizado |
|---|---|---|
| Elementos Lógicos | 15.408 | ~5% |
| Blocos M9K | 56 (504 Kbit) | 0 (sem frame buffer) |
| PLLs | 4 | 1 |
| Pinos I/O | 346 | ~20 (VGA + botões) |
