# Resultados e Conclusões

## Validação de Temporização

A validação foi realizada via **testbench automatizado** (simulação RTL), comparando os intervalos medidos com os valores nominais da norma VESA. O critério de aprovação é erro inferior a **±0,5%**.

### Resultados da Simulação

| Parâmetro | Valor Medido | Erro (%) | Status |
|---|---|---|---|
| **Pixel clock** | 25,176 MHz | 0,005% | OK |
| H — Visible Area | 25.420,80 ns | 0,005% | OK |
| H — Front Porch | 635,52 ns | 0,000% | OK |
| H — Sync Pulse | 3.813,12 ns | 0,000% | OK |
| H — Back Porch | 1.906,56 ns | 0,000% | OK |
| V — Visible Area | 15.252,48 µs | 0,006% | OK |
| V — Front Porch | 317,76 µs | 0,006% | OK |
| V — Sync Pulse | 1,00 ms | 0,000% | OK |
| V — Back Porch | 1.048,56 µs | 0,010% | OK |

O desvio máximo observado foi de **0,010%** — significativamente abaixo do limite de 0,5%.

### Verificação Automatizada — Pixel Clock

O testbench captura dois ciclos consecutivos e calcula o erro percentual:

```verilog
task Teste_vesa_clock;
    real periodo, frequencia, erro;
    time t1, t2;
    begin
        $display("\n==== Teste CLOCK VESA ====");
        @(posedge clk); t1 = $time;
        @(posedge clk); t2 = $time;
        periodo = t2 - t1;
        frequencia = 1_000_000.0 / periodo;
        erro = ((frequencia - 25.175) / 25.175) * 100.0;
        $display("Pixel clock: %f MHz | Erro: %0.3f%% | %s",
            frequencia, abs_real(erro),
            (abs_real(erro) <= 0.5) ? "[OK]" : "[FORA]");
    end
endtask
```

## Utilização de Recursos

```{mermaid}
pie title Utilização do FPGA EP3C16
    "Elementos Lógicos livres" : 95
    "Elementos Lógicos usados" : 5
```

| Recurso | Disponível | Utilizado | Observação |
|---|---|---|---|
| Elementos Lógicos | 15.408 | ~5% | Lógica combinacional + registradores |
| RAM M9K | 504 Kbit | 0 | Renderização procedural elimina frame buffer |
| PLLs | 4 | 1 | Síntese do pixel clock |
| Multiplicadores | 56 | 0 | Sem operações aritméticas complexas |

## Conclusões

### Principais Contribuições

1. **Eficiência de recursos** — A renderização procedural eliminou a necessidade de frame buffer, viabilizando o projeto em um FPGA com apenas 504 Kbit de RAM interna.

2. **Precisão temporal** — O pixel clock gerado (25,177 MHz) apresentou desvio de apenas 0,005%, e todos os parâmetros de temporização ficaram abaixo de 0,01% de erro — uma ordem de grandeza melhor que o exigido pela norma VESA.

3. **Controle robusto** — A FSM coordenou de forma estável as transições entre modos de exibição, utilizando o intervalo de Vertical Blanking para evitar artefatos visuais.

4. **Validação completa** — O testbench automatizado verificou cada parâmetro de temporização contra os limites da norma, fornecendo um critério objetivo de aprovação.

### Lições Aprendidas

- Em Verilog para síntese, **cada variável pode ser atribuída em apenas um bloco `always`** — multiple drivers causam erro de compilação.
- O sincronismo vertical deve ser contabilizado em **unidades de linhas completas** (múltiplos de 800 pixels), não em ciclos individuais.
- A reconfiguração do pino `nCEO` (K22) como I/O regular requer configuração explícita nas opções de *Dual-Purpose Pins* do Quartus II.
- O uso de debounce é essencial em interfaces com botões mecânicos — sem ele, um único pressionamento pode gerar múltiplas transições.

### Trabalhos Futuros

- Implementação de resolução 800×600 ou 1024×768 com PLL reconfigurável
- Inclusão de caracteres alfanuméricos via ROM de fontes
- Persistência na flash EPCS4 (atualmente a gravação é feita apenas online via JTAG)
