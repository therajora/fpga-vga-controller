`timescale 1ns / 1ps

module vga_pll (
    input  wire inclk0, // 50 MHz input
    output reg  c0,     // ~25.175 MHz output
    output reg  locked
);

    // 25.175 MHz -> Period = 39.7219 ns
    // Half period = 19.8609 ns
    
    initial begin
        c0 = 0;
        locked = 0;
        #100;
        locked = 1;
    end

    // Use a delay to simulate the clock frequency
    // Note: This ignores inclk0 phase but generates correct frequency for testbench
    always begin
        #19.861 c0 = ~c0;
    end

endmodule
