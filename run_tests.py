#!/usr/bin/env python3

import os
import subprocess
import sys

# Configuration
RTL_DIR = "rtl"
TB_DIR = "tb"
SIM_DIR = "sim"
SCRIPTS_DIR = "scripts"

# Testbenches to run
# Format: (tb_file, [rtl_files], vcd_file)
TESTS = [
    {
        "name": "vga_sync",
        "tb": "tb_vga_sync.v",
        "rtl": ["vga_sync.v"],
        "vcd": "vga_sync.vcd"
    },
    {
        "name": "vga_display",
        "tb": "tb_vga_display.v",
        "rtl": ["vga_display.v"],
        "vcd": "vga_display.vcd"
    },
    {
        "name": "vga_top",
        "tb": "tb_vga_top.v",
        "rtl": ["vga_fpga.v", "vga_top.v", "vga_sync.v", "vga_display.v"],
        "vcd": "vga_top.vcd",
        "extra_rtl": ["sim/mock_pll.v"] # Mock PLL for simulation
    }
]

def run_command(cmd):
    print(f"Running: {cmd}")
    ret = os.system(cmd)
    if ret != 0:
        print(f"Error executing command: {cmd}")
        return False
    return True

def main():
    if not os.path.exists(SIM_DIR):
        os.makedirs(SIM_DIR)
        
    results = {}
    
    for test in TESTS:
        print(f"\n--- Running Test: {test['name']} ---")
        
        tb_path = os.path.join(TB_DIR, test['tb'])
        rtl_paths = [os.path.join(RTL_DIR, f) for f in test['rtl']]
        
        if "extra_rtl" in test:
             rtl_paths.extend(test["extra_rtl"])
             
        vvp_out = os.path.join(SIM_DIR, f"{test['name']}.vvp")
        
        # 1. Compile
        cmd_compile = f"iverilog -o {vvp_out} -I {RTL_DIR} {tb_path} {' '.join(rtl_paths)}"
        if not run_command(cmd_compile):
            results[test['name']] = "COMPILE FAIL"
            continue
            
        # 2. Simulate
        cmd_sim = f"vvp {vvp_out}"
        if not run_command(cmd_sim):
            results[test['name']] = "SIM FAIL"
            continue
            
        # Check if VCD was generated
        if os.path.exists(test['vcd']):
             # Move VCD to SIM_DIR
             dest_vcd = os.path.join(SIM_DIR, test['vcd'])
             os.rename(test['vcd'], dest_vcd)
             
             # 3. Visualize
             cmd_viz = f"python3 {os.path.join(SCRIPTS_DIR, 'visualize_waves.py')} {dest_vcd}"
             run_command(cmd_viz)
             
             results[test['name']] = "PASS"
        else:
             results[test['name']] = "NO VCD"
             
    print("\n--- Test Results ---")
    for name, status in results.items():
        print(f"{name}: {status}")

if __name__ == "__main__":
    main()
