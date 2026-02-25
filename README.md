# fpga-vga-controller

Gerador de sincronismo VGA 640x480 @ 60Hz em Verilog.

```mermaid
graph LR
    clk_50["clk 50MHz"] --> clock_div
    clock_div["clock_div<br/>divisor /2 ou PLL"] -->|"clk_pixel 25MHz"| vga_sync
    vga_sync["vga_sync<br/>contadores H/V<br/>sync + blanking"] --> out["hsync / vsync<br/>pixel_x / pixel_y<br/>video_on / frame_end"]
    btn["botoes"] --> debounce --> vga_sync
```

## Estrutura

```sh
rtl/
  clock_div.v   divisor de clock (PLL no Quartus, /2 na simulacao)
  debounce.v    filtro de bounce para botoes
  clock.v       gerador de sync VGA
tb/
  tb_clock.v    testbench automatizado (13 testes VESA)
sim/            saidas de simulacao (.vcd, .vvp)
constraints/    arquivos de pinos para FPGA
```

## Como rodar

```bash
# pre-requisitos
sudo apt install iverilog gtkwave

# compilar e rodar testbench
make test

# abrir formas de onda
make wave

# limpar artefatos
make clean
```
