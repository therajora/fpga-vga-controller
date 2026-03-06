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
    *   `sim_sdl.cpp`: C++ simulator using Verilator + SDL2.
    *   `mock_pll.v`: Simulation model for the PLL.
*   `scripts/`: Utility scripts.
    *   `visualize_waves.py`: Generates waveform plots from VCD files.
*   `docs/`: Technical documentation (Sphinx).

## Running Tests

### 1. Verilog Testbench (Waveforms)
Checks timing and generates VCD files.

```bash
make test
make wave
```

### 2. C++ Visual Simulation (Verilator + SDL2)
Simulates the VGA output in real-time using a window on your desktop. This is much faster than traditional HDL simulation for checking visual artifacts.

**Prerequisites:**
```bash
sudo apt install verilator libsdl2-dev g++
```

**Run:**
```bash
make run
```
Controls:
- `M`: Change Mode
- `C`: Change Background Color
- `V`: Change Square Color
- `ESC`: Quit

A screenshot is automatically saved as `sim_screenshot.bmp` after 1 second.

### 3. Automated Python Tests
We provide a Python script to automate compiling, running, and visualizing tests.

```bash
./run_tests.py
```
This generates `.png` plots of the waveforms in `sim/`.

## Modules

### `vga_fpga` (Top Level)
Wraps the design for the FPGA, including the PLL to generate the 25.175 MHz pixel clock from the 50 MHz input clock.

### `vga_top`
Connects the synchronization logic (`vga_sync`) and the display logic (`vga_display`).

### `vga_sync`
Generates HSYNC and VSYNC signals according to VESA 640x480@60Hz timing standards.

### `vga_display`
Generates RGB color signals based on the current pixel coordinates and selected mode (Static color, Crosshair, Checkerboard, etc.).
