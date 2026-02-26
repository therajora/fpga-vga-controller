// vga_top.v — Top-level: clock_div + vga_sync + debounce x4 + vga_display

module vga_top (
    input  wire       clk_50,
    input  wire       rst,
    input  wire [3:0] btn,       // [mode, pause, speed, color]
    output wire       hsync,
    output wire       vsync,
    output wire       video_on,
    output wire [7:0] r,
    output wire [7:0] g,
    output wire [7:0] b,
    output wire       pll_locked,
    output wire       frame_end
);

wire clk_pixel;

clock_div u_clk (
    .clk_in    (clk_50),
    .rst       (rst),
    .clk_pixel (clk_pixel),
    .locked    (pll_locked)
);

wire [9:0] pixel_x, pixel_y;
wire       h_video, v_video, line_end;

vga_sync u_sync (
    .clk        (clk_pixel),
    .rst        (rst),
    .hsync      (hsync),
    .vsync      (vsync),
    .pixel_x    (pixel_x),
    .pixel_y    (pixel_y),
    .video_on   (video_on),
    .h_video    (h_video),
    .v_video    (v_video),
    .pixel_tick (),
    .line_end   (line_end),
    .frame_end  (frame_end),
    .display    ()
);

wire [3:0] btn_db;

genvar gi;
generate
    for (gi = 0; gi < 4; gi = gi + 1) begin : gen_debounce
        debounce #(.COUNTER_BITS(18), .STABLE_COUNT(3)) u_db (
            .clk     (clk_pixel),
            .rst     (rst),
            .btn_in  (btn[gi]),
            .btn_out (btn_db[gi])
        );
    end
endgenerate

vga_display u_display (
    .clk_pixel  (clk_pixel),
    .rst        (rst),
    .pixel_x    (pixel_x),
    .pixel_y    (pixel_y),
    .video_on   (video_on),
    .frame_end  (frame_end),
    .btn_mode   (btn_db[0]),
    .btn_pause  (btn_db[1]),
    .btn_speed  (btn_db[2]),
    .btn_color  (btn_db[3]),
    .r          (r),
    .g          (g),
    .b          (b)
);

endmodule
