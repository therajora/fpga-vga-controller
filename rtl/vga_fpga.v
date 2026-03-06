module vga_fpga (
    input  wire clk,        // 50 MHz
    input  wire rst,        // Reset
    input  wire button1,    // Cor Tela
    input  wire button2,    // Cor Quadrado
    input  wire button3,    // Modo

    output wire hsync,
    output wire vsync,
    output wire [3:0] red,
    output wire [3:0] green,
    output wire [3:0] blue
);

    wire clk_25m;
    wire locked;

    // PLL instantiation
    // Generates 25.175 MHz from 50 MHz
    vga_pll pll_inst (
        .inclk0(clk),
        .c0(clk_25m),
        .locked(locked)
    );

    // Core logic
    vga_top top_inst (
        .clk(clk_25m),
        .reset(rst),
        .botao_cor_tela(button1),
        .botao_cor_quadrado(button2),
        .botao_modo(button3),
        .hsync(hsync),
        .vsync(vsync),
        .R(red),
        .G(green),
        .B(blue)
    );

endmodule
