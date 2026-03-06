# Makefile — fpga-vga-controller
#
# Targets:
#   make test    → runs Verilog testbench (tb_vga_top)
#   make wave    → generates VCD and opens in GTKWave
#   make sdl     → compiles SDL2 simulator (Verilator)
#   make run     → runs SDL2 simulator
#   make clean   → removes build artifacts
#
# Prerequisites:
#   sudo apt install iverilog gtkwave verilator g++ libsdl2-dev

RTL_DIR = rtl
TB_DIR  = tb
SIM_DIR = sim
OBJ_DIR = obj_dir

IVERILOG = iverilog
VVP      = vvp

# RTL Source Files
RTL_SRC  = $(RTL_DIR)/vga_sync.v \
           $(RTL_DIR)/vga_display.v \
           $(RTL_DIR)/vga_top.v

# Top module name for Verilator
TOP_MODULE = vga_top
SDL_BIN    = $(OBJ_DIR)/V$(TOP_MODULE)_sdl

.PHONY: all test wave sdl run clean

all: test

test:
	$(IVERILOG) -o $(SIM_DIR)/tb_vga_top.vvp $(TB_DIR)/tb_vga_top.v $(RTL_SRC)
	cd $(SIM_DIR) && $(VVP) tb_vga_top.vvp

wave: test
	gtkwave $(SIM_DIR)/tb_vga_top.vcd &

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
