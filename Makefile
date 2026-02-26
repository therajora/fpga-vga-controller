# Makefile — fpga-vga-controller
#
# Targets:
#   make test    → checks automaticos VESA (13 testes)
#   make wave    → gera VCD e abre no GTKWave
#   make sdl     → compila simulador SDL2 (Verilator)
#   make run     → compila e abre janela SDL2
#   make clean   → remove artefatos de build
#
# Pre-requisitos:
#   sudo apt install iverilog gtkwave verilator g++ libsdl2-dev

RTL_DIR = rtl
TB_DIR  = tb
SIM_DIR = sim
OBJ_DIR = obj_dir

IVERILOG = iverilog
VVP      = vvp

RTL_SYNC = $(RTL_DIR)/clock.v
RTL_SRC  = $(RTL_DIR)/clock_div.v \
           $(RTL_DIR)/debounce.v \
           $(RTL_DIR)/clock.v \
           $(RTL_DIR)/vga_display.v \
           $(RTL_DIR)/vga_top.v

TOP_MODULE = vga_top
SDL_BIN    = $(OBJ_DIR)/V$(TOP_MODULE)_sdl

.PHONY: all test wave sdl run clean

all: test

test:
	$(IVERILOG) -o $(SIM_DIR)/tb_clock.vvp $(TB_DIR)/tb_clock.v $(RTL_SYNC)
	cd $(SIM_DIR) && $(VVP) tb_clock.vvp

wave: test
	gtkwave $(SIM_DIR)/tb_clock.vcd &

sdl: $(SDL_BIN)

$(SDL_BIN): $(RTL_SRC) $(SIM_DIR)/sim_sdl.cpp
	verilator --cc --exe --build -j 0 \
		-O3 --x-assign fast --x-initial fast --noassert \
		-CFLAGS "-O2 -std=c++17 $$(sdl2-config --cflags)" \
		-LDFLAGS "$$(sdl2-config --libs) -lpthread" \
		--top-module $(TOP_MODULE) \
		-Wno-WIDTH \
		--Mdir $(OBJ_DIR) \
		-o V$(TOP_MODULE)_sdl \
		$(RTL_SRC) $(SIM_DIR)/sim_sdl.cpp

run: sdl
	$(SDL_BIN)

clean:
	rm -f $(SIM_DIR)/*.vvp $(SIM_DIR)/*.vcd
	rm -rf $(OBJ_DIR)
