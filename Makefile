# Makefile — fpga-vga-controller
#
# Targets:
#   make test    → compila e roda o testbench (Icarus Verilog)
#   make wave    → abre o VCD no GTKWave
#   make clean   → remove artefatos de build
#
# Pre-requisitos:
#   sudo apt install iverilog gtkwave

RTL_DIR = rtl
TB_DIR  = tb
SIM_DIR = sim

IVERILOG = iverilog
VVP      = vvp

RTL_SRC  = $(RTL_DIR)/clock_div.v \
           $(RTL_DIR)/debounce.v \
           $(RTL_DIR)/clock.v
TB_SRC   = $(TB_DIR)/tb_clock.v
TB_BIN   = $(SIM_DIR)/tb_clock.vvp
VCD_FILE = $(SIM_DIR)/tb_clock.vcd

.PHONY: all test wave clean

all: test

test: $(TB_BIN)
	cd $(SIM_DIR) && $(VVP) tb_clock.vvp

$(TB_BIN): $(TB_SRC) $(RTL_SRC)
	$(IVERILOG) -o $(TB_BIN) $(TB_SRC) $(RTL_SRC)

wave: $(VCD_FILE)
	gtkwave $(VCD_FILE) &

clean:
	rm -f $(SIM_DIR)/*.vvp $(SIM_DIR)/*.vcd
