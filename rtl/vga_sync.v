module vga_sync #(
    parameter H_VISIBLE = 640,
    parameter H_FRONT   = 16,
    parameter H_SYNC    = 96,
    parameter H_BACK    = 48,
    parameter V_VISIBLE = 480,
    parameter V_FRONT   = 10,
    parameter V_SYNC    = 2,
    parameter V_BACK    = 33
) (
    input  wire clk,
    input  wire rst,
    output reg  hsync,
    output reg  vsync,
    output wire display,
    output wire [9:0] pixel_x,
    output wire [9:0] pixel_y
);

    // Derived parameters
    localparam H_TOTAL = H_VISIBLE + H_FRONT + H_SYNC + H_BACK; // 800
    localparam V_TOTAL = V_VISIBLE + V_FRONT + V_SYNC + V_BACK; // 525

    reg [9:0] h_count;
    reg [9:0] v_count;

    // Horizontal and Vertical Counters
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            h_count <= 0;
            v_count <= 0;
        end else begin
            if (h_count == H_TOTAL - 1) begin
                h_count <= 0;
                if (v_count == V_TOTAL - 1)
                    v_count <= 0;
                else
                    v_count <= v_count + 1;
            end else begin
                h_count <= h_count + 1;
            end
        end
    end

    // HSYNC Signal Generation (Active Low)
    always @(posedge clk or posedge rst) begin
        if (rst)
            hsync <= 1;
        else if (h_count >= (H_VISIBLE + H_FRONT) && 
                 h_count <  (H_VISIBLE + H_FRONT + H_SYNC))
            hsync <= 0;
        else
            hsync <= 1;
    end

    // VSYNC Signal Generation (Active Low)
    always @(posedge clk or posedge rst) begin
        if (rst)
            vsync <= 1;
        else if (v_count >= (V_VISIBLE + V_FRONT) && 
                 v_count <  (V_VISIBLE + V_FRONT + V_SYNC))
            vsync <= 0;
        else
            vsync <= 1;
    end

    // Display Enable (Active High) & Pixel Coordinates
    assign display = (h_count < H_VISIBLE) && (v_count < V_VISIBLE);
    assign pixel_x = h_count;
    assign pixel_y = v_count;

endmodule
