module vga_display #(
    parameter H_RES = 640,
    parameter V_RES = 480,
    parameter SQUARE_SIZE = 50
) (
    input  wire        clk,
    input  wire        reset,
    input  wire [9:0]  pixel_x,
    input  wire [9:0]  pixel_y,
    input  wire        video_on,

    input  wire        btn_color_bg,
    input  wire        btn_color_sq,
    input  wire        btn_mode,

    output reg  [3:0]  R,
    output reg  [3:0]  G,
    output reg  [3:0]  B
);

    // --- State Definitions ---
    localparam MODE_SQUARE = 2'd0;
    localparam MODE_CROSS  = 2'd1;
    localparam MODE_CHECKER = 2'd2;

    // --- Internal Signals ---
    reg [1:0] current_mode;
    
    // Square position and velocity
    reg [9:0] sq_x, sq_y;
    reg signed [3:0] vel_x, vel_y;

    // Color selections
    reg [1:0] sel_color_sq;
    reg [1:0] sel_color_bg;

    // Button synchronization (Debounce logic simplified to edge detection for simulation)
    // In a real FPGA, a proper debounce module is recommended.
    reg [1:0] sync_mode, sync_bg, sync_sq;
    wire tick_mode, tick_bg, tick_sq;

    always @(posedge clk) begin
        sync_mode <= {sync_mode[0], btn_mode};
        sync_bg   <= {sync_bg[0], btn_color_bg};
        sync_sq   <= {sync_sq[0], btn_color_sq};
    end

    assign tick_mode = (sync_mode == 2'b01); // Rising edge
    assign tick_bg   = (sync_bg   == 2'b01);
    assign tick_sq   = (sync_sq   == 2'b01);

    // --- Logic for Square Movement ---
    wire frame_tick = (pixel_x == 799 && pixel_y == 524); // End of frame

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            sq_x <= 200;
            sq_y <= 150;
            vel_x <= 1;
            vel_y <= 1;
        end else if (frame_tick) begin
            // Update position
            sq_x <= sq_x + vel_x;
            sq_y <= sq_y + vel_y;

            // Bounce horizontal
            if (sq_x <= 0) 
                vel_x <= 1;
            else if (sq_x + SQUARE_SIZE >= H_RES) 
                vel_x <= -1;

            // Bounce vertical
            if (sq_y <= 0) 
                vel_y <= 1;
            else if (sq_y + SQUARE_SIZE >= V_RES) 
                vel_y <= -1;
        end
    end

    // --- State Machine & Control ---
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            current_mode <= MODE_SQUARE;
            sel_color_sq <= 0;
            sel_color_bg <= 0;
        end else begin
            if (tick_mode) begin
                if (current_mode == MODE_CHECKER)
                    current_mode <= MODE_SQUARE;
                else
                    current_mode <= current_mode + 1;
            end

            if (tick_bg) sel_color_bg <= sel_color_bg + 1;
            if (tick_sq) sel_color_sq <= sel_color_sq + 1;
        end
    end

    // --- Rendering Logic ---
    wire in_square = (pixel_x >= sq_x) && (pixel_x < sq_x + SQUARE_SIZE) &&
                     (pixel_y >= sq_y) && (pixel_y < sq_y + SQUARE_SIZE);

    always @(posedge clk) begin
        if (!video_on) begin
            {R, G, B} <= 12'h000;
        end else begin
            case (current_mode)
                MODE_SQUARE: begin
                    if (in_square) begin
                        case (sel_color_sq)
                            0: {R, G, B} <= 12'hF00; // Red
                            1: {R, G, B} <= 12'h0F0; // Green
                            2: {R, G, B} <= 12'h00F; // Blue
                            3: {R, G, B} <= 12'hFF0; // Yellow
                        endcase
                    end else begin
                        case (sel_color_bg)
                            0: {R, G, B} <= 12'h000; // Black
                            1: {R, G, B} <= 12'h0FF; // Cyan
                            2: {R, G, B} <= 12'hF0F; // Magenta
                            3: {R, G, B} <= 12'h888; // Gray
                        endcase
                    end
                end

                MODE_CROSS: begin
                    if (pixel_x == H_RES/2 || pixel_y == V_RES/2)
                        {R, G, B} <= 12'hFFF; // White crosshair
                    else
                        {R, G, B} <= 12'h000;
                end

                MODE_CHECKER: begin
                    // 32x32 checkerboard pattern
                    if (pixel_x[5] ^ pixel_y[5])
                        {R, G, B} <= 12'hFFF;
                    else
                        {R, G, B} <= 12'h000;
                end

                default: {R, G, B} <= 12'h000;
            endcase
        end
    end

endmodule
