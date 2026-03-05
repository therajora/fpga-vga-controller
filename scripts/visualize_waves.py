#!/usr/bin/env python3

import sys
import os
import re
import matplotlib.pyplot as plt

def parse_vcd(vcd_file, signals):
    """
    Parses a VCD file for specific signals.
    Returns a dictionary of signal names to a list of (time, value) tuples.
    """
    data = {sig: [] for sig in signals}
    # Map from VCD identifier to signal name
    id_map = {}
    current_time = 0
    
    with open(vcd_file, 'r') as f:
        for line in f:
            line = line.strip()
            if not line: continue
            
            if line.startswith('$var'):
                parts = line.split()
                # Format: $var type size id name $end
                # We are interested in 'id' and 'name'
                # parts[3] is id, parts[4] is name
                if len(parts) >= 5:
                    sig_name = parts[4]
                    sig_id = parts[3]
                    if sig_name in signals:
                        id_map[sig_id] = sig_name
            
            elif line.startswith('#'):
                current_time = int(line[1:])
            
            elif line.startswith('$dumpvars') or line.startswith('$end'):
                continue
            
            else:
                # Value change
                # For 1-bit: value+id (e.g. 1! or 0!)
                # For vectors: b0010 id (e.g. b1010 !)
                match = re.match(r'^([01xz])(.+)$', line)
                if match:
                    val, sig_id = match.groups()
                    if sig_id in id_map:
                        sig_name = id_map[sig_id]
                        # Convert x/z to 0 or previous? Let's use 0 for simplicity or None
                        if val in 'xz': val = 0
                        else: val = int(val)
                        data[sig_name].append((current_time, val))
                else:
                    match_vec = re.match(r'^b([01xz]+)\s+(.+)$', line)
                    if match_vec:
                        val_str, sig_id = match_vec.groups()
                        if sig_id in id_map:
                            sig_name = id_map[sig_id]
                            # Handle x/z
                            val_str = val_str.replace('x', '0').replace('z', '0')
                            try:
                                val = int(val_str, 2)
                            except ValueError:
                                val = 0
                            data[sig_name].append((current_time, val))

    # Post-process to extend values to end time or fill gaps?
    # For plotting step-wise, matplotlib step() works if we have time points.
    return data

def plot_waves(data, output_file, duration=None):
    """
    Plots the waveform data.
    """
    signals = list(data.keys())
    num_signals = len(signals)
    fig, axes = plt.subplots(num_signals, 1, sharex=True, figsize=(12, 2*num_signals))
    
    if num_signals == 1:
        axes = [axes]
    
    for i, sig in enumerate(signals):
        ax = axes[i]
        times, values = zip(*data[sig]) if data[sig] else ([], [])
        
        # Add initial point at time 0 if missing
        if times and times[0] != 0:
            times = (0,) + times
            values = (values[0],) + values
            
        ax.step(times, values, where='post')
        ax.set_ylabel(sig)
        ax.grid(True)
        
        # If duration is specified, limit x-axis
        if duration:
            ax.set_xlim(0, duration)
            
    plt.xlabel('Time (ps)')
    plt.tight_layout()
    plt.savefig(output_file)
    print(f"Plot saved to {output_file}")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 visualize_waves.py <vcd_file> [duration]")
        sys.exit(1)
        
    vcd_file = sys.argv[1]
    duration = int(sys.argv[2]) if len(sys.argv) > 2 else None
    
    # Signals to plot - customize based on testbench or args?
    # We'll default to common VGA signals
    signals_to_plot = ['clk', 'hsync', 'vsync', 'red', 'green', 'blue', 'R', 'G', 'B', 'display']
    
    data = parse_vcd(vcd_file, signals_to_plot)
    
    # Filter empty signals
    data = {k: v for k, v in data.items() if v}
    
    if not data:
        print("No matching signals found in VCD.")
        sys.exit(1)
        
    output_png = vcd_file.replace('.vcd', '.png')
    plot_waves(data, output_png, duration)
