# Divisão de Código por Squads

O desenvolvimento deste controlador VGA foi dividido entre 4 squads, cada um responsável por um conjunto de módulos e testes. A divisão do código-fonte (RTL e simulação) ficou da seguinte forma:

## Squad 1
**Responsabilidade:** Geração e integração de clock.
- `rtl-squad-1/clock.v`
- `rtl-squad-1/tb_clock.v`

## Squad 2
**Responsabilidade:** Integração final do sistema.
- `rtl-squad-2/VGA_FINAL.v`

## Squad 3
**Responsabilidade:** Testbench de sincronismo avançado.
- `rtl-squad-3/vga_sync_tb.v`

## Squad 4
**Responsabilidade:** Blocos centrais do controlador VGA (Sincronismo, Display, PLL e Wrapper Principal).
- `rtl-squad-4/VgaController.v`
- `rtl-squad-4/VgaDisplay.v`
- `rtl-squad-4/VgaSync.v`
- `rtl-squad-4/vga_pll.v`
