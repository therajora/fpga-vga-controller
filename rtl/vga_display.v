// vga_display.v — Gerador de pixels RGB
//
// Modos (btn_mode para alternar):
//   00 = Bouncing Box
//   01 = Checkerboard 32x32
//   10 = Mira de calibracao (crosshair + grid)
//   11 = Barras de cor SMPTE

module vga_display (
    input  wire        clk_pixel,
    input  wire        rst,
    input  wire [9:0]  pixel_x,
    input  wire [9:0]  pixel_y,
    input  wire        video_on,
    input  wire        frame_end,
    input  wire        btn_mode,
    input  wire        btn_pause,
    input  wire        btn_speed,
    input  wire        btn_color,
    output reg  [7:0]  r,
    output reg  [7:0]  g,
    output reg  [7:0]  b
);

localparam SCREEN_W = 640;
localparam SCREEN_H = 480;

// Deteccao de borda dos botoes (rising edge)
reg btn_mode_prev, btn_pause_prev, btn_speed_prev, btn_color_prev;
wire mode_edge  = btn_mode  & ~btn_mode_prev;
wire pause_edge = btn_pause & ~btn_pause_prev;
wire speed_edge = btn_speed & ~btn_speed_prev;
wire color_edge = btn_color & ~btn_color_prev;

always @(posedge clk_pixel or posedge rst) begin
    if (rst) begin
        btn_mode_prev  <= 0; btn_pause_prev <= 0;
        btn_speed_prev <= 0; btn_color_prev <= 0;
    end else begin
        btn_mode_prev  <= btn_mode;  btn_pause_prev <= btn_pause;
        btn_speed_prev <= btn_speed; btn_color_prev <= btn_color;
    end
end

// Estado global
reg [1:0] display_mode;
reg       paused, fast_mode;
reg [1:0] color_sel;

always @(posedge clk_pixel or posedge rst) begin
    if (rst) begin
        display_mode <= 0; paused <= 0; fast_mode <= 0; color_sel <= 0;
    end else begin
        if (mode_edge)  display_mode <= display_mode + 1;
        if (pause_edge) paused       <= ~paused;
        if (speed_edge) fast_mode    <= ~fast_mode;
        if (color_edge) color_sel    <= color_sel + 1;
    end
end

// --- Modo 00: Bouncing Box ---
localparam BOX_SIZE = 40;
reg [9:0] box_x, box_y;
reg       dir_x, dir_y;
wire [2:0] speed = fast_mode ? 3'd4 : 3'd2;

always @(posedge clk_pixel or posedge rst) begin
    if (rst) begin
        box_x <= 100; box_y <= 80; dir_x <= 0; dir_y <= 0;
    end else if (frame_end && !paused) begin
        if (!dir_x) begin
            if (box_x + BOX_SIZE + speed >= SCREEN_W) begin dir_x <= 1; box_x <= SCREEN_W - BOX_SIZE - 1; end
            else box_x <= box_x + {7'd0, speed};
        end else begin
            if (box_x < {7'd0, speed}) begin dir_x <= 0; box_x <= 0; end
            else box_x <= box_x - {7'd0, speed};
        end
        if (!dir_y) begin
            if (box_y + BOX_SIZE + speed >= SCREEN_H) begin dir_y <= 1; box_y <= SCREEN_H - BOX_SIZE - 1; end
            else box_y <= box_y + {7'd0, speed};
        end else begin
            if (box_y < {7'd0, speed}) begin dir_y <= 0; box_y <= 0; end
            else box_y <= box_y - {7'd0, speed};
        end
    end
end

wire in_box = (pixel_x >= box_x) && (pixel_x < box_x + BOX_SIZE) &&
              (pixel_y >= box_y) && (pixel_y < box_y + BOX_SIZE);
wire in_box_border = in_box && (
    (pixel_x < box_x + 2) || (pixel_x >= box_x + BOX_SIZE - 2) ||
    (pixel_y < box_y + 2) || (pixel_y >= box_y + BOX_SIZE - 2));

reg [7:0] box_r, box_g, box_b;
always @(*) begin
    case (color_sel)
        2'b00: begin box_r = 8'h00; box_g = 8'hFF; box_b = 8'hFF; end
        2'b01: begin box_r = 8'h00; box_g = 8'hFF; box_b = 8'h00; end
        2'b10: begin box_r = 8'hFF; box_g = 8'h00; box_b = 8'hFF; end
        2'b11: begin box_r = 8'hFF; box_g = 8'hFF; box_b = 8'h00; end
    endcase
end

reg [7:0] bounce_r, bounce_g, bounce_b;
always @(*) begin
    if (in_box_border)     begin bounce_r = 8'hFF; bounce_g = 8'hFF; bounce_b = 8'hFF; end
    else if (in_box)       begin bounce_r = box_r;  bounce_g = box_g;  bounce_b = box_b;  end
    else begin
        bounce_r = 8'h08; bounce_g = 8'h08;
        bounce_b = {2'b00, pixel_y[8:3]};
    end
end

// --- Modo 01: Checkerboard ---
wire check_pat = pixel_x[5] ^ pixel_y[5];
wire [7:0] check_r = check_pat ? 8'hFF : 8'h00;
wire [7:0] check_g = check_pat ? 8'hFF : 8'h00;
wire [7:0] check_b = check_pat ? 8'hFF : 8'h00;

// --- Modo 10: Mira ---
wire cross_h     = (pixel_y >= 238) && (pixel_y <= 241);
wire cross_v     = (pixel_x >= 318) && (pixel_x <= 321);
wire border_px   = (pixel_x == 0) || (pixel_x == SCREEN_W-1) ||
                   (pixel_y == 0) || (pixel_y == SCREEN_H-1);
wire grid_h      = (pixel_x % 80 == 0);
wire grid_v      = (pixel_y % 80 == 0);
wire signed [10:0] dx = pixel_x - 320;
wire signed [10:0] dy = pixel_y - 240;
wire [21:0] dist_sq = dx*dx + dy*dy;
wire circle = (dist_sq >= 22'd3481) && (dist_sq <= 22'd3721);

reg [7:0] mira_r, mira_g, mira_b;
always @(*) begin
    if      (cross_h || cross_v) begin mira_r = 8'hFF; mira_g = 8'h00; mira_b = 8'h00; end
    else if (circle)             begin mira_r = 8'hFF; mira_g = 8'hFF; mira_b = 8'h00; end
    else if (border_px)          begin mira_r = 8'hFF; mira_g = 8'hFF; mira_b = 8'hFF; end
    else if (grid_h || grid_v)   begin mira_r = 8'h40; mira_g = 8'h40; mira_b = 8'h40; end
    else                         begin mira_r = 8'h00; mira_g = 8'h00; mira_b = 8'h00; end
end

// --- Modo 11: Barras de cor ---
reg [7:0] bar_r, bar_g, bar_b;
always @(*) begin
    case (pixel_x / 80)
        0: begin bar_r=8'hFF; bar_g=8'hFF; bar_b=8'hFF; end
        1: begin bar_r=8'hFF; bar_g=8'hFF; bar_b=8'h00; end
        2: begin bar_r=8'h00; bar_g=8'hFF; bar_b=8'hFF; end
        3: begin bar_r=8'h00; bar_g=8'hFF; bar_b=8'h00; end
        4: begin bar_r=8'hFF; bar_g=8'h00; bar_b=8'hFF; end
        5: begin bar_r=8'hFF; bar_g=8'h00; bar_b=8'h00; end
        6: begin bar_r=8'h00; bar_g=8'h00; bar_b=8'hFF; end
        default: begin bar_r=8'h00; bar_g=8'h00; bar_b=8'h00; end
    endcase
end

// --- Mux de saida ---
always @(*) begin
    if (!video_on) begin r = 0; g = 0; b = 0; end
    else case (display_mode)
        2'b00: begin r = bounce_r; g = bounce_g; b = bounce_b; end
        2'b01: begin r = check_r;  g = check_g;  b = check_b;  end
        2'b10: begin r = mira_r;   g = mira_g;   b = mira_b;   end
        2'b11: begin r = bar_r;    g = bar_g;     b = bar_b;    end
    endcase
end

endmodule
