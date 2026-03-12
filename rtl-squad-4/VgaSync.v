 module VgaSync (
		input clk, rst,
		output hSync, vSync, 
		output [9:0]	pixelX,pixelY,
		output  videoAreaOn
);

    localparam H_DESENHO        = 640;
    localparam H_FRONT_PORCH    = 16;
    localparam H_SYNC           = 96;
    localparam H_BACK_PORCH     = 48;
    localparam H_TOTAL          = 800; 

    localparam V_DESENHO        = 480;
    localparam V_FRONT_PORCH    = 10;
    localparam V_SYNC           = 2;
    localparam V_BACK_PORCH     = 33;
    localparam V_TOTAL          = 525;


		
	reg [9:0] hCount;
	reg [9:0] vCount;
		 
	 assign videoAreaOn = ((hCount < H_DESENHO) && (vCount < V_DESENHO));
	 assign hSync = ~((hCount >= H_DESENHO + H_FRONT_PORCH) && (hCount < H_DESENHO + H_FRONT_PORCH + H_SYNC));
	 assign vSync = ~((vCount >= V_DESENHO + V_FRONT_PORCH) && (vCount < V_DESENHO + V_FRONT_PORCH + V_SYNC));
	 assign pixelX = (hCount < H_DESENHO) ? hCount : 10'd0;
	 assign pixelY = (vCount < V_DESENHO) ? vCount : 10'd0;
	 
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            hCount <= 0;
            vCount <= 0;
        end else begin
            // Lógica de contagem paralela (padrão industrial)
            if (hCount == H_TOTAL-1) begin           
                hCount <= 0;
                if (vCount == V_TOTAL-1)
                    vCount <= 0;
                else
                    vCount <= vCount + 1;
            end else begin
                hCount <= hCount + 1;
            end
        end
    end
endmodule		 