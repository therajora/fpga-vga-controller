`timescale 1ns/1ps

module tb_vga_sync;

reg clk = 0;
reg rst = 1;

wire hsync;
wire vsync;
wire display;
wire [9:0] pixel_x;
wire [9:0] pixel_y;

// 25,175 MHz → período 39.721946 ns
always #19.86097 clk = ~clk;

vga_sync uut (
    .clk(clk),
    .rst(rst),
    .hsync(hsync),
    .vsync(vsync),
    .display(display),
    .pixel_x(pixel_x),
    .pixel_y(pixel_y)
);



initial begin
    
    #100;
    rst = 0;

    // Simula 200 microsegundos (ideal para ver HSYNC)
    // #200000;

    #40000000;  // 40 ms (2 frames, ideal para ver VSYNC)

    $stop;
end

endmodule