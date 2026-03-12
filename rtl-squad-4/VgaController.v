module VgaController (
    input clk, rst, button1, button2, button3,            
    input [3:0] Rin, Gin, Bin,
	 //output clkOut, hSyncOut, vSyncOut,
    output [3:0] Rout, Gout, Bout,
    output hSync, vSync 
);

wire [9:0] pixelX, pixelY;
wire videoAreaOn;

vga_pll	vga_pll_inst (
		.inclk0 ( clk ),
		.c0 ( c0_sig ),
		.locked ( locked_sig )
		);

VgaSync VgaSync (
		 .clk(c0_sig), 
		 .rst(rst),
		 .hSync(hSync),
		 .vSync(vSync),
		 .pixelX(pixelX),
		 .pixelY(pixelY),
		 .videoAreaOn(videoAreaOn)
 );
	 
VgaDisplay VgaDisplay(
		.clk(c0_sig),                
		.rst(rst),       
		.button1(button1),  
		.button2(button2),
		.button3(button3),
		.pixelX(pixelX),
		.pixelY(pixelY),
		.videoAreaOn(videoAreaOn),          
		.Rout(Rout),
		.Bout(Bout),
		.Gout(Gout)
);
	 
endmodule