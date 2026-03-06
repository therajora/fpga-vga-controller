`timescale 1ns/1ps

module tb_vga_top;

    reg clk = 0;       // 25 MHz
    reg reset = 1;
    reg btn_bg = 0;      // Cor Tela
    reg btn_sq = 0;      // Cor Quadrado
    reg btn_mode = 0;      // Modo

    wire hsync;
    wire vsync;
    wire [3:0] R;
    wire [3:0] G;
    wire [3:0] B;

    // 25 MHz -> period 40 ns (20 ns high, 20 ns low)
    always #20 clk = ~clk;

    vga_top uut (
        .clk(clk),
        .reset(reset),
        .btn_color_bg(btn_bg),
        .btn_color_sq(btn_sq),
        .btn_mode(btn_mode),
        .hsync(hsync),
        .vsync(vsync),
        .R(R),
        .G(G),
        .B(B)
    );

    initial begin
        $dumpfile("vga_top.vcd");
        $dumpvars(0, tb_vga_top);

        // Reset sequence
        #100;
        reset = 0;

        // Run simulation for enough time to see sync pulses
        // HSYNC period ~32 us = 32000 ns
        
        // Wait for HSYNC start
        wait(hsync == 0);
        $display("HSYNC active at %t", $time);
        
        wait(hsync == 1);
        $display("HSYNC inactive at %t", $time);

        // Run for 2 full frames approx (16.7ms * 2 = 34ms)
        // 34 ms = 34,000,000 ns
        // Simulating 34ms might be slow in Icarus if dumping VCD for everything.
        // Let's run for a few lines (e.g. 2 lines = ~64 us)
        #100000; 

        $finish;
    end

endmodule
