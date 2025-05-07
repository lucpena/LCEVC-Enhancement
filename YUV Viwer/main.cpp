#include "raylib.h"

#include <algorithm>
#include <fstream>
#include <vector>
#include <iostream>

const int WIDTH = 960;
const int HEIGHT = 544;
const int FRAME_RATE = 60;
const int Y_SIZE = WIDTH * HEIGHT;
const int UV_WIDTH = WIDTH / 2;
const int UV_HEIGHT = HEIGHT / 2;
const int UV_SIZE = UV_WIDTH * UV_HEIGHT;

using std::vector;
using std::ifstream;
using std::clamp;
using std::cout;
using std::endl;
using std::cin;

vector<unsigned char> y_data(Y_SIZE);
vector<unsigned char> u_data(UV_SIZE);
vector<unsigned char> v_data(UV_SIZE);
vector<unsigned char> rgb_data(WIDTH * HEIGHT * 3);

// Converte o YUV para RGB
void YUV420ToRGB(int frameIndex) {
    // Para cada linha da imagem
    for (int y = 0; y < HEIGHT; y++) {
        // Para cada coluna da imagem
        for (int x = 0; x < WIDTH; x++) {

            // Luminância (Y) : Brilho do pixel
            int Y = y_data[y * WIDTH + x];

            // Crominância (U e V): armazenam informações da cor.
            // Divide por 2 porque a resolução destes valores é a metade da de Y
            int U = u_data[(y / 2) * UV_WIDTH + (x / 2)];
            int V = v_data[(y / 2) * UV_WIDTH + (x / 2)];

            // Compensando os offsets
            int C = Y - 16;
            int D = U - 128;
            int E = V - 128;

            // Convertendo para RedGreenBlue
            int R = (298 * C + 409 * E + 128) >> 8;
            int G = (298 * C - 100 * D - 208 * E + 128) >> 8;
            int B = (298 * C + 516 * D + 128) >> 8;

            // Mantêm os valores dentro da faixa RGB
            R = clamp(R, 0, 255);
            G = clamp(G, 0, 255);
            B = clamp(B, 0, 255);

            // Calcula o índice do pixel atual no array RGB
            // Armazena como (R, G, B)
            int index = (y * WIDTH + x) * 3;

            rgb_data[index + 0] = R;
            rgb_data[index + 1] = G;
            rgb_data[index + 2] = B;
        }
    }
}

int main() {
    InitWindow(WIDTH, HEIGHT, "YUV Player");
    
    SetTargetFPS(FRAME_RATE);

    ifstream file("/home/lucpena/Downloads/SSH/Bosphorus_960x544_120fps_420_8bit.yuv", std::ios::binary);
    
    if (!file) {
        cout << "\nCould not find the video..." << endl;
        cin;
        return -1;
    }

    Image image = {
        .data = rgb_data.data(),
        .width = WIDTH,
        .height = HEIGHT,
        .mipmaps = 1,
        .format = PIXELFORMAT_UNCOMPRESSED_R8G8B8
    };

    Texture2D texture = LoadTextureFromImage(image);

    while (!WindowShouldClose()) {
        u_int64_t frame = file.tellg() / (Y_SIZE + UV_SIZE * 2);
        
        // if (!file.read((char*)y_data.data(), Y_SIZE)) YUV420ToRGB(0);
        
        file.read((char*)y_data.data(), Y_SIZE);
        file.read((char*)u_data.data(), UV_SIZE);
        file.read((char*)v_data.data(), UV_SIZE);

        YUV420ToRGB(0);
        UpdateTexture(texture, rgb_data.data());

        BeginDrawing();
            ClearBackground(RAYWHITE);

            DrawTexture(texture, 0, 0, WHITE);

            DrawText(TextFormat("Frame: %llu", frame), 10, 10, 20, RAYWHITE);
            DrawText(TextFormat("YUV420: %d x %d", WIDTH, HEIGHT), 10, 40, 20, RAYWHITE);
            DrawText(TextFormat("YUV: %d x %d", UV_WIDTH, UV_HEIGHT), 10, 70, 20, RAYWHITE);
            DrawText(TextFormat("YUV Size: %d", Y_SIZE), 10, 100, 20, RAYWHITE);
            DrawText(TextFormat("U Size: %d", UV_SIZE), 10, 130, 20, RAYWHITE);
            DrawText(TextFormat("V Size: %d", UV_SIZE), 10, 160, 20, RAYWHITE);
            DrawText(TextFormat("YUV Frame: %llu", frame), 10, 190, 20, RAYWHITE);
            DrawText(TextFormat("YUV Frame Size: %llu", Y_SIZE + UV_SIZE * 2), 10, 220, 20, RAYWHITE);

        EndDrawing();
    }

    CloseWindow();
    return 0;
}