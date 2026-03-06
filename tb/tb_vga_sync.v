`timescale 1ns/1ps

module tb_vga_sync;

    reg clk = 0;
    reg rst = 1;

    wire hsync;
    wire vsync;
    wire display;
    wire [9:0] pixel_x;
    wire [9:0] pixel_y;

    // 25.175 MHz -> period ~39.72 ns
    always #19.861 clk = ~clk;

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
        $dumpfile("vga_sync.vcd");
        $dumpvars(0, tb_vga_sync);

        // Reset sequence
        #100;
        rst = 0;

        // Run for enough time to see at least one full line and part of next
        // One line = 800 pixels * 39.72 ns = 31776 ns
        // One frame = 525 lines * 31776 ns = 16.68 ms
        
        // Wait for HSYNC pulse
        wait(hsync == 0);
        $display("HSYNC pulse detected at %t", $time);
        wait(hsync == 1);
        $display("HSYNC pulse ended at %t", $time);

        // Wait for VSYNC pulse (will take a while in simulation)
        // We can check pixel counters instead to speed up or run longer
        
        #100000; // 100 us
        
        $finish;
    end

endmodule
