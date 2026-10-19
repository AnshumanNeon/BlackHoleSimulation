#include "raylib.h"

int main() {
    const int screenWidth = 800;
    const int screenHeight = 450;

    InitWindow(screenWidth, screenHeight, "Black Hole Simulation");

    SetTargetFPS(60);

    while (!WindowShouldClose()) {
        // Update

        // Draw
        BeginDrawing();
            ClearBackground(RAYWHITE);
        EndDrawing();
    }

    // De-Initialization
    CloseWindow();

    return 0;
}
