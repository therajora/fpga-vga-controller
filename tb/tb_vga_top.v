`timescale 1ns/1ps

module tb_vga_top;

    reg clk = 0;       // 50 MHz
    reg rst = 1;
    reg btn1 = 0;      // Cor Tela
    reg btn2 = 0;      // Cor Quadrado
    reg btn3 = 0;      // Modo

    wire hsync;
    wire vsync;
    wire [3:0] red;
    wire [3:0] green;
    wire [3:0] blue;

    // 50 MHz -> period 20 ns
    always #10 clk = ~clk;

    vga_fpga uut (
        .clk(clk),
        .rst(rst),
        .button1(btn1),
        .button2(btn2),
        .button3(btn3),
        .hsync(hsync),
        .vsync(vsync),
        .red(red),
        .green(green),
        .blue(blue)
    );

    initial begin
        $dumpfile("vga_top.vcd");
        $dumpvars(0, tb_vga_top);

        // Wait for PLL lock and reset
        #200;
        rst = 0;

        // Run simulation for enough time to see sync pulses
        // HSYNC period ~32 us
        // VSYNC period ~16.7 ms
        
        // Wait for HSYNC start
        wait(hsync == 0);
        $display("HSYNC active at %t", $time);
        
        wait(hsync == 1);
        $display("HSYNC inactive at %t", $time);

        // Run for 2 ms (enough for many HSYNCs, but not full VSYNC unless very long)
        // For visualization, we might want more.
        #2000000; // 2 ms

        $finish;
    end

endmodule
