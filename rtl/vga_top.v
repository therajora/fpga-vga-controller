// `include "vga_display.v"
// `include "vga_sync.v"

module vga_top (
    input  wire clk,                // 25 MHz
    input  wire reset,

    input  wire botao_cor_tela,
    input  wire botao_cor_quadrado,
    input  wire botao_modo,

    output wire hsync,
    output wire vsync,

    output wire [3:0] R,
    output wire [3:0] G,
    output wire [3:0] B
);

    // Sinais internos de conexão
    wire [9:0] pixel_x;
    wire [9:0] pixel_y;
    wire       display;

    // Instância do sincronismo
    vga_sync sync_inst (
        .clk(clk),
        .rst(reset),
        .hsync(hsync),
        .vsync(vsync),
        .display(display),
        .pixel_x(pixel_x),
        .pixel_y(pixel_y)
    );

    // Instância do display
    vga_display display_inst (
        .clk(clk),
        .reset(reset),
        .hsinc(pixel_x),
        .vsinc(pixel_y),
        .area_visivel(display),

        .botao_cor_tela(botao_cor_tela),
        .botao_cor_quadrado(botao_cor_quadrado),
        .botao_modo(botao_modo),

        .R(R),
        .G(G),
        .B(B)
    );

endmodule