# Módulos RTL

Abaixo está a documentação detalhada de cada módulo Verilog desenvolvido para o projeto. O código está organizado de forma hierárquica.

## `vga_top.v` (Top-Level)

Este é o módulo principal que integra os sub-blocos e conecta-se aos pinos físicos do FPGA.

### Função
- Instancia o módulo de sincronismo (`vga_sync`).
- Instancia o gerador de padrões de vídeo (`vga_display`).
- Conecta os botões físicos aos módulos internos.

### Código Fonte

```verilog
module vga_top (
    input  wire clk,                // 25 MHz
    input  wire reset,

    input  wire btn_color_bg,       // Botão cor de fundo
    input  wire btn_color_sq,       // Botão cor do quadrado
    input  wire btn_mode,           // Botão de modo

    output wire hsync,
    output wire vsync,

    output wire [3:0] R,
    output wire [3:0] G,
    output wire [3:0] B
);
    // ... (sinais internos e instâncias)
endmodule
```

---

## `vga_sync.v` (Controlador de Sincronismo)

Gera os sinais de temporização VESA 640x480 @ 60Hz.

### Parâmetros (Configuráveis)
| Parâmetro | Valor Padrão | Descrição |
|---|---|---|
| `H_VISIBLE` | 640 | Largura da área ativa |
| `H_FRONT` | 16 | Front Porch Horizontal |
| `H_SYNC` | 96 | Pulso de Sincronismo Horizontal |
| `H_BACK` | 48 | Back Porch Horizontal |
| `V_VISIBLE` | 480 | Altura da área ativa |

### Lógica de Funcionamento
Utiliza dois contadores (`h_count` e `v_count`) para rastrear a posição atual do feixe de elétrons. Gera os sinais `hsync` e `vsync` (ativo baixo) quando os contadores atingem as janelas de sincronismo especificadas.

```verilog
    // Exemplo da lógica HSYNC
    always @(posedge clk or posedge rst) begin
        if (rst)
            hsync <= 1;
        else if (h_count >= (H_VISIBLE + H_FRONT) && 
                 h_count <  (H_VISIBLE + H_FRONT + H_SYNC))
            hsync <= 0;
        else
            hsync <= 1;
    end
```

---

## `vga_display.v` (Gerador de Padrões)

Responsável por determinar a cor de cada pixel (`R`, `G`, `B`) com base nas coordenadas (`pixel_x`, `pixel_y`) e no estado atual.

### Máquina de Estados (FSM)
O módulo possui uma FSM para alternar entre os modos de visualização:
1.  **MODE_SQUARE**: Exibe um quadrado móvel sobre um fundo colorido.
2.  **MODE_CROSS**: Exibe uma mira (cruz) centralizada.
3.  **MODE_CHECKER**: Exibe um padrão de xadrez.

### Lógica de Renderização
A renderização é feita "on-the-fly" (sem memória de vídeo), verificando a posição do pixel atual.

```verilog
    // Lógica do quadrado
    wire in_square = (pixel_x >= sq_x) && (pixel_x < sq_x + SQUARE_SIZE) &&
                     (pixel_y >= sq_y) && (pixel_y < sq_y + SQUARE_SIZE);
```

---

## `tb_vga_top.v` (Testbench)

Simula o sistema completo, gerando o clock de 25MHz e estímulos de reset.

### Verificações Realizadas
- Período do Clock
- Largura dos pulsos de sincronismo
- Polaridade dos sinais

```verilog
    // Geração de Clock 25MHz
    always #20 clk = ~clk; 
```
