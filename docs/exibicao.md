# Lógica de Exibição

## Renderização Procedural

A abordagem escolhida calcula a cor de **cada pixel em tempo real**, sem frame buffer. Isso é necessário porque um buffer completo demandaria:

$$
640 \times 480 \times 12 \text{ bits} = 3{,}686{,}400 \text{ bits} \approx 3{,}7 \text{ Mbit}
$$

A Cyclone III dispõe de apenas **504 Kbit** de RAM interna — insuficiente. A renderização procedural consome **zero bits de memória** para armazenamento de frame.

## Máquina de Estados — Modos Gráficos

O módulo `vga_display` utiliza uma **FSM** para alternar entre três modos de exibição:

```{mermaid}
stateDiagram-v2
    direction LR
    [*] --> Quadrado: reset
    Quadrado --> Mira: botão modo
    Mira --> Xadrez: botão modo
    Xadrez --> Quadrado: botão modo

    Quadrado: Quadrado Móvel
    Mira: Mira Central
    Xadrez: Padrão Xadrez
```

O estado é armazenado em um registrador de 2 bits (`modo_atual`). A transição ocorre na **borda de subida** do botão de modo, sincronizada ao clock.

:::{important}
Todas as trocas de estado ocorrem durante o intervalo de **Vertical Blanking** para evitar o efeito de *tearing* (rasgo visual durante a transição).
:::

## Modos de Operação

### Modo 0 — Quadrado Móvel

Um quadrado de dimensão fixa (40×40 pixels) se desloca pela tela com velocidade constante, rebatendo nas bordas:

```{mermaid}
flowchart TD
    A["Pixel atual<br/>(pixel_x, pixel_y)"] --> B{Está na região<br/>do quadrado?}
    B -->|Sim| C["Cor do quadrado<br/>(selecionável)"]
    B -->|Não| D["Cor de fundo<br/>(selecionável)"]
    C --> E["Saída RGB"]
    D --> E
```

**Detecção do quadrado:**

```verilog
assign dentro_horizontal = (hsinc >= pos_hsinc) &&
                            (hsinc <  pos_hsinc + tamanho_do_quadrado);
assign dentro_vertical   = (vsinc >= pos_vsinc) &&
                            (vsinc <  pos_vsinc + tamanho_do_quadrado);
assign formacao_quadrado = dentro_horizontal && dentro_vertical;
```

**Atualização de posição** — ocorre apenas uma vez por frame (~60 Hz):

```verilog
if (fim_frame) begin
    pos_hsinc <= pos_hsinc + vel_hsinc;
    pos_vsinc <= pos_vsinc + vel_vsinc;
    // Inversão de velocidade ao colidir com bordas
    if (pos_hsinc <= 0)
        vel_hsinc <= 4'sd1;
    else if (pos_hsinc + tamanho_do_quadrado >= largura_de_tela)
        vel_hsinc <= -4'sd1;
end
```

### Modo 1 — Mira Central

Uma cruz fixa no centro da tela (linha vertical em x=320, linha horizontal em y=240):

```verilog
if (hsinc == 320 || vsinc == 240)
    {R, G, B} <= 12'hFFF;  // branco
else
    {R, G, B} <= 12'h000;  // preto
```

### Modo 2 — Padrão Xadrez

Tabuleiro gerado por **operação XOR** entre bits de posição — sem comparadores complexos:

```verilog
if (hsinc[5] ^ vsinc[5])
    {R, G, B} <= 12'hFFF;  // branco
else
    {R, G, B} <= 12'h000;  // preto
```

O bit 5 ($2^5 = 32$) define blocos de **32×32 pixels**.

## Debounce de Botões

Os botões mecânicos geram ruídos (bouncing) que podem ser interpretados como múltiplos acionamentos. A solução é uma **FSM de debounce** com atraso de 50 ms:

```{mermaid}
stateDiagram-v2
    direction LR
    [*] --> Idle
    Idle --> Debounce: botão pressionado
    Debounce --> Leitura: 50ms decorridos
    Leitura --> Idle: processa ação
```

## Controle de Cores

Os botões permitem alterar as cores de forma cíclica:

| Botão | Ação |
|---|---|
| **Botão 1** | Altera a cor de fundo da tela |
| **Botão 2** | Ativa mira + xadrez sobrepostos |
| **Botão 3** | Ativa quadrado / altera cor do quadrado / altera cor de fundo |

As cores são selecionadas por registradores de 2 bits, permitindo 4 combinações por botão.
