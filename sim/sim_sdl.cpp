// sim_sdl.cpp — Verilator + SDL2 Simulation for vga_top
//
// Keyboard Controls:
// M = Change Mode (Square, Crosshair, Checkerboard)
// C = Change Background Color
// V = Change Square Color (was 'C' in previous version, split for clarity)
// P / Space = Pause
// F = Fullscreen
// Q / ESC = Quit

#include <cstdio>
#include <cstring>
#include <signal.h>
#include <chrono>
#include <thread>
#include <iostream>

#include <SDL2/SDL.h>
#include "Vvga_top.h"
#include "verilated.h"

// Screen Dimensions
static constexpr int WIDTH   = 640;
static constexpr int HEIGHT  = 480;
static constexpr int H_TOTAL = 800; // 640 + 16 + 96 + 48
static constexpr int V_TOTAL = 525; // 480 + 10 + 2 + 33

static volatile bool running = true;
static void sig_handler(int) { running = false; }

void save_screenshot(SDL_Renderer* ren, const char* filename) {
    SDL_Surface *sshot = SDL_CreateRGBSurface(0, WIDTH, HEIGHT, 32, 0x00ff0000, 0x0000ff00, 0x000000ff, 0xff000000);
    if (!sshot) return;
    SDL_RenderReadPixels(ren, NULL, SDL_PIXELFORMAT_ARGB8888, sshot->pixels, sshot->pitch);
    SDL_SaveBMP(sshot, filename);
    SDL_FreeSurface(sshot);
}

int main(int argc, char **argv) {
    signal(SIGINT, sig_handler);
    Verilated::commandArgs(argc, argv);
    
    // Instantiate the top module
    auto *top = new Vvga_top;

    if (SDL_Init(SDL_INIT_VIDEO) < 0) {
        fprintf(stderr, "SDL_Init Error: %s\n", SDL_GetError());
        return 1;
    }

    SDL_Window   *win = SDL_CreateWindow("VGA Controller Simulation (Verilator + SDL2)",
        SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
        WIDTH, HEIGHT, SDL_WINDOW_SHOWN | SDL_WINDOW_RESIZABLE);

    if (!win) {
        fprintf(stderr, "SDL_CreateWindow Error: %s\n", SDL_GetError());
        return 1;
    }

    SDL_Renderer *ren = SDL_CreateRenderer(win, -1,
        SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC);
    
    if (!ren) {
        // Fallback to software renderer
        ren = SDL_CreateRenderer(win, -1, SDL_RENDERER_SOFTWARE);
    }

    SDL_Texture  *tex = SDL_CreateTexture(ren,
        SDL_PIXELFORMAT_RGB24, SDL_TEXTUREACCESS_STREAMING, WIDTH, HEIGHT);
    
    SDL_RenderSetLogicalSize(ren, WIDTH, HEIGHT);

    // Initial Reset
    top->reset = 1;
    top->clk = 0;
    top->btn_mode = 0;
    top->btn_color_bg = 0;
    top->btn_color_sq = 0;

    // Pulse clock for reset
    for (int i = 0; i < 20; i++) { 
        top->clk = !top->clk; 
        top->eval(); 
    }
    top->reset = 0;

    // Pixel buffer
    auto *pixels = new uint8_t[WIDTH * HEIGHT * 3];
    int frames = 0;
    
    auto t0 = std::chrono::steady_clock::now();

    // Simulation Loop
    while (running && !Verilated::gotFinish()) {
        SDL_Event ev;
        
        // Handle Input
        while (SDL_PollEvent(&ev)) {
            if (ev.type == SDL_QUIT) { running = false; break; }
            if (ev.type == SDL_KEYDOWN) {
                switch (ev.key.keysym.sym) {
                    case SDLK_ESCAPE: case SDLK_q: running = false;  break;
                    case SDLK_m:      top->btn_mode = 1; break; 
                    case SDLK_c:      top->btn_color_bg = 1; break;
                    case SDLK_v:      top->btn_color_sq = 1; break; // Added 'V' for square color
                    case SDLK_f: {
                        Uint32 f = SDL_GetWindowFlags(win);
                        SDL_SetWindowFullscreen(win,
                            (f & SDL_WINDOW_FULLSCREEN_DESKTOP)
                            ? 0 : SDL_WINDOW_FULLSCREEN_DESKTOP);
                        break;
                    }
                }
            }
            if (ev.type == SDL_KEYUP) {
                 switch (ev.key.keysym.sym) {
                    case SDLK_m:      top->btn_mode = 0; break; 
                    case SDLK_c:      top->btn_color_bg = 0; break;
                    case SDLK_v:      top->btn_color_sq = 0; break;
                }
            }
        }
        if (!running) break;

        // Clear pixel buffer for safety (optional, as we overwrite it)
        // memset(pixels, 0, WIDTH * HEIGHT * 3);

        // Run simulation for one full frame (active + blanking)
        // We simulate pixel-by-pixel.
        // H_TOTAL * V_TOTAL = 800 * 525 = 420,000 clock cycles per frame.
        
        int pixel_ptr = 0; // Index for the SDL texture buffer

        for (int v = 0; v < V_TOTAL; v++) {
            for (int h = 0; h < H_TOTAL; h++) {
                // Toggle Clock (Rising Edge)
                top->clk = 1; 
                top->eval();
                
                // Capture pixel color at the rising edge (or right after)
                // We only care about the visible area for the SDL texture
                if (h < WIDTH && v < HEIGHT) {
                    int idx = (v * WIDTH + h) * 3;
                    
                    // Scale 4-bit color to 8-bit (0-15 -> 0-255)
                    // Simple shift: x * 17 (e.g., F -> 255, 0 -> 0)
                    pixels[idx]   = top->R * 17;
                    pixels[idx+1] = top->G * 17;
                    pixels[idx+2] = top->B * 17;
                }

                // Toggle Clock (Falling Edge)
                top->clk = 0; 
                top->eval();
            }
        }

        // Update Screen
        SDL_UpdateTexture(tex, nullptr, pixels, WIDTH * 3);
        SDL_RenderClear(ren);
        SDL_RenderCopy(ren, tex, nullptr, nullptr);
        SDL_RenderPresent(ren);
        frames++;

        // Auto-Screenshot after 60 frames (1 second)
        if (frames == 60) {
            save_screenshot(ren, "sim_screenshot.bmp");
            printf("Screenshot saved to sim_screenshot.bmp\n");
        }

        // Frame Pacing (~60 FPS)
        // In simulation, we might run faster or slower than real-time depending on CPU.
        // This logic limits it to 60FPS max to be playable.
        double elapsed = std::chrono::duration<double>(
            std::chrono::steady_clock::now() - t0).count();
        double target = frames / 60.0;
        if (target > elapsed)
            std::this_thread::sleep_for(std::chrono::microseconds(
                (long)((target - elapsed) * 1e6)));

        // Update Window Title with FPS
        if (frames % 60 == 0) {
            double s = std::chrono::duration<double>(
                std::chrono::steady_clock::now() - t0).count();
            char title[128];
            snprintf(title, sizeof(title),
                "VGA Sim | FPS: %.1f | Frame: %d | Mode: %d",
                frames / s, frames, (int)top->R); // Just debug info
            SDL_SetWindowTitle(win, title);
        }
    }

    // Cleanup
    delete[] pixels;
    top->final();
    delete top;
    SDL_DestroyTexture(tex);
    SDL_DestroyRenderer(ren);
    SDL_DestroyWindow(win);
    SDL_Quit();
    return 0;
}
