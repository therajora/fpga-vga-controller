// clock_div.v — Divisor de Clock / PLL para VGA
//
// Quartus (sintese): ALTPLL 50 MHz × 91/181 = 25.138 MHz (~0.15% erro)
// Simulacao:         divisor /2 = 25.000 MHz (~0.70% erro, dentro da tolerancia VGA)
//
// QUARTUS_VERSION e definido automaticamente pelo Quartus — nao e necessario setar nada.
// Para usar o PLL, gere o wrapper via IP Catalog → ALTPLL e salve como pll_25mhz.v.

module clock_div (
    input  wire clk_in,     // Clock do sistema (50 MHz)
    input  wire rst,        // Reset ativo alto
    output wire clk_pixel,  // Pixel clock (~25 MHz)
    output wire locked      // 1 = clock estavel
);

`ifdef QUARTUS_VERSION
    // ALTPLL gerado pelo Quartus IP Catalog (Tools → IP Catalog → ALTPLL)
    // Input: 50 MHz  |  Output c0: 25.175 MHz  |  Multiply=91, Divide=181
    pll_25mhz u_pll (
        .inclk0 (clk_in),
        .c0     (clk_pixel),
        .locked (locked)
    );

`else
    // Divisor por 2 para simulacao
    reg clk_div_r;

    always @(posedge clk_in or posedge rst) begin
        if (rst)
            clk_div_r <= 1'b0;
        else
            clk_div_r <= ~clk_div_r;
    end

    assign clk_pixel = clk_div_r;
    assign locked    = ~rst;

`endif

endmodule
