// debounce.v — Filtro de bounce para botoes
//
// Amostra o botao a cada tick (~10ms com clock de 25 MHz, counter de 18 bits).
// Muda a saida apos STABLE_COUNT amostras consecutivas iguais (~31.5 ms total).

module debounce #(
    parameter COUNTER_BITS = 18,  // 2^18 / 25 MHz = 10.5 ms por tick
    parameter STABLE_COUNT = 3    // 3 ticks = ~31.5 ms de debounce
)(
    input  wire clk,
    input  wire rst,
    input  wire btn_in,   // Entrada com bounce
    output reg  btn_out   // Saida filtrada
);

reg [COUNTER_BITS-1:0] tick_counter;
wire tick = (tick_counter == {COUNTER_BITS{1'b1}});

always @(posedge clk or posedge rst) begin
    if (rst) tick_counter <= 0;
    else     tick_counter <= tick_counter + 1;
end

reg [$clog2(STABLE_COUNT+1)-1:0] stable_r;
reg btn_sync_0, btn_sync_1;  // Sincronizador 2-FF contra metastabilidade

always @(posedge clk or posedge rst) begin
    if (rst) begin
        btn_sync_0 <= 1'b0;
        btn_sync_1 <= 1'b0;
        stable_r   <= 0;
        btn_out    <= 1'b0;
    end else begin
        btn_sync_0 <= btn_in;
        btn_sync_1 <= btn_sync_0;

        if (tick) begin
            if (btn_sync_1 == btn_out) begin
                stable_r <= 0;
            end else begin
                if (stable_r >= STABLE_COUNT - 1) begin
                    btn_out  <= btn_sync_1;
                    stable_r <= 0;
                end else begin
                    stable_r <= stable_r + 1;
                end
            end
        end
    end
end

endmodule
