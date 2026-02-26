// sim_sdl.cpp — Simulador Verilator + SDL2 para vga_top
//
// Teclas: M=modo | P/Space=pause | S=speed | C=cor | F=fullscreen | Q/ESC=sair

#include <cstdio>
#include <cstring>
#include <signal.h>
#include <chrono>
#include <thread>

#include <SDL2/SDL.h>
#include "Vvga_top.h"
#include "verilated.h"

static constexpr int WIDTH   = 640;
static constexpr int HEIGHT  = 480;
static constexpr int H_TOTAL = 800;
static constexpr int V_TOTAL = 525;
static constexpr int BTN_HOLD = 4;  // frames que o botao fica pressionado

static volatile bool running = true;
static void sig_handler(int) { running = false; }

int main(int argc, char **argv) {
    signal(SIGINT, sig_handler);
    Verilated::commandArgs(argc, argv);
    auto *top = new Vvga_top;

    if (SDL_Init(SDL_INIT_VIDEO) < 0) {
        fprintf(stderr, "SDL_Init: %s\n", SDL_GetError());
        return 1;
    }

    SDL_Window   *win = SDL_CreateWindow("VGA Sim | M=modo P=pause S=speed C=cor",
        SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
        WIDTH, HEIGHT, SDL_WINDOW_SHOWN | SDL_WINDOW_RESIZABLE);
    SDL_Renderer *ren = SDL_CreateRenderer(win, -1,
        SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC);
    if (!ren) ren = SDL_CreateRenderer(win, -1, SDL_RENDERER_SOFTWARE);
    SDL_Texture  *tex = SDL_CreateTexture(ren,
        SDL_PIXELFORMAT_RGB24, SDL_TEXTUREACCESS_STREAMING, WIDTH, HEIGHT);
    SDL_RenderSetLogicalSize(ren, WIDTH, HEIGHT);

    // Reset
    top->rst = 1; top->btn = 0; top->clk_50 = 0;
    for (int i = 0; i < 20; i++) { top->clk_50 = !top->clk_50; top->eval(); }
    top->rst = 0;

    auto *pixels = new uint8_t[WIDTH * HEIGHT * 3];
    int frames = 0;
    uint8_t pending_btn = 0;
    int btn_hold = 0;
    auto t0 = std::chrono::steady_clock::now();

    while (running && !Verilated::gotFinish()) {
        SDL_Event ev;
        uint8_t btn_press = 0;
        while (SDL_PollEvent(&ev)) {
            if (ev.type == SDL_QUIT) { running = false; break; }
            if (ev.type == SDL_KEYDOWN) {
                switch (ev.key.keysym.sym) {
                    case SDLK_ESCAPE: case SDLK_q: running = false;  break;
                    case SDLK_m:      btn_press |= 0x01; break;  // mode
                    case SDLK_p: case SDLK_SPACE: btn_press |= 0x02; break;  // pause
                    case SDLK_s:      btn_press |= 0x04; break;  // speed
                    case SDLK_c:      btn_press |= 0x08; break;  // color
                    case SDLK_f: {
                        Uint32 f = SDL_GetWindowFlags(win);
                        SDL_SetWindowFullscreen(win,
                            (f & SDL_WINDOW_FULLSCREEN_DESKTOP)
                            ? 0 : SDL_WINDOW_FULLSCREEN_DESKTOP);
                        break;
                    }
                }
            }
        }
        if (!running) break;

        if (btn_press) { pending_btn |= btn_press; btn_hold = BTN_HOLD; }
        if (btn_hold > 0) {
            top->btn = pending_btn;
            if (--btn_hold == 0) { pending_btn = 0; top->btn = 0; }
        }

        memset(pixels, 0, WIDTH * HEIGHT * 3);

        for (int i = 0; i < H_TOTAL * V_TOTAL && running; i++) {
            // clock_div divide por 2: dois ciclos de clk_50 = um pixel clock
            top->clk_50 = 1; top->eval();
            top->clk_50 = 0; top->eval();
            top->clk_50 = 1; top->eval();
            top->clk_50 = 0; top->eval();

            if (top->video_on) {
                int h = i % H_TOTAL;
                int v = i / H_TOTAL;
                if (h < WIDTH && v < HEIGHT) {
                    int idx = (v * WIDTH + h) * 3;
                    pixels[idx]   = top->r;
                    pixels[idx+1] = top->g;
                    pixels[idx+2] = top->b;
                }
            }
        }

        SDL_UpdateTexture(tex, nullptr, pixels, WIDTH * 3);
        SDL_RenderClear(ren);
        SDL_RenderCopy(ren, tex, nullptr, nullptr);
        SDL_RenderPresent(ren);
        frames++;

        // Pacing ~60 fps
        double elapsed = std::chrono::duration<double>(
            std::chrono::steady_clock::now() - t0).count();
        double target = frames / 60.0;
        if (target > elapsed)
            std::this_thread::sleep_for(std::chrono::microseconds(
                (long)((target - elapsed) * 1e6)));

        if (frames % 60 == 0) {
            double s = std::chrono::duration<double>(
                std::chrono::steady_clock::now() - t0).count();
            char title[80];
            snprintf(title, sizeof(title),
                "VGA Sim | M=modo P=pause S=speed C=cor | %.1f fps | Frame %d",
                frames / s, frames);
            SDL_SetWindowTitle(win, title);
        }
    }

    delete[] pixels;
    top->final();
    delete top;
    SDL_DestroyTexture(tex);
    SDL_DestroyRenderer(ren);
    SDL_DestroyWindow(win);
    SDL_Quit();
    return 0;
}
