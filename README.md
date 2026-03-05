# VGA Controller (Refactored)

This repository contains a Verilog implementation of a VGA controller (640x480 @ 60Hz), organized for clarity and testability.

## Directory Structure

*   `rtl/`: Synthesizable Verilog source code.
    *   `vga_fpga.v`: Top-level wrapper (instantiates PLL and Core).
    *   `vga_top.v`: Core logic (Sync + Display).
    *   `vga_sync.v`: VGA Synchronization logic (HSYNC, VSYNC).
    *   `vga_display.v`: Pattern generation logic.
    *   `vga_pll.v`: PLL module (Altera IP).
*   `tb/`: Testbenches.
    *   `tb_vga_sync.v`: Tests synchronization signals.
    *   `tb_vga_display.v`: Tests pattern generation.
    *   `tb_vga_top.v`: Tests the full integration.
*   `sim/`: Simulation artifacts and models.
    *   `mock_pll.v`: Simulation model for the PLL.
*   `scripts/`: Utility scripts.
    *   `visualize_waves.py`: Generates waveform plots from VCD files.

## Running Tests

We provide a Python script to automate compiling, running, and visualizing tests.

### Prerequisites

*   `iverilog` (Icarus Verilog)
*   `python3`
*   `matplotlib` (Python library for plotting)

### Execution

Run the test runner from this directory:

```bash
./run_tests.py
```

This will:
1.  Compile each testbench using `iverilog`.
2.  Run the simulation using `vvp`.
3.  Generate `.vcd` waveform files.
4.  Plot key signals (HSYNC, VSYNC, RGB) to `.png` images in the `sim/` directory.

### Simulation Output

Check the `sim/` directory for:
*   `*.vvp`: Compiled simulation executables.
*   `*.vcd`: Waveform dumps.
*   `*.png`: Visualized waveforms.

## Modules

### `vga_fpga` (Top Level)
Wraps the design for the FPGA, including the PLL to generate the 25.175 MHz pixel clock from the 50 MHz input clock.

### `vga_top`
Connects the synchronization logic (`vga_sync`) and the display logic (`vga_display`).

### `vga_sync`
Generates HSYNC and VSYNC signals according to VESA 640x480@60Hz timing standards.

### `vga_display`
Generates RGB color signals based on the current pixel coordinates and selected mode (Static color, Crosshair, Checkerboard, etc.).
