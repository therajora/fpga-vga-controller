module vga_sync (
    input  wire        clk,
    input  wire        rst,
    output wire        hsync,        // Horizontal sync (ativo LOW)
    output wire        vsync,        // Vertical sync   (ativo LOW)
    output wire        display,      // 1 = area visivel (alias de video_on)
    output wire [9:0]  pixel_x,      // Coordenada horizontal atual (0..799)
    output wire [9:0]  pixel_y,      // Coordenada vertical atual   (0..524)
    output wire        h_video,      // 1 = dentro da area horizontal visivel
    output wire        v_video,      // 1 = dentro da area vertical visivel
    output wire        video_on,     // 1 = pixel ativo (h_video && v_video)
    output wire        pixel_tick,   // Pulso a cada pixel (= clk aqui)
    output wire        line_end,     // Pulso no fim de cada linha
    output wire        frame_end     // Pulso no fim de cada frame
);

// Definicao de projeto

localparam H_VISIBLE = 640;   // Área horizontal
localparam H_FRONT   = 16;    // Front porch (pausa antes do sinal de sincronismo)
localparam H_SYNC    = 96;    // Pulso de sincronismo (resetar a posição)
localparam H_BACK    = 48;    // Back porch (estabilização antes de começar a desenhar )
localparam H_TOTAL   = 800;   // Total horizontal

localparam V_VISIBLE = 480;   // Área visível vertical
localparam V_FRONT   = 10;    // Área morta
localparam V_SYNC    = 2;
localparam V_BACK    = 33;    // Área morta
localparam V_TOTAL   = 525;   // Área total



//Contador 

reg [9:0] h_count;   // Conta pixels (0–799)
reg [9:0] v_count;   // Conta linhas (0–524)

always @(posedge clk or posedge rst) begin
    if (rst) begin
        h_count <= 0;
        v_count <= 0;
    end else begin

        // Incrementa pixel
        if (h_count == H_TOTAL-1) begin
            h_count <= 0;

            // Incrementa linha ao terminar 
            if (v_count == V_TOTAL-1)
                v_count <= 0;
            else
                v_count <= v_count + 1;

        end else begin
            h_count <= h_count + 1;
        end

    end
end


// Sincronizacao Horizontal e Vertical (combinatorio, sem atraso de 1 ciclo)

assign hsync = ~((h_count >= (H_VISIBLE + H_FRONT)) &&
                  (h_count <  (H_VISIBLE + H_FRONT + H_SYNC)));

assign vsync = ~((v_count >= (V_VISIBLE + V_FRONT)) &&
                  (v_count <  (V_VISIBLE + V_FRONT + V_SYNC)));

// Area visivel

assign h_video    = (h_count < H_VISIBLE);
assign v_video    = (v_count < V_VISIBLE);
assign video_on   = h_video && v_video;
assign display    = video_on;

// Coordenadas e eventos de temporizacao

assign pixel_x    = h_count;
assign pixel_y    = v_count;
assign pixel_tick = 1'b1;
assign line_end   = (h_count == H_TOTAL - 1);
assign frame_end  = line_end && (v_count == V_TOTAL - 1);

endmodule
