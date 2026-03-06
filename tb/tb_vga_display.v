`timescale 1ns/1ps

module tb_vga_display;

    reg clk = 0;
    reg rst = 1;
    reg [9:0] pixel_x = 0;
    reg [9:0] pixel_y = 0;
    reg display_on = 0;
    
    reg btn_cor_tela = 0;
    reg btn_cor_quadrado = 0;
    reg btn_modo = 0;

    wire [3:0] red;
    wire [3:0] green;
    wire [3:0] blue;

    // 25.175 MHz -> period ~39.72 ns
    always #19.861 clk = ~clk;

    vga_display uut (
        .clk(clk),
        .reset(rst),
        .hsinc(pixel_x),
        .vsinc(pixel_y),
        .area_visivel(display_on),
        .botao_cor_tela(btn_cor_tela),
        .botao_cor_quadrado(btn_cor_quadrado),
        .botao_modo(btn_modo),
        .R(red),
        .G(green),
        .B(blue)
    );

    initial begin
        $dumpfile("vga_display.vcd");
        $dumpvars(0, tb_vga_display);

        // Reset
        #100;
        rst = 0;

        // Test Mode Change
        #1000;
        btn_modo = 1;
        #100;
        btn_modo = 0; // Mode 1
        
        // Drive pixel coordinates to check display output
        // Simulate a few pixels
        display_on = 1;
        pixel_x = 320;
        pixel_y = 240;
        #200;
        
        // Check output (expect white for crosshair mode if active)
        $display("Time=%t R=%h G=%h B=%h", $time, red, green, blue);

        // Advance to next mode (Checkerboard)
        #1000;
        btn_modo = 1;
        #100;
        btn_modo = 0;
        
        // Test checkerboard pattern
        pixel_x = 32; pixel_y = 32; // Should be white?
        #100;
        $display("Checkerboard 32,32: R=%h G=%h B=%h", red, green, blue);
        
        pixel_x = 0; pixel_y = 0; // Should be black?
        #100;
        $display("Checkerboard 0,0: R=%h G=%h B=%h", red, green, blue);

        $finish;
    end

endmodule
