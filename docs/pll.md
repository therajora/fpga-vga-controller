# PLL – Síntese de Frequência

## Por que um PLL?

O padrão VESA exige um **pixel clock de 25,175 MHz** para a resolução 640×480 @ 60 Hz. A placa DE0 possui um oscilador de **50 MHz**. A conversão é realizada pelo **PLL (Phase-Locked Loop)**, um bloco de hardware dedicado do Cyclone III que multiplica e divide frequências com baixo jitter.

```{mermaid}
flowchart LR
    IN["50 MHz (inclk0)"] --> DIV_N["Divisor N (N=3)"]
    DIV_N --> PFD["Detector de Fase"]
    PFD --> LPF["Filtro LPF"]
    LPF --> VCO["VCO (1183 MHz)"]
    VCO --> DIV_C["Divisor C0 (C0=47)"]
    DIV_C --> OUT["25.177 MHz (pixel clock)"]
    VCO --> DIV_M["Divisor M (M=71)"]
    DIV_M --> PFD
```

## Equação de Síntese

$$
f_{OUT} = \frac{f_{IN} \times M}{N \times C_0}
$$

Substituindo os parâmetros:

$$
f_{OUT} = \frac{50 \times 71}{3 \times 47} = \frac{3550}{141} \approx 25{,}177 \text{ MHz}
$$

## Parâmetros de Configuração

| Parâmetro | Valor | Função |
|---|---|---|
| **M** (multiplicador) | 71 | Fator de multiplicação do VCO |
| **N** (divisor de entrada) | 3 | $f_{VCO} = 50 \times 71 / 3 \approx 1183$ MHz |
| **C0** (divisor de saída) | 47 | Produz $f_{out} \approx 25{,}177$ MHz |
| **Duty Cycle** | 50% | Ajustado automaticamente pelo hardware |

:::{note}
O VCO deve operar entre **600 MHz e 1300 MHz** (limites da Cyclone III). Com a configuração escolhida, $f_{VCO} \approx 1183$ MHz — dentro da faixa segura.
:::

## Por que não 25,175 MHz exato?

A fração ideal seria $\frac{1007}{2000}$, mas os contadores internos da Cyclone III aceitam no máximo o valor **512**. A melhor aproximação viável é a fração **71/141**, que resulta em um erro de apenas **0,005%** — muito abaixo da tolerância de ±0,5% da norma VESA.

## Configuração no Quartus II

1. **Tools → MegaWizard Plug-in Manager**
2. Selecionar **ALTPLL** (pasta I/O)
3. Definir `inclk0 = 50 MHz`
4. Em **Output Clocks**, configurar M = 71 e N×C = 141
5. Habilitar sinais `areset` e `locked`
6. Exportar os arquivos `.v` para instanciar no `vga_top`

:::{tip}
O sinal `locked` indica que o PLL estabilizou. Use-o para manter o restante da lógica em reset até que o clock esteja pronto.
:::
