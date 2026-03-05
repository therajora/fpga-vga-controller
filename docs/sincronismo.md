# Sincronismo VGA

## O Padrão de Varredura

O VGA utiliza **varredura sequencial**: a imagem é formada pixel por pixel, da esquerda para a direita e de cima para baixo. Cada linha e cada quadro são divididos em quatro regiões temporais:

```{mermaid}
flowchart LR
    A["Visible Area<br/>Pixels ativos"] --> B["Front Porch<br/>Margem de segurança"]
    B --> C["Sync Pulse<br/>Pulso de sincronismo"]
    C --> D["Back Porch<br/>Estabilização"]
    D --> A
```

## Temporização VESA — 640×480 @ 60 Hz

### Horizontal (em pixels)

| Região | Pixels | Tempo |
|---|---|---|
| Visible Area | 640 | 25.420,8 ns |
| Front Porch | 16 | 635,5 ns |
| Sync Pulse | 96 | 3.813,1 ns |
| Back Porch | 48 | 1.906,6 ns |
| **Total** | **800** | **31,77 µs** |

### Vertical (em linhas)

| Região | Linhas | Tempo |
|---|---|---|
| Visible Area | 480 | 15.253,4 µs |
| Front Porch | 10 | 317,8 µs |
| Sync Pulse | 2 | 63,6 µs |
| Back Porch | 33 | 1.048,7 µs |
| **Total** | **525** | **16,68 ms** |

### Frequências derivadas

$$
f_H = \frac{25{,}175 \times 10^6}{800} \approx 31{,}468 \text{ kHz} \quad \Rightarrow \quad T_H \approx 31{,}77 \text{ µs}
$$

$$
f_V = \frac{31{,}468 \times 10^3}{525} \approx 59{,}94 \text{ Hz} \quad \Rightarrow \quad T_V \approx 16{,}68 \text{ ms}
$$

## Implementação: `vga_sync`

O módulo utiliza **dois contadores síncronos de 10 bits** encadeados:

```{mermaid}
stateDiagram-v2
    direction LR
    [*] --> Contando_H: reset
    Contando_H --> Contando_H: h_count < 799
    Contando_H --> Incrementa_V: h_count == 799
    Incrementa_V --> Contando_H: v_count < 524
    Incrementa_V --> Frame_Done: v_count == 524
    Frame_Done --> Contando_H: reinicia ambos
```

### Código Verilog — Contadores

```verilog
localparam H_TOTAL = 800;
localparam V_TOTAL = 525;

reg [9:0] h_count;  // 0–799
reg [9:0] v_count;  // 0–524

always @(posedge clk or posedge rst) begin
    if (rst) begin
        h_count <= 0;
        v_count <= 0;
    end else begin
        if (h_count == H_TOTAL - 1) begin
            h_count <= 0;
            if (v_count == V_TOTAL - 1)
                v_count <= 0;
            else
                v_count <= v_count + 1;
        end else
            h_count <= h_count + 1;
    end
end
```

### Código Verilog — Geração de HSYNC / VSYNC

```verilog
// HSYNC: ativo baixo entre pixels 656 e 751
always @(posedge clk or posedge rst) begin
    if (rst)
        hsync <= 1;
    else if (h_count >= (H_VISIBLE + H_FRONT) &&
             h_count <= (H_VISIBLE + H_FRONT + H_SYNC - 1))
        hsync <= 0;
    else
        hsync <= 1;
end

// VSYNC: ativo baixo entre linhas 490 e 491
always @(posedge clk or posedge rst) begin
    if (rst)
        vsync <= 1;
    else if (v_count >= (V_VISIBLE + V_FRONT) &&
             v_count <= (V_VISIBLE + V_FRONT + V_SYNC - 1))
        vsync <= 0;
    else
        vsync <= 1;
end
```

### Sinal de Blanking

Fora da área visível (640×480), os sinais RGB **devem ser zero** para evitar distorções:

```verilog
assign display_enable = (h_count < H_VISIBLE) && (v_count < V_VISIBLE);
```

## Diagrama de Temporização

```{mermaid}
gantt
    title Ciclo Horizontal (800 pixels)
    dateFormat X
    axisFormat %s

    section Regiões
    Visible Area (640px)   :a, 0, 640
    Front Porch (16px)     :b, 640, 656
    Sync Pulse (96px)      :crit, c, 656, 752
    Back Porch (48px)      :d, 752, 800
```
