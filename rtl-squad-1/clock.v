module vga_sync (
    input  wire clk,          
    input  wire rst,          
    output reg  hsync,        
    output reg  vsync,        
    output wire display,  //1 para ligado e 0 desligado 
    output wire [9:0] pixel_x,
    output wire [9:0] pixel_y 
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


// Sincronizacao Horizontal (HSYNC)

always @(posedge clk or posedge rst) begin
    if (rst)
        hsync <= 1;
    else if (h_count >= (H_VISIBLE + H_FRONT) &&
             h_count <= (H_VISIBLE + H_FRONT + H_SYNC - 1))
        hsync <= 0;  // padrão VGA ativo em nível baixo
    else
        hsync <= 1;
end

// Sincronizacao Vertical (VSYNC)

always @(posedge clk or posedge rst) begin
    if (rst)
        vsync <= 1;
    else if (v_count >= (V_VISIBLE + V_FRONT) &&
             v_count <= (V_VISIBLE + V_FRONT + V_SYNC - 1))
        vsync <= 0;  // padrão VGA ativo em nível baixo
    else
        vsync <= 1;
end


// Vizualizacao


assign display = (h_count < H_VISIBLE) &&
                    (v_count < V_VISIBLE);

assign pixel_x = h_count; //coordenada atual do pixel
assign pixel_y = v_count;

endmodule
