module vga_top (
    input  wire clk,                // 25 MHz
    input  wire reset,

    input  wire btn_color_bg,       // Botão cor de fundo
    input  wire btn_color_sq,       // Botão cor do quadrado
    input  wire btn_mode,           // Botão de modo

    output wire hsync,
    output wire vsync,

    output wire [3:0] R,
    output wire [3:0] G,
    output wire [3:0] B
);

    // Sinais internos de conexão
    wire [9:0] pixel_x;
    wire [9:0] pixel_y;
    wire       video_on;

    // Instância do sincronismo
    vga_sync sync_inst (
        .clk(clk),
        .rst(reset),
        .hsync(hsync),
        .vsync(vsync),
        .display(video_on),
        .pixel_x(pixel_x),
        .pixel_y(pixel_y)
    );

    // Instância do display
    vga_display display_inst (
        .clk(clk),
        .reset(reset),
        .pixel_x(pixel_x),
        .pixel_y(pixel_y),
        .video_on(video_on),

        .btn_color_bg(btn_color_bg),
        .btn_color_sq(btn_color_sq),
        .btn_mode(btn_mode),

        .R(R),
        .G(G),
        .B(B)
    );

endmodule
