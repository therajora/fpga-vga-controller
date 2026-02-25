`timescale 1ns/1ps

module tb_vga_sync;

// Parametros esperados VESA 640x480 @ 60Hz
localparam H_TOTAL  = 800;
localparam V_TOTAL  = 525;
localparam H_ACTIVE = 640;
localparam V_ACTIVE = 480;
localparam H_SYNC_W = 96;
localparam V_SYNC_W = 2;
localparam H_FRONT  = 16;
localparam H_BACK   = 48;
localparam V_FRONT  = 10;
localparam V_BACK   = 33;

// 25.175 MHz → periodo 39.721946 ns
localparam CLK_HALF = 19.86097;

reg clk = 0;
reg rst = 1;

wire        hsync;
wire        vsync;
wire        display;
wire [9:0]  pixel_x;
wire [9:0]  pixel_y;
wire        h_video;
wire        v_video;
wire        video_on;
wire        pixel_tick;
wire        line_end;
wire        frame_end;

always #CLK_HALF clk = ~clk;

vga_sync uut (
    .clk        (clk),
    .rst        (rst),
    .hsync      (hsync),
    .vsync      (vsync),
    .display    (display),
    .pixel_x    (pixel_x),
    .pixel_y    (pixel_y),
    .h_video    (h_video),
    .v_video    (v_video),
    .video_on   (video_on),
    .pixel_tick (pixel_tick),
    .line_end   (line_end),
    .frame_end  (frame_end)
);

// Contadores de resultado
integer pass_count = 0;
integer fail_count = 0;
integer test_num   = 0;

task check(input integer cond, input [255:0] nome);
begin
    test_num = test_num + 1;
    if (cond) begin
        $display("  [PASS] %0d: %0s", test_num, nome);
        pass_count = pass_count + 1;
    end else begin
        $display("  [FAIL] %0d: %0s", test_num, nome);
        fail_count = fail_count + 1;
    end
end
endtask

integer i, cycle;
integer h_count_meas, h_active_meas, hsync_w_meas;
integer h_front_meas, h_back_meas;
integer v_count_meas, v_active_meas, vsync_w_meas;
integer v_front_meas, v_back_meas;
integer frame_end_count, line_end_count;
integer integrity_errors;

initial begin
    #100;
    rst = 0;
    @(posedge clk);

    // --- Timing horizontal ---
    // Amostra sinais combinatorios antes do clock: espera pixel_x==0 sem avancar
    wait(pixel_x == 0);

    h_count_meas  = 0;
    h_active_meas = 0;
    hsync_w_meas  = 0;
    h_front_meas  = 0;
    h_back_meas   = 0;

    begin : h_medir
        reg sync_visto;
        sync_visto = 0;

        for (i = 0; i < H_TOTAL + 5; i = i + 1) begin
            h_count_meas = h_count_meas + 1;
            if (video_on)  h_active_meas = h_active_meas + 1;
            if (!hsync)    hsync_w_meas  = hsync_w_meas  + 1;
            if (!h_video && hsync && !sync_visto) h_front_meas = h_front_meas + 1;
            if (!hsync)    sync_visto = 1;
            if (hsync && sync_visto && !h_video)  h_back_meas  = h_back_meas  + 1;
            @(posedge clk);
            if (pixel_x == 0) disable h_medir;
        end
    end

    $display("-- Horizontal --");
    check(h_count_meas  == H_TOTAL,  "total pixels = 800");
    check(h_active_meas == H_ACTIVE, "pixels ativos = 640");
    check(hsync_w_meas  == H_SYNC_W, "largura hsync = 96");
    check(h_front_meas  == H_FRONT,  "front porch H = 16");
    check(h_back_meas   == H_BACK,   "back porch H = 48");

    // --- Timing vertical ---
    wait(pixel_y == 0 && pixel_x == 0);
    @(posedge clk);

    v_count_meas   = 0;
    v_active_meas  = 0;
    vsync_w_meas   = 0;
    v_front_meas   = 0;
    v_back_meas    = 0;
    frame_end_count = 0;
    line_end_count  = 0;

    begin : v_medir
        reg sync_visto;
        reg passou_ativo;
        sync_visto   = 0;
        passou_ativo = 0;

        for (cycle = 0; cycle < H_TOTAL * V_TOTAL + 100; cycle = cycle + 1) begin
            if (line_end) begin
                line_end_count = line_end_count + 1;
                if (v_video) begin
                    v_active_meas = v_active_meas + 1;
                end else begin
                    passou_ativo = 1;
                    if (!sync_visto && vsync)  v_front_meas = v_front_meas + 1;
                    if (!vsync)               begin vsync_w_meas = vsync_w_meas + 1; sync_visto = 1; end
                    if (sync_visto && vsync)   v_back_meas  = v_back_meas  + 1;
                end
            end
            if (frame_end) frame_end_count = frame_end_count + 1;
            @(posedge clk);
            if (frame_end_count >= 1 && pixel_y == 0 && pixel_x < 5) disable v_medir;
        end
    end

    v_count_meas = line_end_count;

    $display("-- Vertical --");
    check(v_count_meas  == V_TOTAL,  "total linhas = 525");
    check(v_active_meas == V_ACTIVE, "linhas ativas = 480");
    check(vsync_w_meas  == V_SYNC_W, "largura vsync = 2");
    check(v_front_meas  == V_FRONT,  "front porch V = 10");
    check(v_back_meas   == V_BACK,   "back porch V = 33");
    check(frame_end_count == 1,      "frame_end pulsa 1x por frame");

    // --- Integridade dos sinais ---
    integrity_errors = 0;
    for (cycle = 0; cycle < H_TOTAL * 10; cycle = cycle + 1) begin
        if (video_on !== (h_video && v_video)) integrity_errors = integrity_errors + 1;
        if ((pixel_x >= H_ACTIVE || pixel_y >= V_ACTIVE) && video_on)
            integrity_errors = integrity_errors + 1;
        @(posedge clk);
    end

    $display("-- Integridade --");
    check(integrity_errors == 0, "video_on = h_video AND v_video sempre");
    check(display == video_on,   "display == video_on");

    // --- Resultado ---
    $display("");
    $display("Resultado: %0d passou, %0d falhou de %0d testes",
             pass_count, fail_count, test_num);

    $finish;
end

// VCD para visualizacao de formas de onda
initial begin
    $dumpfile("tb_clock.vcd");
    $dumpvars(0, tb_vga_sync);
end

// Watchdog: 3 frames
initial begin
    #(CLK_HALF * 2 * H_TOTAL * V_TOTAL * 3);
    $display("[TIMEOUT] Simulacao excedeu 3 frames.");
    $finish;
end

endmodule
