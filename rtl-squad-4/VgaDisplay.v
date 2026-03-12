module VgaDisplay (
		input clk, rst, button1, button2, button3,            
		input [9:0] pixelX, pixelY,            
		input videoAreaOn,            
		output reg [3:0] Rout, Bout, Gout   		               
);

localparam TIME_DEBOUNCE		= 1258748;	// Valor para 50ms
localparam TIME_DELAY_BUTTON	= 12500000;	// Valor para 0,41 ms
localparam ESTATE_INITIAL		= 0;
localparam ESTATE_DEBOUNCE		= 10;
localparam ESTATE_IMAGES1		= 20;
localparam ESTATE_IMAGES2		= 30;
localparam ESTATE_IMAGES3		= 40;

integer estateButton = 0, counterTime = 0, image = 0; 
integer directionX = 1, directionY = 1;
integer moveX = 0;
integer moveY = 0;

reg [2:0] colorSquare = 0;

function is_in_rect(
	  input [9:0] pixelX, pixelY,           // Posição atual do scanner
	  input [9:0] originX, originY,         // Origem do retângulo
	  input [9:0] widthX, heightY          // Largura e altura
 );
	  begin
			is_in_rect = (pixelX >= originX && pixelX < originX + widthX) && (pixelY >= originY && pixelY < originY + heightY);
	  end
 endfunction
 
always @(posedge clk or negedge rst) begin
        if(!rst) begin
            // Inicializa tudo no reset 
            Rout <= 0; Gout <= 0; Bout <= 0;
            estateButton <= 0;
            counterTime <= 0;
            image <= 0;
				colorSquare <= 0;
        end
        else begin
            // Máquina de estados dos botões
            case (estateButton)
                ESTATE_INITIAL: begin
                    if(!button1 || !button2 || !button3) estateButton <= ESTATE_DEBOUNCE;
                end
                
                ESTATE_DEBOUNCE: begin // Debounce/Espera
                    if(counterTime > TIME_DEBOUNCE) begin
                        counterTime <= 0;
                        if(!button1)      estateButton <= ESTATE_IMAGES1;
                        else if(!button2) estateButton <= ESTATE_IMAGES2;
                        else if(!button3) estateButton <= ESTATE_IMAGES3;
                        else              estateButton <= ESTATE_INITIAL;
                    end else begin
                        counterTime <= counterTime + 1;
                    end
                end

                ESTATE_IMAGES1: begin // Alterna imagens
                    if(counterTime > TIME_DELAY_BUTTON) begin 
                        counterTime <= 0;
                        if(image >= 6) image <= 0;
                        else image <= image + 1;
                        estateButton <= ESTATE_INITIAL;
                    end else begin
                        counterTime <= counterTime + 1;
                    end
                end

                ESTATE_IMAGES2: begin
                    if(counterTime > TIME_DELAY_BUTTON) begin 
                        counterTime <= 0;
                        if(image < 7) image <= 7;
                        else if(image >= 8) image <= 7;
                        else image <= image + 1;
                        estateButton <= ESTATE_INITIAL;
                    end else begin
                        counterTime <= counterTime + 1;
                    end
                end

                ESTATE_IMAGES3: begin
					     if(counterTime > TIME_DELAY_BUTTON) begin 
                        counterTime <= 0;
								image <= 9;
								if(colorSquare >= 7) colorSquare <= 0;
								else colorSquare <= colorSquare + 1;
                        estateButton <= ESTATE_INITIAL;
                    end else begin
                        counterTime <= counterTime + 1;
                    end
                end
                
                default: estateButton <= 0;
            endcase

            // Lógica de Renderização de Vídeo 
            if (videoAreaOn) begin
                case(image)
                    0: begin Rout <= 4'b1111; Gout <= 4'b0000; Bout <= 4'b0000; end
                    1: begin Rout <= 4'b0000; Gout <= 4'b1111; Bout <= 4'b0000; end
                    2: begin Rout <= 4'b1111; Gout <= 4'b0000; Bout <= 4'b1111; end
                    3: begin Rout <= 4'b1111; Gout <= 4'b1010; Bout <= 4'b0000; end
                    4: begin Rout <= 4'b1111; Gout <= 4'b1111; Bout <= 4'b0000; end
                    5: begin Rout <= 4'b1000; Gout <= 4'b1100; Bout <= 4'b1110; end
                    6: begin Rout <= 4'b1110; Gout <= 4'b1000; Bout <= 4'b1110; end
                    7: begin
								if (pixelX[5] ^ pixelY[5]) begin
									Rout <= 4'b1111; Gout <= 4'b1111; Bout <= 4'b1111;
								end
								else begin
									Rout <= 0; Gout <= 0; Bout <= 0;
								end
                        /*if((pixelY >= 0 && pixelY <= 59) || (pixelY >= 120 && pixelY <= 179) || 
                           (pixelY >= 240 && pixelY <= 299) || (pixelY >= 360 && pixelY <= 419)) begin
                            if((pixelX >= 0 && pixelX <= 79) || (pixelX >= 160 && pixelX <= 239) || 
                               (pixelX >= 320 && pixelX <= 399) || (pixelX >= 480 && pixelX <= 559)) begin
                                Rout <= 0; Gout <= 0; Bout <= 0;
                            end else begin
                                Rout <= 4'b1111; Gout <= 4'b1111; Bout <= 4'b1111;
                            end
                        end
                        else if((pixelY >= 60 && pixelY <= 119) || (pixelY >= 180 && pixelY <= 239) || 
                                (pixelY >= 300 && pixelY <= 359) || (pixelY >= 420 && pixelY <= 479)) begin
                            if((pixelX >= 80 && pixelX <= 159) || (pixelX >= 240 && pixelX <= 319) || 
                               (pixelX >= 400 && pixelX <= 479) || (pixelX >= 560 && pixelX <= 639)) begin
                                Rout <= 0; Gout <= 0; Bout <= 0;
                            end else begin
                                Rout <= 4'b1111; Gout <= 4'b1111; Bout <= 4'b1111;
                            end
                        end*/
                    end
                    8: begin
                        if(pixelY == 240 || pixelX == 320) begin
                            Rout <= 0; Gout <= 0; Bout <= 0;
                        end else begin
                            Rout <= 4'b1111; Gout <= 4'b1111; Bout <= 4'b1111;
                        end
                    end
						  9: begin
								if(pixelX == 639 && pixelY == 479) begin
									if(moveX >= 640 - 50) directionX <= -1;
									else if(moveX == 1) directionX <= 1;
									moveX <= moveX + directionX;
									if(moveY >= 480 - 50) directionY <= -1;
									else if(moveY == 1) directionY <= 1;
									moveY <= moveY + directionY;
								end
								if(is_in_rect(pixelX, pixelY, moveX, moveY, 50, 50)) begin
									case (colorSquare)
										0: begin
											Rout <= 4'b1111; Gout <= 4'b0000; Bout <= 4'b0000;
										end
										1: begin
											Rout <= 4'b0000; Gout <= 4'b1111; Bout <= 4'b0000;
										end
										2: begin
											Rout <= 4'b0000; Gout <= 4'b0000; Bout <= 4'b1111;
										end
										3: begin
											Rout <= 4'b1111; Gout <= 4'b1111; Bout <= 4'b0000;
										end
										default: 
										begin
											Rout <= 4'b0000; Gout <= 4'b0000; Bout <= 4'b0000;
										end
									endcase
								end
								else begin
								case (colorSquare)
										4: begin
											Rout <= 4'b1001; Gout <= 4'b0101; Bout <= 4'b1010;
										end
										5: begin
											Rout <= 4'b1100; Gout <= 4'b1001; Bout <= 4'b0110;
										end
										6: begin
											Rout <= 4'b0000; Gout <= 4'b1111; Bout <= 4'b1111;
										end
										7: begin
											Rout <= 4'b1010; Gout <= 4'b1010; Bout <= 4'b1010;
										end
										default: begin
											Rout <= 4'b1111; Gout <= 4'b1111; Bout <= 4'b1111;
										end
									endcase
								end
						  end
                    default: begin
                        Rout <= 4'b1111; Gout <= 4'b1111; Bout <= 4'b1111;
                    end
                endcase
            end 
            else begin
                // Fora da área de vídeo deve ser sempre preto [cite: 37, 45]
                Rout <= 0; Gout <= 0; Bout <= 0;
            end
        end // Fim do else
    end // Fim do always
endmodule